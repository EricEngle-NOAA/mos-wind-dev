#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U710 MOS Wind Development (MOS Forecast Post-Processing)
#
# Description of MOS Wind Post-Processing Steps:
#
#     step1 = Compute wind direction from u- and v-wind forecast.
#     step2 = Set negative wind speed forecasts to zero.
#     step3 = Set wind direction to zero if wind speed is LE zero.
#     step4 = DEV ONLY: Make operation forecasts. That is use primary or
#             secondary forecasts at projections where appropriate.  For winds,
#             the projections are 6-hr through 15-hr.
#
# NOTE: When running step4, make sure steps 1 through 3 have been completed.
#       TAUS should contain no p/s suffixes, but PREP-u710-id-list.sh will
#       check for this and correct.
#
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================   
CYC=00
ELEMENT="wind"
MODEL="nam"
SAVEFORT12=1
SEASON="wm"
SHARED=0
STEPS="step4"
SUBMIT=1
RUN="indep"

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
#TAUS=$(../ush/make-taus.sh 6,3,84,p 6,3,15,s)
TAUS=$(../ush/make-taus.sh 6,3,84)

# ==============================================================================   
# Import dev environment
# ==============================================================================   
. ../dev.env

# ==============================================================================   
# Get DD from MODEL
# ==============================================================================   
DD=$(grep '^'"$MODEL" ../fix/model2dd | cut -d":" -f 2)

# ==============================================================================   
# Modify QUEUE if SHARED=1 (yes).
# ==============================================================================   
if [ $SHARED -eq 1 ]; then
   QUEUE+="_shared"
fi

# ==============================================================================   
# Iterate over STEPS
# ==============================================================================   
DATA=$DEVSTMP/u710_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${RUN}
for STEP in $STEPS
do

# Define the step number
STEPNUM=${STEP: -1}

# Define and make WORKDIR}
WORKDIR=$DEVSTMP/u710_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${RUN}/${STEP}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# Create links to u700 and u710 output directories
ln -s $DEVOUTDIR/u700 $WORKDIR/data_u700
ln -s $DEVOUTDIR/u710 $WORKDIR/data_u710

# Copy files to WORKDIR
cp dates/u710.dates.${CYC}.${SEASON}.${RUN} $WORKDIR/.
cp ../const/$CONST_GRD $WORKDIR/.
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/$STALST $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u710.x $WORKDIR/.

# Create ID list. Here we need to send TAUS into the prep IDs script
# as a comma delimited list.
./PREP-u710-id-list.sh $ELEMENT $STEP $DD ${TAUS//$'\n'/,} $WORKDIR/u710.ids.${STEP}

# Create input file list.  For U710, this can be tricky as one step is
# dependent on the previous.
if [ $STEPNUM -ge 1 -a $STEPNUM -le 3 ]; then
printf " 20    %-60s##INPUT (FROM U700)\n" data_u700/u700.${MODEL}${CYC}.${ELEMENT}.${SEASON} >> $WORKDIR/inputs
for s in $(seq 1 1 $(( ${STEP: -1} - 1 )) )
do
   printf "%3d    %-60s##INPUT (FROM U710, STEP $s)\n" $(( $s + 20 )) "data_u710/u710.${MODEL}${CYC}.${ELEMENT}.${SEASON}.step${s}" >> $WORKDIR/inputs
done # for s
elif [ $STEPNUM -eq 4 ]; then
printf " 20    %-60s##INPUT (FROM U700)\n" data_u700/u700.${MODEL}${CYC}.${ELEMENT}.${SEASON} >> $WORKDIR/inputs
printf " 21    %-60s##INPUT (FROM U710, STEP 1)\n" "data_u710/u710.${MODEL}${CYC}.${ELEMENT}.${SEASON}.step1" >> $WORKDIR/inputs
printf " 22    %-60s##INPUT (FROM U710, STEP 2)\n" "data_u710/u710.${MODEL}${CYC}.${ELEMENT}.${SEASON}.step2" >> $WORKDIR/inputs
printf " 23    %-60s##INPUT (FROM U710, STEP 3)\n" "data_u710/u710.${MODEL}${CYC}.${ELEMENT}.${SEASON}.step3" >> $WORKDIR/inputs
fi


# Create list of RA input files
printf " 44    %-60s##GRIDDED CONSTANTS\n" $CONST_GRD >> $WORKDIR/rainputs
printf " 45    %-60s##VECTOR CONSTANTS\n" $CONST_STA >> $WORKDIR/rainputs

# Create list of station list and table.
printf " 30    %-60s##STATION LIST\n"  $STALST >> $WORKDIR/station
printf " 31    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Create U710.CN
RUN10=$(printf "%-5s\n" $RUN)
sed -e "s/BB/${SEASON}/g" \
    -e "s/CCCCC/${RUN10}/g" \
    -e "s/EEEE/${ELEMENT}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "s/SSSSS/${STEP}/g" \
    -e "/<input>/r $WORKDIR/inputs" \
    -e "/<rainput>/r $WORKDIR/rainputs" \
    -e "/<station>/r $WORKDIR/station" control/U710.CN_TEMPLATE > $WORKDIR/U710.CN
sed -i '/<[a-z]*/d' $WORKDIR/U710.CN

# Create run script in WORKDIR
OUTPUT=$(grep '^199 ' $WORKDIR/U710.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u710.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u710.sh
echo "./u710.x" >> $WORKDIR/run-u710.sh
echo "cp $OUTPUT $DEVOUTDIR/u710/$OUTPUT" >> $WORKDIR/run-u710.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $DEVOUTDIR/u710/fort12_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${STEP}.gz" >> $WORKDIR/run-u710.sh
fi
chmod 744 $WORKDIR/run-u710.sh

done # for STEP

# ==============================================================================   
# Build job card. For U710, each step needs to run in sequential order.
# poescript is retained here even though the job is serial. The job will
# simply execute the poescript like any other shell script.
# ==============================================================================   
POESCRIPT=$DATA/poescript
if [ -f $POESCRIPT ]; then rm -f $POESCRIPT; fi
echo "#!/bin/sh" >> $POESCRIPT
/bin/ls -1 $DEVSTMP/u710_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${RUN}/step*/run-u710.sh >> $POESCRIPT
NTASKS=$(cat $POESCRIPT | wc -l)

if [ $NTASKS -le $MAXTHREADS ]; then
   PTILE=$NTASKS
else
   PTILE=$MAXTHREADS
fi

if [ -f $DATA/run-u710-serial.sh ]; then rm -f $DATA/run-u710-serial.sh; fi
cat << EOF > $DATA/run-u710-serial.sh
#BSUB -a serial
#BSUB -J  "u710-${MODEL}${CYC}-${ELEMENT}-${SEASON}-${RUN}-${STEP}"
#BSUB -oo "u710-${MODEL}${CYC}-${ELEMENT}-${SEASON}-${RUN}-${STEP}.out"
#BSUB -W 02:00
#BSUB -n $NTASKS
#BSUB -R "span[ptile=$PTILE]"
#BSUB -R "affinity[core(1)]"
#BSUB -R "rusage[mem=1728]"
#BSUB -q "$QUEUE"
#BSUB -P "MDLST-T2O"
#
cd $DATA
chmod 744 poescript
./poescript
EOF

# ==============================================================================   
# Submit job
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then 
   chmod 744 $DATA/run-u710-serial.sh
   cat $DATA/run-u710-serial.sh | bsub
fi
