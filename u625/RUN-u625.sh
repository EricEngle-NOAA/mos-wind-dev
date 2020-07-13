#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U625 MOS Wind Development (Modifies/Inventories Equation Files)
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================   
CYC=00
ELEMENT="wind"
MODEL="gfs"
SAVECSV="3"        # 0=off; 1=input; 2=output; 3=all
SAVEFORT12=0
SEASON="cl"
SHARED=0
SUBMIT=0
RUN="final"

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
#TAUS=$(../ush/make-taus.sh 6,3,192,p 6,3,15,s)
TAUS=$(../ush/make-taus.sh 6,3,240,p 6,3,15,s 246,6,264,p)

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
WORKDIR=$DEVSTMP/u625_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${RUN}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# ==============================================================================   
# Iterate over TAUS. Build input and output equation files.
# ==============================================================================   
i=200
for TAU in $TAUS
do
   j=$(( $i + 100 ))
   printf "%3d    %-60s##INPUT EQUATIONS\n"  $i "eqns_u600/u600.${MODEL}${CYC}.${ELEMENT}.${SEASON}.f${TAU}" >> $WORKDIR/inputEQNS
   printf "%3d    %-60s##OUTPUT EQUATIONS\n" $j "eqns_u625/u625.${MODEL}${CYC}.${ELEMENT}.${SEASON}.f${TAU}" >> $WORKDIR/outputEQNS
   i=$(( $i + 1 ))
done # for TAU

# ==============================================================================   
# Populate WORKDIR
# ==============================================================================   

# Create link to U600 input and U625 output directories.
if [ ! -d $DEVOUTDIR/u625/${RUN} ]; then mkdir -p $DEVOUTDIR/u625/${RUN}; fi
ln -s $DEVOUTDIR/u600/${RUN} $WORKDIR/eqns_u600
ln -s $DEVOUTDIR/u625/${RUN} $WORKDIR/eqns_u625

# Copy files to WORKDIR
cp ../table/$STALST $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
#cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u625.x $WORKDIR/.

# Create list of station list and table.
printf " 30    %-60s##STATION LIST\n"  $STALST >> $WORKDIR/stationlst
printf " 31    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/stationtbl

# Create U600.CN
sed -e "/<inputeqns>/r $WORKDIR/inputEQNS" \
    -e "/<outputeqns>/r $WORKDIR/outputEQNS" \
    -e "/<stationlst>/r $WORKDIR/stationlst" \
    -e "/<stationtbl>/r $WORKDIR/stationtbl" control/U625.CN_TEMPLATE > $WORKDIR/U625.CN
sed -i '/<[a-zA-Z]*/d' $WORKDIR/U625.CN

# Create run script in WORKDIR
echo "#!/bin/sh" >> $WORKDIR/run-u625.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u625.sh
echo "./u625.x" >> $WORKDIR/run-u625.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $DEVOUTDIR/u625/${RUN}/fort12_${MODEL}${CYC}_${ELEMENT}_${SEASON}.gz" >> $WORKDIR/run-u625.sh
fi
if [ $SAVECSV -eq 1 -o $SAVECSV -eq 3 ]; then
echo "cp U625EFE170 $DEVOUTDIR/u625/${RUN}/inputeqns_${MODEL}${CYC}_${ELEMENT}_${SEASON}.csv" >> $WORKDIR/run-u625.sh
fi
if [ $SAVECSV -eq 2 -o $SAVECSV -eq 3 ]; then
echo "cp U625EFE180 $DEVOUTDIR/u625/${RUN}/outputeqns_${MODEL}${CYC}_${ELEMENT}_${SEASON}.csv" >> $WORKDIR/run-u625.sh
fi
chmod 744 $WORKDIR/run-u625.sh

# ==============================================================================   
# Build job card.
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then 
bsub  -a serial \
      -J  "u625-${MODEL}${CYC}-${ELEMENT}-${SEASON}" \
      -oo "u625-${MODEL}${CYC}-${ELEMENT}-${SEASON}.out" \
      -W 00:30 \
      -n 1 \
      -R "span[ptile=$PTILE]" \
      -R "affinity[core(1)]" \
      -R "rusage[mem=1728]" \
      -q "$QUEUE" \
      -P "MDLST-T2O" \
      $WORKDIR/run-u625.sh
fi
