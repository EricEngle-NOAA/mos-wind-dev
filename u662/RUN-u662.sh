#!/bin/sh
# ==============================================================================   
# RUN script for U662 (Combine METAR and Marine Predictand Data)
#
# This process is very quick so no need to run in stmp or submit to LSF.
# ==============================================================================   
if [ $# -ne 3 ]; then
   echo "Usage: $(basename $0) MODEL ELEMENT SEASON"
   echo ""
   echo "   MODEL = model string"
   echo "   ELEMENT = \"wind\""
   echo "   SEASON = season string"
   echo ""
   exit 1
fi
MODEL=$1
ELEMENT=$2
SEASON=$3

# ==============================================================================   
# Import dev environment
# ==============================================================================   
set -x
. ../env/dev.env

# Create symlinks to U201 metar and marine predictand files.
ln -s $DEVOUTDIR/u201/u201.${MODEL}${ELEMENT}.met.tand.${SEASON} .
ln -s $DEVOUTDIR/u201/u201.${MODEL}${ELEMENT}.mar.tand.${SEASON} .
echo " 20    u201.${MODEL}${ELEMENT}.met.tand.${SEASON}" >> input
echo " 21    u201.${MODEL}${ELEMENT}.mar.tand.${SEASON}" >> input

# Copy files to WORKDIR
ln -s $DEVDIR/u201/dates/u201.dates.${SEASON}.tand .
ln -s $DEVDIR/table/$STALST .
ln -s $DEVDIR/table/$STATBL .
ln -s $DEVDIR/table/mos2000id.tbl .
ln -s sorc/u662.x .

# Create list of station list and table.
printf " 30    %-60s##STATION LIST\n"  $STALST >> station
printf " 31    %-60s##STATION TABLE\n" $STATBL >> station

# Create U600.CN
sed -e "s/BB/${SEASON}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "/<input>/r input" \
    -e "/<station>/r station" control/U662.CN_TEMPLATE > U662.CN
sed -i '/<[a-zA-Z]>*/d' U662.CN

# Run U662.x
./u662.x

# Move the output file to u201 output area.
OUTPUT=$(grep '^199 ' U662.CN | tr -s ' ' ' ' | cut -d" " -f 2)
mv $OUTPUT $DEVOUTDIR/u201/$OUTPUT

# Clean up.
find -maxdepth 1 -type l -exec unlink {} \;
rm -f input station U662.CN
