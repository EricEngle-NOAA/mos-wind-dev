#!/bin/sh
#
# Script: make-taus.sh
#
# Purpose: The purpose of this script is to provide a simple interface for creating
#          a list of forecast projections with varying increments along with a
#          suffixed string.  Note that each input argument PAIR has 4 sub-arguments.
#
# Usage: make-taus.sh PS,  PAIR1, PAIR2, ..., PAIRn
#
# Arguments:
#      PAIRn = FIRST,INCREMENT,LAST,PS
#      FIRST = Beginning forecast projection in PAIRn.
#  INCREMENT = Interval at which forecast projections are to be generated.
#       LAST = Ending forecast projection in PAIRn.
#         PS = Suffix string for each forecast projection in PAIR. This is optional.
#
# ======================================================================================== 
#set -x

if [ $# -eq 0 ]; then exit 0; fi

# ======================================================================================== 
# Initialize TAUS
# ======================================================================================== 
unset TAUS

# ======================================================================================== 
# Interate over the input arugments.
# ======================================================================================== 
for PAIR in $@
do

   # Parse the PAIR
   FIRST=$(echo $PAIR | cut -d"," -f 1)
   INCREMENT=$(echo $PAIR | cut -d"," -f 2)
   LAST=$(echo $PAIR | cut -d"," -f 3)
   PS=$(echo $PAIR | cut -d"," -f 4)

   # Test to see if FIRST > LAST.
   if [ $FIRST -gt $LAST ]; then exit 1; fi

   # Build the list of forecast projections.
   TAUS+="$(seq --format="%03g$PS" --separator=":" $FIRST $INCREMENT $LAST):"

done

# ======================================================================================== 
# Print the forecast projections. The projections are printed on new lines so one
# can invoke this script and pipe to wc -l to get the number of forecast projections.
# ======================================================================================== 
echo ${TAUS%?} | tr -s ':' '\n' | sort -n
