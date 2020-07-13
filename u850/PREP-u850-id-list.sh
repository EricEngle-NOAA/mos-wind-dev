#!/bin/sh
# ======================================================================== 
# Script: make-u850-id-list.sh
#
# Usage: make-u850-id-list.sh SGROUP DDS TAUS MODELNAMES STRATVAL [OUTPUT]
#
# Arguments:
#
# SGROUP = U850 score group (e.g. "sgroup1")
#
# DDS = List of model DDs.
#
# TAUS = List of forecast projections (comma delimited)
#
# MODELNAMES = List of model names to inset into ID files
#              (comma delimited)
#
# STRATVAL = Value to stratify verification by (omitted when 0).
#
# OUTPUT = Output filename. This is optional. TEMPFILE is retained.
# ======================================================================== 
set -x

if [ $# -lt 5 ]; then
   exit 1
fi

SGROUP=$1
DDS=$2
TAUS=$3
MODELNAMES=$4
STRATVAL=$5
OUTPUT=$6

TEMPFILE=temp.$$
TERM8X6="   888888"
TERM9X6="   999999"

# ======================================================================== 
# Template files to work from.
# ======================================================================== 
HEADER_TEMP=ids/u850_header_${SGROUP}_TEMPLATE

# ======================================================================== 
# Determine the number of models. This is done by counting the number
# of delimiters (",") in MODELNAMES and adding 1.
# ======================================================================== 
DELIMITERS=${MODELNAMES//[^,]}
NMODELS=$(( ${#DELIMITERS} + 1)) 


# ======================================================================== 
# Start the ID file with a header
# ======================================================================== 
cat $HEADER_TEMP >> $TEMPFILE
echo "999999" >> $TEMPFILE

# ======================================================================== 
# Interate over FCST then OBS. The U850 ID file has forecast IDs first
# followed by observation IDs.
# ======================================================================== 
if [ "$STRATVAL" != "0" ]; then
   FOS="fcst obs strat"
   STRATVAL1=$STRATVAL
else
   FOS="fcst obs"
   STRATVAL1="0000E+00"
fi

for FO in $FOS
do

#IDTEMP=ids/u850_${FO}_${SGROUP}_TEMPLATE

# ======================================================================== 
# Iterate over TAUS. TAUS comes in this script delimited by commas so
# that the entire list can be contaied in one argument.
# ======================================================================== 
for TAU in ${TAUS//,/ }
do

   i=1
   for MODEL in ${MODELNAMES//,/ }
   do

      if [ "$FO" == "fcst" ] && [[ $MODEL == *DMO* ]]; then
         IDTEMP=ids/u850_${FO}_${SGROUP}_TEMPLATE_DMO
      else
         IDTEMP=ids/u850_${FO}_${SGROUP}_TEMPLATE
      fi

      # Set DD.  The operational model will always be first.
      #if [ $i -eq 1 ]; then
      #   DD=$BASEDD
      #elif [ $i -eq 2 ]; then
      #   DD=$(( 10#$BASEDD + 30 ))
      #else
      #   DD=$(( $DD + 10 ))
      #fi
      DD=$(echo $DDS | cut -d"," -f $i)
      sed -e "s/DD/${DD}/g" \
          -e "s/XXX/${TAU:0:3}/g" \
          -e "s/PLAIN/${MODEL}/g" \
          -e "s/STRATVAL/${STRATVAL1}/g" $IDTEMP >> $TEMPFILE

      #if [ "$FO" == "obs" -a $i -eq 1 ]; then break; fi
      #if [ "$FO" == "strat" -a $i -eq 1 ]; then break; fi
      if [ "$FO" != "fcst" -a $i -eq 1 ]; then break; fi

      i=$(( $i + 1 ))

   done # for MODEL

   # Finished with a group of fcst/obs IDs for a given
   # projection.  Write 8's terminator.
   echo "$TERM8X6" >> $TEMPFILE

done # for TAU

   # Finished with either fcst or obs IDs for all
   # projections.  Write 9's terminator.
   echo "$TERM9X6" >> $TEMPFILE

done # for FO

# Insert terminators
echo "$TERM9X6"  >> $TEMPFILE # This is terminator for "matching variables" (i.e. stratification variables)
echo $TERM9X6  >> $TEMPFILE   # No double quotes makes this terminator left-justified (no leading spaces)

# If OUTPUT is set, then copy TEMPFILE to OUTPUT
# and remove TEMPFILE.
if [ ! -z $OUTPUT ]; then
   cp $TEMPFILE $OUTPUT
   rm -f $TEMPFILE
fi
