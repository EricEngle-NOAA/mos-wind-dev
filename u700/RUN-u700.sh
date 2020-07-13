#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U700 MOS Wind Development (Generates MOS Forecasts)
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================   
CYC=00
ELEMENT="wind"
MODEL="gfs"
SAVEFORT12=1
SEASON="cl"
SHARED=1
SUBMIT=1
RUN=$1          #"final"

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
TAUS=$(../ush/make-taus.sh 6,3,240,p 246,6,264,p 6,3,15,s)

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
WORKDIR=$DEVSTMP/u700_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${RUN}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# ==============================================================================   
# Define and make the output area
# ==============================================================================   
OUTDIR=$DEVOUTDIR/u700/$RUN
if [ ! -d $OUTDIR ];then mkdir -p $OUTDIR; fi

# ==============================================================================   
# Iterate over TAUS and build input predictor and equation file lists.
# ==============================================================================   
i=200
for TAU in $TAUS
do
   j=$(( $i + 100 ))
   if [ "${TAU: -1}" == "p" ]; then
      printf "%3d    %-60s##VECTOR PREDICTOR INPUT\n" $i "data/u201.${MODEL}${CYC}.f${TAU:0:3}.${SEASON}" >> $WORKDIR/inputPRED
   fi
   printf "%3d    %-60s##EQUATION INPUT\n" $j "eqns/u600.${MODEL}${CYC}.${ELEMENT}.${SEASON}.f${TAU}" >> $WORKDIR/inputEQNS
   i=$(( $i + 1 ))
done # for TAU

# ==============================================================================   
# Populate WORKDIR
# ==============================================================================   

# Create link to U201 output directory. This is U700 input
ln -s $DEVOUTDIR/u201 $WORKDIR/data
ln -s $DEVOUTDIR/u600/${RUN} $WORKDIR/eqns

# Copy files to WORKDIR
cp dates/u700.dates.${CYC}.${SEASON}.${RUN} $WORKDIR/.
cp ../const/$CONST_GRD $WORKDIR/.
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/$STALST $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../fix/mdl_predtofcst $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u700.x $WORKDIR/.

# Create list of RA input files
printf " 44    %-60s##GRIDDED CONSTANTS\n" $CONST_GRD >> $WORKDIR/rainputs
printf " 45    %-60s##VECTOR CONSTANTS\n" $CONST_STA >> $WORKDIR/rainputs

# Create list of station list and table.
printf " 30    %-60s##STATION LIST\n"  $STALST >> $WORKDIR/station
printf " 31    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Create U600.CN
RUN10=$(printf "%-10s\n" $RUN)
sed -e "s/BB/${SEASON}/g" \
    -e "s/CCCCCCCCCC/${RUN10}/g" \
    -e "s/EEEE/${ELEMENT}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "/<inputPRED>/r $WORKDIR/inputPRED" \
    -e "/<inputEQNS>/r $WORKDIR/inputEQNS" \
    -e "/<rainput>/r $WORKDIR/rainputs" \
    -e "/<station>/r $WORKDIR/station" control/U700.CN_TEMPLATE > $WORKDIR/U700.CN
sed -i '/<[a-zA-Z]*/d' $WORKDIR/U700.CN

# Create run script in WORKDIR
OUTPUT=$(grep '^199 ' $WORKDIR/U700.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u700.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u700.sh
echo "./u700.x" >> $WORKDIR/run-u700.sh
echo "cp $OUTPUT $DEVOUTDIR/u700/${RUN}/$OUTPUT" >> $WORKDIR/run-u700.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $DEVOUTDIR/u700/${RUN}/fort12_${MODEL}${CYC}_${ELEMENT}_${SEASON}.gz" >> $WORKDIR/run-u700.sh
fi
chmod 744 $WORKDIR/run-u700.sh

# ==============================================================================   
# Build job card.
# ==============================================================================   
PTILE=1
if [ $SUBMIT -eq 1 ]; then 
bsub  -a serial \
      -J  "u700-${MODEL}${CYC}-${ELEMENT}-${SEASON}" \
      -oo "u700-${MODEL}${CYC}-${ELEMENT}-${SEASON}.out" \
      -W 01:00 \
      -n 1 \
      -R "span[ptile=$PTILE]" \
      -R "affinity[core(1)]" \
      -R "rusage[mem=1728]" \
      -q "$QUEUE" \
      -P "MDLST-T2O" \
      $WORKDIR/run-u700.sh
fi
