#!/bin/sh
set -x

SG='sgroup1a'

TAUS=$(seq 6 3 192 && seq 198 6 264)
for tau in $TAUS
do

   tau1=$(printf "%.3d" $tau)

   #  Insert forecast projection for forecast IDs
   #sed -e "s/XXX/${tau1}/g" \
   #    -e "s/YYY/${ISG}/g" ids_fcst_${SG}.TMPL >>tempA
   sed -e "s/XXX/${tau1}/g" ids_fcst_${SG}.TMPL >>tempA
   #  Insert forecast projection for observation IDs
   #sed -e "s/XXX/${tau1}/g" \
   #    -e "s/YYY/${ISG}/g" ids_wsob_${SG}.TMPL >>tempB
   sed -e "s/XXX/${tau1}/g" ids_wsob_${SG}.TMPL >>tempB
   #  Insert forecast projection for statification IDs
   sed -e "s/XXX/${tau1}/g" ids_wsob_strat_${SG}.TMPL >> tempC
#
done 
#
echo "   999999" >> tempA
#
echo "   999999" >> tempB
echo "   999999" >> tempC
echo "999999   " >> tempC
#
cat header_${SG} tempA tempB tempC > ${SG}_wspd.ids
#cat header_${SG} tempA tempB > ${SG}_wdir.ids
rm -f temp*
