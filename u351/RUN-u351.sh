#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U351 MOS Wind Development (Packs ASCII data in RA File)
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================   
ELEMENT="prob"
MODEL="gfs"
SAVEFORT12=0
SHARED=1
SUBMIT=1

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
TAUS=$(../ush/make-taus.sh 6,3,192,p 198,6,264,p 6,3,15,s)

# ==============================================================================   
# Import dev environment
# ==============================================================================   
. ../dev.env

# ==============================================================================   
# Modify QUEUE if SHARED=1 (yes).
# ==============================================================================   
if [ $SHARED -eq 1 ]; then
   QUEUE+="_shared"
fi

# ==============================================================================   
# Define and make WORKDIR
# ==============================================================================   
WORKDIR=$DEVSTMP/u351_${MODEL}_${ELEMENT}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# ==============================================================================   
# Iterate over TAUS and build input ASCII file list.
# ==============================================================================   
i=200
for CYC in 00 12; do
for SEASON in cl wm; do
for TAU in $TAUS; do
   printf "%3d    %-60s##INPUT ASCII\n" "$i" "data_u830/u830.${MODEL}${CYC}.${ELEMENT}.${SEASON}.thresh.f${TAU}" >> $WORKDIR/inputASCII
   printf "%3d    %-60s##STATION TABLE\n" "22" "${STATBL}" >> $WORKDIR/inputASCII
   printf " 99\n" >> $WORKDIR/inputASCII
   i=$(( $i + 1 ))
done # for TAU
done # for SEASON
done # for CYC

# ==============================================================================   
# Populate WORKDIR
# ==============================================================================   

# Create empty RA file in WORKDIR
../ush/make-rafile.sh 300 2000 $WORKDIR/u830.${MODEL}.gust.thresholds

# Create link to U830 output directory. This is U351 input
ln -s $DEVOUTDIR/u830 $WORKDIR/data_u830

# Copy files to WORKDIR
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/$STALST $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp sorc/u351.x $WORKDIR/.

# Create list of station list and table.
printf " 20    %-60s##STATION LIST\n"  $STALST >> $WORKDIR/station
printf " 21    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Create U351.CN
RUN10=$(printf "%-10s\n" $RUN)
sed -e "s/BB/${SEASON}/g" \
    -e "s/EEEE/${ELEMENT}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "/<inputASCII>/r $WORKDIR/inputASCII" \
    -e "/<station>/r $WORKDIR/station" control/U351.CN_TEMPLATE > $WORKDIR/U351.CN
sed -i '/<[a-zA-Z]*/d' $WORKDIR/U351.CN

# Create run script in WORKDIR
OUTPUT=$(grep '^199 ' $WORKDIR/U351.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u351.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u351.sh
echo "./u351.x" >> $WORKDIR/run-u351.sh
echo "cp $OUTPUT $DEVOUTDIR/u351/." >> $WORKDIR/run-u351.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $DEVOUTDIR/u351/fort12_${MODEL}${CYC}_${ELEMENT}_${SEASON}.gz" >> $WORKDIR/run-u351.sh
fi
chmod 744 $WORKDIR/run-u351.sh

# ==============================================================================   
# Build job card.
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then 
bsub  -a serial \
      -J  "u351-${MODEL}-${ELEMENT}" \
      -oo  "u351-${MODEL}-${ELEMENT}.out" \
      -W 01:00 \
      -n 1 \
      -R "span[ptile=1]" \
      -R "affinity[core(1)]" \
      -R "rusage[mem=1728]" \
      -q "$QUEUE" \
      -P "MDLST-T2O" \
      $WORKDIR/run-u351.sh
fi
