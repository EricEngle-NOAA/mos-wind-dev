# U201
MOS Program U201 generates predictand and predictor data given the appropriate input data.  This directory has the following structure:

**`control/`** - contains U201.CN template files for predictand runs and predictor runs.

**`data_pred/`** - directory to store input model TDLPACK files.  **NOTE:** Use symbolic links to the actual files.

**`data_tand/`** - directory to store input observation TDLPACK files.  **NOTE:** Use symbolic links to the actual files.

**`dates/`** - contains template files for specifying dates for predictand and predictor runs.  The template file for predictand is `u201.dates.BB.tand` and predictors is `u201.dates.HH.BB.pred` where `BB` = season (`cl` or `wm`) and `HH` = model cycle (i.e. `00`).  Here is an example of the format of the date file

```
 19100100 -20033100
 99999999
```

**`ids/`** - contains predictand and predictor ID lists.  These should not need much changing.  The predictor file contains placeholder text for DD, TAU, and ISG parts of the MOS-2000 ID.

**`sorc/`** - U201 program driver source and makefile.  Once compiled, leave u201.x executable in this directory.

There are 2 run scripts, `RUN-u201-pred.sh` and `RUN-u201-tand.sh`.  See these scripts for usage.
