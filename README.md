# MOS Wind Development Template
This repository is a directory structure template for performing a station-based MOS Wind (Wind Speed, Direction, and Gust) development).  The template is struture where each MOS UXXX program is its own direcotry, along with directories for statics files that are meant to be shared across the various programs.  Each uXXX/ directory contains many templated files and run scripts, however, the actual MOS UXXX programs are not provided here.

## Environment Setup

### Environment Variables
Setup your environment by editing [dev.env](./env/dev.env).  This file contains environment variables that are used throughout the development workflow.  This file also sources env files for NOAA HPC systems.  If you are not developing on these system, then modify env files as needed.

### Static Files
Setup files in `table/` and `const/` directories. See the README files in those directories.

## Predictand and Predictor Generation
Predictand and predictor generation is done using program [u201](./u201).  See the u201 directory [README](./u201/README.md) and u201 RUN scripts for more information.  For predictand generation, you must run u201 for METAR and Marine stations separately.  Once these have been completed, run [u662](./u662/) to merge METAR and Marine predictand TDLPACK files into a single file.
