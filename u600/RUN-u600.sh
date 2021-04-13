#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U600 MOS Wind Development (Regression Equation Generation)
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
#RUN="hold201412" # "holdYYYYMM" or "final"
RUN=$1 # "holdYYYYMM" or "final"
MULTITAU=1

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
TAUS=$(../ush/make-taus.sh 6,3,192,p 198,6,264,p)

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
# Define and make the output area
# ==============================================================================   
OUTDIR=$DEVOUTDIR/u600/$RUN
if [ ! -d $OUTDIR ];then mkdir -p $OUTDIR; fi

# ==============================================================================   
# Iterate on TAUS, create and populate WORKDIR with necessary files and links.
# ==============================================================================   
DATA=$DEVSTMP/u600_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${RUN}
for TAU in $TAUS
do

# Define and make WORKDIR
WORKDIR=$DATA/f${TAU}
if [ ! -d $WORKDIR ];then mkdir -p $WORKDIR; fi

# Create link to U201 output directory. This is U600 input
ln -s $DEVOUTDIR/u201 $WORKDIR/data

# Copy files to WORKDIR
cp dates/u600.dates.${CYC}.${SEASON}.${RUN} $WORKDIR/.
cp ../const/$CONST_GRD $WORKDIR/.
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/${STALST}_u600 $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u600.x $WORKDIR/.


./PREP-u600-id-list.sh $ELEMENT $DD $TAU $MULTITAU $WORKDIR/u600.ids.f$TAU

# Create list of Predictor input files
i=25
if [ $MULTITAU -eq 1 ]; then MORETAUS=$(grep '^'"${TAU:0:3}" ../fix/tau2isg | cut -d":" -f 3); fi
for TAU1 in $TAU $MORETAUS
do
   printf "% 2d    %-60s#PREDICTOR INPUT\n" $i data/u201.${MODEL}${CYC}.f${TAU1:0:3}.${SEASON} >> $WORKDIR/predinputs
   i=$(($i+1))
done

# Create list of RA input files
printf " 44    %-60s##GRIDDED CONSTANTS\n" $CONST_GRD >> $WORKDIR/rainputs
printf " 45    %-60s##VECTOR CONSTANTS\n" $CONST_STA >> $WORKDIR/rainputs

# Create list of station list and table. For U600, the station list needs to
# have a terminator after each station (single-station eqns) or group of
# stations (regional equation). This file should already be created and
# name in the following manner: STALST_u600_ELEMENT_SEASON.
printf " 30    %-60s##STATION LIST\n" ${STALST}_u600 >> $WORKDIR/station
printf " 31    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Define DD for U600.CN
if [ ${TAU//[ps]/} -le 15 ]; then
if [ "${TAU: -1}" == "p" ]; then
   DDCN=$(( ${DD//0/} + 10 ))
elif [ "${TAU: -1}" == "s" ]; then
   DDCN=$(( ${DD//0/} + 20 ))
fi
else
   DDCN=$DD
fi

# Create U600.CN
RUN10=$(printf "%-10s\n" $RUN)
sed -e "s/AA/${DDCN}/g" \
    -e "s/BB/${SEASON}/g" \
    -e "s/CCCCCCCCCC/${RUN10}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "s/XXX/${TAU:0:3}/g" \
    -e "s/YYYY/${TAU}/g" \
    -e "/<predinput>/r $WORKDIR/predinputs" \
    -e "/<rainput>/r $WORKDIR/rainputs" \
    -e "/<station>/r $WORKDIR/station" control/U600.CN_${ELEMENT}_TEMPLATE > $WORKDIR/U600.CN
sed -i '/<[a-z]*/d' $WORKDIR/U600.CN

# Create run script in WORKDIR
OUTPUT=$(grep '^199 ' $WORKDIR/U600.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u600.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u600.sh
echo "./u600.x" >> $WORKDIR/run-u600.sh
echo "cp $OUTPUT $OUTDIR/$OUTPUT" >> $WORKDIR/run-u600.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $OUTDIR/fort12_${MODEL}${CYC}_${ELEMENT}_f${TAU}_${SEASON}.gz" >> $WORKDIR/run-u600.sh
echo "gzip -c U600EFE118 > $OUTDIR/U600EFE118_${MODEL}${CYC}_${ELEMENT}_f${TAU}_${SEASON}.gz" >> $WORKDIR/run-u600.sh
echo "gzip -c U600EFE122 > $OUTDIR/U600EFE122_${MODEL}${CYC}_${ELEMENT}_f${TAU}_${SEASON}.gz" >> $WORKDIR/run-u600.sh
fi
chmod 744 $WORKDIR/run-u600.sh

done # for TAU

# ==============================================================================   
# Build $POESCRIPT and job card.
# ==============================================================================   
POESCRIPT=$DATA/poescript
if [ -f $POESCRIPT ]; then rm -f $POESCRIPT; fi
/bin/ls -1 $DATA/f*/run-u600.sh > $POESCRIPT
NTASKS=$(cat $POESCRIPT | wc -l)

if [ $NTASKS -le $MAXTHREADS ]; then
   PTILE=$NTASKS
else
   PTILE=$MAXTHREADS
fi

if [ -f $DATA/run-u600-poe.sh ]; then rm -f $DATA/run-u600-poe.sh; fi
cat << EOF > $DATA/run-u600-poe.sh
#BSUB -J  "u600-${MODEL}${CYC}-${ELEMENT}-${SEASON}-${RUN}"
#BSUB -oo "u600-${MODEL}${CYC}-${ELEMENT}-${SEASON}-${RUN}.out"
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
chmod 755 $POESCRIPT
mpirun.lsf -cmdfile $POESCRIPT
#
EOF

# ==============================================================================   
# Submit job
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then 
   chmod 744 $DATA/run-u600-poe.sh
   cat $DATA/run-u600-poe.sh | bsub
fi
