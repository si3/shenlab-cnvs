#!/bin/bash

# This script starts the CLAMMS algorithm to call CNVs
# It invokes two sub-scripts, CLAMMS_normalizer and CLAMMS_model_fitter
# Should be in CLAMMS_OUT

# InpFil - (required) path to bam_list
# RefFil - (required) shell file containing resources for this batch
# LogFil - (optional) log to monitor progress
# TgtFil - (optional) capture kit used in batch, support pending

# Required directories
# PROJ_DIR
# COV_DIR
# CLAMMS

usage="
	this script runs all steps of the CLAMMS workflow
	Calls CNVs in samples based on mean RD and interval file
	Output will go into CLAMMS_output

	Run_CLAMMS.sh

	-i (required) path/to/bam_list
	-r (required) path/to/shell/ref/file
	-l (optional) path/to/log
	-t (optional) path/to/targets, used when no -r
	-H (flag) prints this message

	Usage: bash Run_CLAMMS.sh -i InpFil -r RefFil -l LogFil
"

while getopts i:r:l:t:H opt; do
        case "$opt" in
                i) InpFil="$OPTARG";;
                r) RefFil="$OPTARG";;
                l) LogFil="$OPTARG";;
                t) TgtBed="$OPTARG";;
                H) echo "$usage"; exit;;
        esac
done

# Check input
if [[ ! -e "$InpFil" ]] || [[ ! -e "$RefFil" ]]; then echo "Missing/incorrect required arguments"; echo "$usage"; exit; fi

# Call the RefFil to load variables
RefFil=`readlink -f $RefFil`
source $RefFil

# Set variables
InpFil=`readlink -f $InpFil`
NoSamples=`wc -l $InpFil | cut -f1 -d" "`
BATCH=`basename $InpFil | cut -f1 -d"."`
WindFil=`readlink -f $WindFil`

# Create log file unless specified
if [[ -z "$LogFil" ]]; then
        LogFil=StartCLAMMSexomeCNV.$$.log
else
        LogFil=`readlink -f $LogFil`
fi

LogNam=`basename $LogFil`
TmpLog="CLAMMS_caller_"$LogNam

# Load script library
source $PROJ_DIR/cnv.exome.lib.sh

# Starts TmpLog
ProcessName="CNV calling using CLAMMS algorithm on $NoSamples samples"
funcWriteStartLog

# First run CLAMMS_normalizer
StepNam="Normalizing in parallel $NoJobs samples at a time"
StepCmd="seq 1 $NoSamples | parallel -j $NoJobs --eta --joblog CLAMMS_normalizer_parallel.$$.log sh $COV_DIR/Run_CLAMMS_normalizer.sh -i $InpFil -r $RefFil -l $LogFil -a {}"
BatchNam="CLAMMSnorm1"
funcRunBatch

# Then run CLAMMS_model_fitter and call CNVs
mv $COV_DIR/Run_CLAMMS_model_fitter.sh $COV_DIR/mosdepth
StepNam="Fitting models and discovering CNVs"
StepCmd="bash $COV_DIR/mosdepth/Run_CLAMMS_model_fitter.sh -i $InpFil -r $RefFil -l $LogFil"
BatchNam="CLAMMSfit1"
funcRunBatch CLAMMSnorm1

if qstat -r | grep -qw "CLAMMSnorm1"; then
echo "CLAMMSnorm1 job submitted via qsub" >> $TmpLog
fi
if qstat -r | grep -qw "CLAMMSfit1"; then
echo "CLAMMSfit1 job submitted via qsub" >> $TmpLog
fi
funcWriteEndLog
