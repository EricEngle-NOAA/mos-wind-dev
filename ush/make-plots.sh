#!/bin/sh
#set -x

if [ $# -ne 5 ]; then exit 1; fi

FORT12=$1
SCORE=$2
TAUGEN=$3
CYC=$4
SEASON=$5

# ======================================================================================== 
# Source the development environment file.
# ======================================================================================== 
. ../dev.env

# ======================================================================================== 
# Create date string for plots.
# ======================================================================================== 
DATE1=$(date --date="$(sed -n 1p $DEVDIR/u850/dates/u850.dates.$CYC.$SEASON | cut -c3-8)" +%D)
DATE2=$(date --date="$(sed -n 2p $DEVDIR/u850/dates/u850.dates.$CYC.$SEASON | cut -c3-8)" +%D)
DATE_STRING="$DATE1 - $DATE2, ${CYC}Z Cycle"

# ======================================================================================== 
# Determine which grep to uze based on if the fort.12 is compressed (gzip).
# ======================================================================================== 
file $FORT12 | grep -q gzip
if [ $? -eq 0 ]; then
   GREP=zgrep
else
   GREP=grep
fi

# ======================================================================================== 
# Obtain region and model names.
# ======================================================================================== 
REGIONS="OVERALL $($GREP '^ GROUP  ' $FORT12 | tr -s ' ' ' ' | cut -d" " -f 6)"
MODELS=$($GREP '^ 20[0-9]' $FORT12 | tr -s ' ' ' ' | cut -d" " -f 11 | sort -u)
NMODELS=$(echo $MODELS | tr ' ' '\n' | wc -l)
TAUS=$(seq ${TAUGEN//,/ })
NTAUS=$(seq ${TAUGEN//,/ } | wc -l)

case $SCORE in
   "BIAS")
      METHOD=1
      OFFSET=$(($NTAUS+4))
      COL_BEGIN=$((4+$NMODELS))
      COL_END=$(($COL_BEGIN+(((($NMODELS-1))*2))))
      COLS=$(seq -s, $COL_BEGIN 2 $COL_END)
      ;;
   "CRF")
      METHOD=3
      OFFSET=$((3+(($NMODELS*7))))
      ;;
   "HEIDKE")
      METHOD=2
      OFFSET=$((3+(($NMODELS*4))))
      ;;
   "MAE")
      METHOD=1
      OFFSET=$(($NTAUS+4))
      COLS=$(seq -s, 3 1 $((2+$NMODELS)))
      ;;
   *) ;;
esac

# ======================================================================================== 
# Extract the scores from fort.12.
# ======================================================================================== 
echo "#PROJ $(echo $MODELS | tr '\n' ' ')" > header.temp
seq ${TAUGEN//,/ } > proj.temp

for REGION in $REGIONS
do
   
   if [ "$REGION" == "OVERALL" ]; then
      REGION1=" OVERALL"
   else
      REGION1="   $REGION"
   fi

   if [ $METHOD -eq 1 ]; then
      $GREP -A$OFFSET '^'"$REGION1"' ' $FORT12 | tail -$NTAUS | tr -s ' ' ' ' |
      sed 's/^ //g' | cut -d" " -f $COLS > scores.temp
   elif [ $METHOD -eq 2 ]; then
      rm -f scores.temp
      for TAU in $TAUS
      do
         $GREP -A$OFFSET '^'"$REGION1"' ' $FORT12 | grep -A$(($OFFSET-3)) " $TAU-HR " |
         grep HEIDKE | tr -s '[A-Z]' ' ' | sed 's/ //g' | 
         pr --columns=$NMODELS --length=1 --separator=" " >> scores.temp
      done
   elif [ $METHOD -eq 3 ]; then
      rm -f scores.temp
      for TAU in $TAUS
      do
         $GREP -A$OFFSET '^'"$REGION1"' ' $FORT12 | grep -A$(($OFFSET-3)) " $TAU-HR " |
         grep "CUM RF" | tr -s ' ' ' ' | cut -d" " -f 7 |
         pr --columns=$NMODELS --length=1 --separator=" " >> scores.temp
      done
   fi

   paste -d" " proj.temp scores.temp > scores1.temp
   cat header.temp scores1.temp > ${REGION}_${SCORE}.txt
done
rm -f *.temp

# ======================================================================================== 
# Make plots using GNUPlot
# ======================================================================================== 
GNUPLOT=/mdlstat/save/util/gnuplot-5.0.1/bin/gnuplot

MODELS_ARR=($MODELS)

LASTTAU=$(echo $TAUGEN | cut -d"," -f 3)
TAUINT=$(echo $TAUGEN | cut -d"," -f 2)

XRES=1920
YRES=1080

for REGION in $REGIONS
do

XLABEL="Forecast Projection (hours)"

case $SCORE in
   "BIAS")
      ELEMENT="WSPD"
      TITLE="${MODEL^^} MOS $ELEMENT Bias ($DATE_STRING)\n$REGION Region"
      YLABEL="Bias (knots)"
      YRANGE="-3.0:3.0"
      ;;
   "CRF")
      ELEMENT="WDIR"
      TITLE="${MODEL^^} MOS $ELEMENT CRF of Errors <= 30 Deg. ($DATE_STRING)\n$REGION Region"
      XLABEL+="\n* Verified when observed wind speed >= 10 knots"
      YLABEL="CRF"
      YRANGE="0.0:1.0"
      ;;
   "HEIDKE")
      ELEMENT="WSPD"
      TITLE="${MODEL^^} MOS $ELEMENT Heidke SKill Score ($DATE_STRING)\n$REGION Region"
      YLABEL="HSS"
      YRANGE="0.0:1.0"
      ;;
   "MAE")
      ELEMENT="WSPD"
      TITLE="${MODEL^^} MOS $ELEMENT MAE ($DATE_STRING)\n$REGION Region"
      YLABEL="MAE (knots)"
      YRANGE="0.0:5.0"
      ;;
   *)
      ;;
esac

# Set some variables to send to GNUPlot for formatting axes.
DATA=${REGION}_${SCORE}.txt
XRANGEL=`grep -v '^#' $DATA | head -1 | cut -d " " -f 1`
XRANGEU=`grep -v '^#' $DATA | tail -1 | cut -d " " -f 1`
XTICS="(`grep -v '^#' $DATA | cut -d " " -f 1 | tr '\012' ',' | sed "s/${XRANGEU},/${XRANGEU}/g"`)"

# Run GNUPlot.
$GNUPLOT << EOF
set term png truecolor nocrop size $XRES,$YRES
set output "$DEVDIR/plots/${ELEMENT}_${REGION}_${SCORE}_${SEASON^^}.png"
set xrange [${XRANGEL}:${XRANGEU}]
set yrange [${YRANGE}]
set xlabel "$XLABEL"
set ylabel "$YLABEL"
set title "$TITLE"
set xtics $XTICS
set key outside center bottom horizontal height 3 width 6
set grid
set xzeroaxis lt 3 lw 2.0 lc rgb "black"
set datafile missing "?"
plot "$DATA" using 1:(\$2) title "${MODELS_ARR[0]}" with linespoints lw 2.0 lc rgb "navy" ps 1.5 pt 13, \
     "$DATA" using 1:(\$3) title "${MODELS_ARR[1]}" with linespoints lw 2.0 lc rgb "red" ps 1.5 pt 5, \
     "$DATA" using 1:(\$4) title "${MODELS_ARR[2]}" with linespoints lw 2.0 lc rgb "green" ps 1.5 pt 5
EOF
rm -f $DATA

done
