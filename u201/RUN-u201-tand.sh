#!/bin/sh
set -x

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
# ==============================================================================
ELEMENT="wind"
MODEL="nam"
SEASON="wm"
SAVEFORT12=1
SHARED=0
STATYPE="marine"             # metar, marine, mesonet
SUBMIT=1

# ==============================================================================   
# Get the string the obs archive name
# ==============================================================================   
if [ "$STATYPE" == "metar" ]; then
   ARCHNAME="hre"
elif [ "$STATYPE" == "marine" ]; then
   ARCHNAME="mar"
elif [ "$STATYPE" == "mesonet" ]; then
   ARCHNAME="mesohre"
fi

# ==============================================================================   
# Import dev environment
# ==============================================================================   
. ../dev.env

# ==============================================================================   
# Get DD from MODEL. NOT NEEDED FOR PREDICTANDS
# ==============================================================================   
DD=$(grep '^'"$MODEL" ../fix/model2dd | cut -d":" -f 2)

# ==============================================================================   
# Modify QUEUE if SHARED=yes.
# ==============================================================================   
if [ $SHARED -eq 1 ]; then
   QUEUE+="_shared"
fi

# Define and make WORKDIR
WORKDIR=$DEVSTMP/u201_${MODEL}${ELEMENT}_${STATYPE}_tand_${SEASON}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# Create link to data_tand
ln -s $DEVDIR/u201/data_tand $WORKDIR/data_tand

# Copy files to WORKDIR
cp dates/u201.dates.${SEASON}.tand $WORKDIR/.
cp ../const/$CONST_GRD $WORKDIR/.
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/$STATYPE.lst $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u201.x $WORKDIR/.

# Create predictand ID file. This is simply copying the TEMPLATE file
cp ids/${ELEMENT}.tand.TEMPLATE $WORKDIR/u201.ids.wind.tand

# Create list of input files
printf " 80    %-60s##VECTOR INPUT\n" $(/bin/ls -1 data_tand/${ARCHNAME}* | grep -v ".sh" ) > $WORKDIR/inputs

# Create list of RA input files
printf " 44    %-60s##GRIDDED CONSTANTS\n" $CONST_GRD >> $WORKDIR/rainput
printf " 45    %-60s##VECTOR CONSTANTS\n"  $CONST_STA >> $WORKDIR/rainput

# Create list of station list and table
printf " 30    %-60s##STATYPE LIST\n"  $STATYPE.lst >> $WORKDIR/station
printf " 31    %-60s##STATYPE TABLE\n" $STATBL >> $WORKDIR/station

# Create U201.CN
sed -e "s/MMM/${MODEL}/g" \
    -e "s/BB/${SEASON}/g" \
    -e "s/SSS/${STATYPE:0:3}/g" \
    -e "/<input>/r $WORKDIR/inputs" \
    -e "/<rainput>/r $WORKDIR/rainput" \
    -e "/<station>/r $WORKDIR/station" control/U201.CN_tand_TEMPLATE > $WORKDIR/U201.CN
sed -i '/<[a-z]*/d' $WORKDIR/U201.CN

# Create local run script
OUTPUT=$(grep '^199 ' $WORKDIR/U201.CN | tr -s ' ' ' ' | cut -d" " -f 2)
echo "#!/bin/sh" >> $WORKDIR/run-u201.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u201.sh
echo "./u201.x" >> $WORKDIR/run-u201.sh
echo "cp $OUTPUT $DEVOUTDIR/u201/$OUTPUT" >> $WORKDIR/run-u201.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "cp fort.12 $DEVOUTDIR/u201/fort12_${MODEL}${ELEMENT}_${STATYPE:0:3}_tand_${SEASON}" >> $WORKDIR/run-u201.sh
fi
chmod 744 $WORKDIR/run-u201.sh

# ==============================================================================   
# Submit on the command line.
# ==============================================================================   
bsub  -J  "u201-${MODEL}${ELEMENT}-${STATYPE}-tand-${SEASON}" \
      -oo "u201-${MODEL}${ELEMENT}-${STATYPE}-tand-${SEASON}.out" \
      -W 01:00 \
      -q "$QUEUE" \
      -x \
      -P "MDLST-T2O" $WORKDIR/run-u201.sh
