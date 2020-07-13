#!/bin/sh
set -x
# ==============================================================================   
# RUN script for U850 MOS Wind Development (Verification)
#
# Description of SGROUP values:
#
#     sgroup1 = Wind Speed BIAS and MAE.
#     sgroup2 = Wind Speed Heidke Skill Score.
#     sgroup3 = Wind Direction CRF of Errors LE 30.
#
# Notes: U850 will use the U201 predictand file as observational input. This
#        is OK since wind speed and direction data are not modified in the
#        U201 predictand generation process.
#
#        The directory data_fcst/ will be populated with forecast data from
#        the operational MOS (in MOM), forecasts from new equations in this
#        development, and any other models in which to verify with. There
#        should be only one file per "model", so sequential files will need to
#        be catted together and have different DDs. The operational MOS, for
#        the dates to run, will always have the real model DD (e.g. GFS=08) and
#        other GFS forecasts files should have a different DD.
#
#        Forecast files from new equations (i.e. this development) should be
#        run through U710, Step 4 (Create operational forecasts), then use
#        itdlp to change the DD. Other model files (except for the operational
#        MOS) should have their DD changed.
#
# ==============================================================================   

# ==============================================================================   
# Change variables. The following variables are yes/no, but use 1/0.
#      SAVEFORT12, SHARED, SUBMIT
#
# Notes:
#      MODELNAMES - Make sure the other of the names matches what is in the
#      U850 ID list file.
# ==============================================================================   
CYC=00
DDS="08,38,08,38"
ELEMENT="wind"
INDVSCORES=1                 # Individual Station Scores (0=no,1=yes), ZZ in U850.CN
MODEL="gfs"
MODELDMO=1
MODELNAMES="DMOOPER,DMOPARA,MOSOPER,MOSPARA"
SAVEFORT12=1
SEASON="cl"
SGROUP="sgroup1"
SHARED=0
SUBMIT=0
STRATVAL="0"          # 0 = no stratification, other = value to stratify
REGION="nws"                 # nws=NWS Regions; gfsvgtyp=GFS Vegetation Type

# ==============================================================================   
# Set TAUS.
# ==============================================================================   
TAUS=$(../ush/make-taus.sh 6,3,192)

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

# Define and make WORKDIR
WORKDIR=$DEVSTMP/u850_${MODEL}${CYC}_${ELEMENT}_${SEASON}_${SGROUP}
if [ ! -d $WORKDIR ]; then
   mkdir -p $WORKDIR
fi

# Create links to predictands, dev forecasts, and operational forecasts.
ln -s $DEVOUTDIR/u201 $WORKDIR/data_u201
ln -s $DEVDIR/u850/data_fcst $WORKDIR/data_fcst
ln -s $DEVDIR/u850/data_oper $WORKDIR/data_oper

# Copy files to WORKDIR
cp dates/u850.dates.${CYC}.${SEASON} $WORKDIR/.
cp ../table/${STALST}_u850_${REGION}_regions $WORKDIR/.
cp ../const/$CONST_GRD $WORKDIR/.
cp ../const/$CONST_STA $WORKDIR/.
cp ../table/$STATBL $WORKDIR/.
cp ../table/mos2000id.tbl $WORKDIR/.
cp sorc/u850.x $WORKDIR/.

# ---------------------------------------------------------------------------------------- 
# Create input file list. First is the predictand file -- the obs to verify against on
# unit 20; then operational forecasts on unit 21; then development forecasts on units
# 101+.
# ---------------------------------------------------------------------------------------- 
IUNIT=20
printf "%3d    %-60s##OBS INPUT\n" $IUNIT "data_u201/u201.${MODEL}wind.tand.${SEASON}" >> $WORKDIR/inputs

IUNIT=21
for file in data_oper/*
do
   printf "%3d    %-60s##OPER FCST INPUT\n" $IUNIT "$file" >> $WORKDIR/inputs
done

IUNIT=100
for file in data_fcst/*
do
   IUNIT=$(( $IUNIT + 1 ))
   printf "%3d    %-60s##FCST INPUT\n" $IUNIT "$file" >> $WORKDIR/inputs
done

# Create list of RA input files
printf " 44    %-60s##GRIDDED CONSTANTS\n" $CONST_GRD >> $WORKDIR/rainput
printf " 45    %-60s##VECTOR CONSTANTS\n"  $CONST_STA >> $WORKDIR/rainput

# Create list of station list and table.
printf " 36    %-60s##STATION LIST\n"  "${STALST}_u850_${REGION}_regions" >> $WORKDIR/station
printf " 37    %-60s##STATION TABLE\n" $STATBL >> $WORKDIR/station

# Create id filename.
printf " 38    %-60s##SCORE GROUP ID LIST\n" "u850.ids.${SGROUP}" >> $WORKDIR/sgroup

# Create U850.CN
sed -e "s/BB/${SEASON}/g" \
    -e "s/HH/${CYC}/g" \
    -e "s/MMM/${MODEL}/g" \
    -e "s/ZZ/ ${INDVSCORES}/g" \
    -e "/<input>/r $WORKDIR/inputs" \
    -e "/<rainput>/r $WORKDIR/rainput" \
    -e "/<sgroup>/r $WORKDIR/sgroup" \
    -e "/<station>/r $WORKDIR/station" control/U850.CN_TEMPLATE > $WORKDIR/U850.CN
sed -i '/<[a-z]*/d' $WORKDIR/U850.CN


# Create ID list. Here we need to send TAUS into the prep IDs script
# as a comma delimited list. MODELNAMES should already be comma delimited.

# Create ID list.  First well need to create a list of DDs to pass to the ID list
# creation script.
#for f in $(cut -c8- $WORKDIR/inputs | cut -d" " -f 1 | grep -v tand)
#do
#   itdlp $f -rec 2 | cut -d":" -f 3 | cut -d" " -f 1 | cut -c8-9 >> dd.temp
#done
#DDS=$(sort -n -u dd.temp)
#DDS=$(cat dd.temp)
#rm -f dd.temp
#./PREP-u850-id-list.sh $SGROUP ${DDS//$'\n'/,} ${TAUS//$'\n'/,} $MODELNAMES $STRATVAL $WORKDIR/u850.ids.${SGROUP}
./PREP-u850-id-list.sh $SGROUP ${DDS} ${TAUS//$'\n'/,} $MODELNAMES $STRATVAL $WORKDIR/u850.ids.${SGROUP}

# Create run script in WORKDIR
echo "#!/bin/sh" >> $WORKDIR/run-u850.sh
echo "cd $WORKDIR/" >> $WORKDIR/run-u850.sh
echo "./u850.x" >> $WORKDIR/run-u850.sh
if [ $SAVEFORT12 -eq 1 ]; then
echo "gzip -c fort.12 > $DEVOUTDIR/u850/fort12_${MODEL}${CYC}_${SEASON}_${SGROUP}_${REGION}.gz" >> $WORKDIR/run-u850.sh
fi
chmod 744 $WORKDIR/run-u850.sh

# ==============================================================================   
# Build job card. For U850 the submit script will simply cd in WORKDIR and
# execute the run script.
# ==============================================================================   
if [ -f run-u850-serial.sh ]; then rm -f run-u850-serial.sh; fi
cat << EOF > run-u850-serial.sh
#BSUB -a serial
#BSUB -J  "u850-${MODEL}${CYC}-${SEASON}-${SGROUP}"
#BSUB -oo "u850-${MODEL}${CYC}-${SEASON}-${SGROUP}.out"
#BSUB -W 02:00
#BSUB -n 1
#BSUB -R "span[ptile=1]"
#BSUB -R "affinity[core(1)]"
#BSUB -R "rusage[mem=2000]"
#BSUB -q "$QUEUE"
#BSUB -P "MDLST-T2O"
#
cd $WORKDIR/
./run-u850.sh
EOF

# ==============================================================================   
# Submit job
# ==============================================================================   
if [ $SUBMIT -eq 1 ]; then 
   chmod 744 run-u850-serial.sh
   cat run-u850-serial.sh | bsub
fi
