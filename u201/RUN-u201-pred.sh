#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U201 MOS Wind Development
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================
CYC=12
ELEMENT="wind"
MODEL="nam"
SAVEFORT12=1
SEASON="wm"
SHARED=1
SUBMIT=0

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
TAUS=$(seq --format "%03g" 6 3 84)

# ==============================================================================   
# Import dev environment
# ==============================================================================   
. ../dev.env

# ==============================================================================   
# Get DD from MODEL
# ==============================================================================   
DD=$(grep '^'"$MODEL" ../fix/model2dd | cut -d":" -f 2)

# ==============================================================================   
# Modify QUEUE if SHARED=yes.
# ==============================================================================   
if [ $SHARED -eq 1 ]; then
   QUEUE+="_shared"
fi

# Define and make WORKDIR
DATA=$DEVSTMP/u201_${MODEL}${CYC}_pred_${SEASON}
if [ ! -d $DATA ]; then
   mkdir -p $DATA
fi

# ==============================================================================   
# Iterate on TAUS, create and populate WORKDIR with necessary files and links.
# ==============================================================================   
for TAU in $TAUS
do

WORKDIR=$DATA/f${TAU}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# Create link to data_pred
ln -s $DEVDIR/u201/data_pred $WORKDIR/

# Copy files to WORKDIR
cp dates/u201.dates.${CYC}.${SEASON}.pred $WORKDIR/.
cp ../const/$CONST_GRD $WORKDIR/.
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/$STALST $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u201.x $WORKDIR/.

# Create predictor ID list. First get ISG value from tau2isg file.
if [ -f ../fix/tau2isg ]; then
   ISG=$(grep '^'"${TAU}" ../fix/tau2isg | cut -d":" -f 2)
else
   exit 1
fi
sed -e "s/DD/${DD}/g" \
    -e "s/XXX/${TAU}/g" \
    -e "s/ISG/${ISG}/g" ids/${ELEMENT}.pred.TEMPLATE > $WORKDIR/u201.ids.${MODEL}${CYC}.f${TAU}

# Create list of input files
printf " 60 $DD %-60s##MODEL INPUT\n" $(/bin/ls -1 data_pred/${MODEL}${CYC}*) > $WORKDIR/inputs

# Create list of RA input files
printf " 44    %-60s##GRIDDED CONSTANTS\n" $CONST_GRD >> $WORKDIR/rainput
printf " 45    %-60s##VECTOR CONSTANTS\n"  $CONST_STA >> $WORKDIR/rainput

# Create list of station list and table
printf " 30    %-60s##STATION LIST\n"  $STALST >> $WORKDIR/station
printf " 31    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Create U201.CN
sed -e "s/MMM/${MODEL}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/BB/${SEASON}/g" \
    -e "s/XXX/${TAU}/g" \
    -e "/<input>/r $WORKDIR/inputs" \
    -e "/<rainput>/r $WORKDIR/rainput" \
    -e "/<station>/r $WORKDIR/station" control/U201.CN_pred_TEMPLATE > $WORKDIR/U201.CN
sed -i '/<[a-z]*/d' $WORKDIR/U201.CN

# Create local run script
OUTPUT=$(grep '^199 ' $WORKDIR/U201.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u201.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u201.sh
echo "./u201.x" >> $WORKDIR/run-u201.sh
echo "cp $OUTPUT $DEVOUTDIR/u201/$OUTPUT" >> $WORKDIR/run-u201.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "cp fort.12 $DEVOUTDIR/u201/fort12_${MODEL}${CYC}_pred_f${TAU}_${SEASON}" >> $WORKDIR/run-u201.sh
fi
chmod 744 $WORKDIR/run-u201.sh

done # for TAU

# ==============================================================================   
# Build poescript and job card.
# ==============================================================================   
POESCRIPT=$DATA/poescript
if [ -f $POESCRIPT ]; then rm -f $POESCRIPT; fi
/bin/ls -1 $DATA/f*/run-u201.sh > $POESCRIPT
NTASKS=$(cat $POESCRIPT | wc -l)

if [ $NTASKS -le $MAXTHREADS ]; then
   PTILE=$NTASKS
else
   PTILE=$MAXTHREADS
fi

if [ -f $DATA/run-u201-poe.sh ]; then rm -f $DATA/run-u201-poe.sh; fi
cat << EOF > $DATA/run-u201-poe.sh
#BSUB -a poe
#BSUB -J  "u201-${MODEL}${CYC}-pred-${SEASON}"
#BSUB -oo "$DATA/u201-${MODEL}${CYC}-pred-${SEASON}.out"
#BSUB -W 04:00
#BSUB -n $NTASKS
#BSUB -R "span[ptile=$PTILE]"
#BSUB -R "affinity[core(1)]"
#BSUB -R "rusage[mem=1728]"
#BSUB -q "$QUEUE"
#BSUB -P "MDLST-T2O"
#
cd $DATA
#
export MP_PGMMODEL=mpmd
export MP_LABELIO=YES
export MP_STDOUTMODE="unordered"
chmod 755 poescript
mpirun.lsf -cmdfile ./poescript
#
EOF

# ==============================================================================   
# Submit job
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then
   chmod 744 $DATA/run-u201-poe.sh
   cat $DATA/run-u201-poe.sh | bsub
fi
