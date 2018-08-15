#!/bin/bash

# This script takes output from mosdepth and bedtools and converts it into input for CANOES, XHMM, CLAMMS
# Calls subscripts that need to be in COV_DIR (same as output from mosdepth and bedtools)

# InpFil - (required) path to bam file or bam list
# RefFil - (required) shell file containing resources for this batch run
# LogFil - (optional) log to monitor progress
# TgtBed - (optional) capture kit used in this batch, may be redundant
# Pipeline - continues pipeline by running next step
# Help - get usage information

# List of variables
# COV_DIR
# PROJ_DIR
# RES_DIR
# SAMPLE_INFO_DIR

usage="
	this script will convert output from mosdepth and bedtools
	into input for CANOES, CLAMMS and XHMM
	
	Run_RD_reformatters.sh
	
	-i (required) path/to/bam_list
	-r (required) path/to/cnv.exome.references.sh
	-l (optional) path/to/log
	-t (optional) path/to/targets.bed
	-P (flag) calls next step in pipeline
	-H (flag) echo this message

	Usage: bash Run_RD_reformatters.sh -i InpFil -r RefFil
"

Pipeline="false"

while getopts i:r:l:a:t:PH opt; do
        case "$opt" in
                i) InpFil="$OPTARG";;
                r) RefFil="$OPTARG";;
                l) LogFil="$OPTARG";;
                t) TgtBed="$OPTARG";;
                P) Pipeline="true";;
                H) echo "$usage"; exit;;
        esac
done

# Check input
if [[ ! -e "$InpFil" ]] || [[ ! -e "$RefFil" ]]; then echo "Missing/incorrect required arguments"; echo "$usage"; exit; fi

# Call the RefFil to load variables
RefFil=`readlink -f $RefFil`
source $RefFil

# Check directories
if [[ ! -d "$COV_DIR/mosdepth" ]] || [[ ! -d "$COV_DIR/bedtools" ]]; then echo "Can't find output from mosdepth/bedtools, check if directory exists"; echo "$usage"; exit; fi

# Set variables
InpFil=`readlink -f $InpFil`
NoSamples=`wc -l $InpFil | cut -f1 -d" "`
NoJobs=$NoJobs
BamFil=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 1)
BamNam=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 2)
WindFil=`readlink -f $WindFil`
LogFil=`readlink -f $LogFil`

TmpLog="RD_reformatter_"$LogFil

# Load script library
source $PROJ_DIR/cnv.exome.lib.sh

ProcessName="reformatting RD output"
funcWriteStartLog

# First run bedtools_to_CANOES and then initiate CANOES pipeline if -P
StepNam="Converting bedtools to CANOES"
StepCmd="bash Run_bedtools_to_CANOES.sh $InpFil $WindFil"
funcRunStep

funcRunPipeline

# Secondly run mosdepth_to_XHMM, initiate XHMM pipeline if -P
StepNam="Converting mosdepth to XHMM"
StepCmd="bash Run_mosdepth_to_XHMM.sh $InpFil $WindFil"
funcRunStep

NextJob=
NextCmd=
funcRunPipeline

# Thirdly run CLAMMS_normalizer, continue pipeline if -P
StepNam="Starting CLAMMS workflow by normalizing in parallel $NoJobs samples at a time"
StepCmd="seq 1 $NoSamples | parallel -j $NoJobs --eta --joblog RD_normalizer_parallel.$$.log sh $COV_DIR/Run.CLAMMS_normalizer.sh -i $InpFil -r $RefFil -l $LogFil -a {}"
funcRunStep

NextJob=
NextCmd=
funcRunPipeline
funcWriteEndLog

