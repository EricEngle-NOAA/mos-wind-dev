#!/bin/sh
# ======================================================================== 
# Script: make-u710-id-list.sh
#
# Usage: make-u710-id-list.sh ELEMENT STEP BASEDD TAUS [OUTPUT]
#
# Arguments:
#
# ELEMENT = wind - 10-m u, v, and speed
#           gust - wind gust speed and prob 
#
# STEP = post-processing step (e.g. "step1")
#
# BASEDD = model base DD (e.x. gfs = 08).
#
# TAUS = list of forecast projections (comma delimited)
#
# OUTPUT = output filename. This is optional. TEMPFILE is retained.
# ======================================================================== 
set -x

if [ $# -lt 4 ]; then
   exit 1
fi

ELEMENT=$1
STEP=$2
BASEDD=$3
TAUS=$4
OUTPUT=$5

TEMPFILE=temp.$$

# ======================================================================== 
# Template files to work from.
# ======================================================================== 
WINDU700TEMP=ids/u710_windu700_TEMPLATE
ELEMENTTEMP=ids/u710_${ELEMENT}_TEMPLATE

# ======================================================================== 
# Iterate over TAUS. TAUS comes in this script delimited by commas so
# that the entire list can be contaied in one argument.
# ======================================================================== 
for TAU in ${TAUS//,/ }
do

   # Logical for is TAU "s" suffix.
   hasS=0

   # Set PS
   PS=${TAU: -1}

   # Check PS. If PS is a number (0-9), then just set DD to BASEDD which
   # means there is suffix in TAUS.
   if [[ "$PS" =~ [0-9] ]]; then
      DD=$BASEDD
   elif [[ "$PS" =~ [a-zA-Z] ]]; then
      if [ "$PS" != "p" -a "$PS" != "s" ]; then exit 1; fi
      if [ "$PS" == "p" -a ${TAU:0:3} -le 15 ]; then
         DD=$(( 10#$BASEDD + 10 ))
      elif [ "$PS" == "s" -a ${TAU:0:3} -le 15 ]; then
         hasS=1
         DD=$(( 10#$BASEDD + 20 ))
      else
         DD=$BASEDD
      fi
   fi

   # Build the ID files.
   if [ "$STEP" == "step4" ]; then
      if [ $hasS -eq 1 ]; then continue; fi
      # Step 4. Simply makes "operational forecasts" meaning the primary and
      # secondary forecasts are selected for an operational forecast where
      # DD = BASEDD.
      DD=$BASEDD
      sed -e "s/DD/${DD}/g" \
          -e "s/XXX/${TAU:0:3}/g" $WINDU700TEMP $ELEMENTTEMP >> $TEMPFILE
   else
      # Search in the template file for the ID associated with STEP.
      grep -i "$STEP" $ELEMENTTEMP |
      sed -e "s/DD/${DD}/g" -e "s/XXX/${TAU:0:3}/g" >> $TEMPFILE
   fi

done 

# Insert terminator
echo "   999999" >> $TEMPFILE

# If OUTPUT is set, then copy TEMPFILE to OUTPUT
# and remove TEMPFILE.
if [ ! -z $OUTPUT ]; then
   cp $TEMPFILE $OUTPUT
   rm -f $TEMPFILE
fi
