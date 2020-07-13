#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U830 MOS Wind Development (Threshold Generation)
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================   
CYC=00
ELEMENT="prob"
MODEL="gfs"
SAVEFORT12=1
SEASON="wm"
SHARED=1
SUBMIT=0

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
TAUS=$(../ush/make-taus.sh 6,3,192,p 198,6,264,p 6,3,15,s)
#TAUS=006p

# ==============================================================================   
# Import dev environment
# ==============================================================================   
. ../dev.env

# ==============================================================================   
# Get SSNNUM from SEASON
# ==============================================================================   
if [ "$SEASON" == "cl" ]; then
   SSNNUM=18
elif [ "$SEASON" == "wm" ]; then
   SSNNUM=17
fi

# ==============================================================================   
# Modify QUEUE if SHARED=1 (yes).
# ==============================================================================   
if [ $SHARED -eq 1 ]; then
   QUEUE+="_shared"
fi

# ==============================================================================   
# Define and make WORKDIR
# ==============================================================================   
DATA=$DEVSTMP/u830_${MODEL}${CYC}_${ELEMENT}_${SEASON}
if [ ! -d $DATA ]; then
   mkdir -p $DATA
fi

# ==============================================================================   
# Iterate on TAUS, create and populate WORKDIR with necessary files and links.
# ==============================================================================   
for TAU in $TAUS
do

WORKDIR=$DATA/f${TAU}
mkdir -p $WORKDIR

# Set PS
PS=${TAU: -1}

# Check PS. If PS is a number (0-9), then just set DD to BASEDD which
# means there is suffix in TAUS.
DD=$(grep '^'"$MODEL" ../fix/model2dd | cut -d":" -f 2)
if [[ "$PS" =~ [0-9] ]]; then
   DD=$DD
elif [[ "$PS" =~ [a-zA-Z] ]]; then
   BASEDD=$DD
   if [ "$PS" != "p" -a "$PS" != "s" ]; then exit 1; fi
   if [ "$PS" == "p" -a ${TAU:0:3} -le 15 ]; then
      DD=$(( 10#$BASEDD + 10 ))
   elif [ "$PS" == "s" -a ${TAU:0:3} -le 15 ]; then
      DD=$(( 10#$BASEDD + 20 ))
   else
      DD=$BASEDD
   fi
fi

# Create link to U201 output directory. This is U830 input
ln -s $DEVOUTDIR/u201 $WORKDIR/data_u201
ln -s $DEVOUTDIR/u710/final $WORKDIR/data_u710

# Copy files to WORKDIR
cp dates/u830.dates.${CYC}.${SEASON} $WORKDIR/.
cp ../table/${STALST}_u830_${ELEMENT}_${SEASON} $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u830.x $WORKDIR/.

# Create threshold file. One line per number of groups in station list.
THRESHINFO=$(grep '^ ' ids/u830_threshold_TEMPLATE)
NSTA=$(grep -c -v 99999999 $WORKDIR/${STALST}_u830_${ELEMENT}_${SEASON})
yes "$THRESHINFO" | head -$NSTA > $WORKDIR/threshinfo

# Create list of station list and table. For U830, the station list needs to
# have a terminator after each station (single-station eqns) or group of
# stations (regional equation). This file should already be created and
# name in the following manner: STALST_u830_ELEMENT_SEASON.
printf " 30    %-60s##STATION LIST\n" ${STALST}_u830_${ELEMENT}_${SEASON} >> $WORKDIR/station
printf " 31    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Create U830.CN
sed -e "s/BB/${SEASON}/g" \
    -e "s/DD/${DD}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/JJ/${SSNNUM}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "s/XXX/${TAU:0:3}/g" \
    -e "s/YYYY/${TAU}/g" \
    -e "/<thresh>/r $WORKDIR/threshinfo" \
    -e "/<station>/r $WORKDIR/station" control/U830.CN_TEMPLATE > $WORKDIR/U830.CN
sed -i '/<[a-z]*/d' $WORKDIR/U830.CN

# Create run script in WORKDIR
OUTPUT=$(grep '^199 ' $WORKDIR/U830.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u830.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u830.sh
echo "./u830.x" >> $WORKDIR/run-u830.sh
echo "cp $OUTPUT $DEVOUTDIR/u830/$OUTPUT" >> $WORKDIR/run-u830.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $DEVOUTDIR/u830/fort12_${MODEL}${CYC}_${ELEMENT}_f${TAU}_${SEASON}.gz" >> $WORKDIR/run-u830.sh
fi
chmod 744 $WORKDIR/run-u830.sh

done # for TAU

# ==============================================================================   
# Build poescript and job card.
# ==============================================================================   
if [ -f $DATA/poescript ]; then rm -f $DATA/poescript; fi
/bin/ls -1 $DEVSTMP/u830_${MODEL}${CYC}_${ELEMENT}_${SEASON}/f*/run-u830.sh > $DATA/poescript
NTASKS=$(cat $DATA/poescript | wc -l)

if [ $NTASKS -le $MAXTHREADS ]; then
   PTILE=$NTASKS
else
   PTILE=$MAXTHREADS
fi

if [ -f $DATA/run-u830-poe.sh ]; then rm -f $DATA/run-u830-poe.sh; fi
cat << EOF > $DATA/run-u830-poe.sh
#BSUB -a poe
#BSUB -J  "u830-${MODEL}${CYC}-${ELEMENT}-${SEASON}"
#BSUB -oo "$DATA/u830-${MODEL}${CYC}-${ELEMENT}-${SEASON}.out"
#BSUB -W 04:00
#BSUB -n $NTASKS
#BSUB -R "span[ptile=$PTILE]"
#BSUB -R "affinity[core(1)]"
#BSUB -R "rusage[mem=1728]"
#BSUB -q "$QUEUE"
#BSUB -P "MDLST-T2O"
#
export MP_PGMMODEL=mpmd
export MP_LABELIO=YES
export MP_STDOUTMODE="unordered"
chmod 755 poescript
mpirun.lsf -cmdfile $DATA/poescript
EOF

# ==============================================================================   
# Submit job
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then 
   chmod 744 $DATA/run-u830-poe.sh
   cat $DATA/run-u830-poe.sh | bsub
fi
