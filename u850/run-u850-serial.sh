#BSUB -a serial
#BSUB -J  "u850-gfs00-wm-sgroup1"
#BSUB -oo "u850-gfs00-wm-sgroup1.out"
#BSUB -W 02:00
#BSUB -n 1
#BSUB -R "span[ptile=1]"
#BSUB -R "affinity[core(1)]"
#BSUB -R "rusage[mem=2000]"
#BSUB -q "devhigh2"
#BSUB -P "MDLST-T2O"
#
cd /stmpp2/Eric.Engle/u850_gfs00_wind_wm_sgroup1/
./run-u850.sh
