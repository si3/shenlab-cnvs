#!/bin/bash

# This script takes output from mosdepth and bedtools and converts it into input for CANOES, XHMM, CLAMMS
# Calls other scripts that need to be in COV_DIR (same as output from mosdepth and bedtools)
# If P="true" then it will also call XHMM and CLAMMS (support for CANOES pending)
# 

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

# List of scripts:
# Run_bedtools_to_CANOES.sh
# Run_mosdepth_to_XHMM.sh
# Run_XHMM (if $Pipeline=true)
# Run_CLAMMS_normalizer (if $Pipeline=true)

usage="
	this script will convert output from mosdepth and bedtools
	into input for CANOES, CLAMMS and XHMM
	
	Run_RD_reformatters.sh
	
	-i (required) path/to/bam_list
	-r (required) path/to/cnv.exome.references.sh
	-l (optional) path/to/log
	-t (optional) path/to/targets.bed
	-P (flag) invokes XHMM and CLAMMS after reformatting
	-H (flag) echo this message

	Usage: bash Run_RD_reformatters.sh -i InpFil -r RefFil
"

Pipeline="false"

while getopts i:r:l:t:PH opt; do
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
#BamFil=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 1)
#BamNam=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 2)
WindFil=`readlink -f $WindFil`

# Create log file unless specified
if [[ -z "$LogFil" ]]; then
        LogFil=ReformatRDexomeCNV.$$.log
else
        LogFil=`readlink -f $LogFil`
fi

LogNam=`basename $LogFil`
TmpLog="RD_reformatter_"$LogNam

# Load script library
source $PROJ_DIR/cnv.exome.lib.sh

# Starts TmpLog
ProcessName="reformatting RD output"
funcWriteStartLog

# First run bedtools_to_CANOES and then initiate CANOES pipeline if -P
mv $COV_DIR/Run_bedtools_to_CANOES.sh $COV_DIR/bedtools
StepNam="Converting bedtools to CANOES"
StepCmd="bash $COV_DIR/bedtools/Run_bedtools_to_CANOES.sh $InpFil $WindFil $COV_DIR/bedtools"
funcRunStep

# NextJob= 
# if [[Pipeline]] Runs CANOES R scripts
# funcRunPipeline

# Secondly run mosdepth_to_XHMM, initiate XHMM pipeline if -P
mv $COV_DIR/Run_mosdepth_to_XHMM.sh $COV_DIR/mosdepth
StepNam="Converting mosdepth to XHMM"
StepCmd="bash $COV_DIR/mosdepth/Run_mosdepth_to_XHMM.sh $InpFil $WindFil $COV_DIR/mosdepth"
funcRunStep

#wait

# Thirdly continue pipeline, run CLAMMS workflow if -P
if [[ $Pipeline == "true" ]]; then
	NextJob="CLAMMS workflow on $NoSamples samples"
	NextCmd="bash $CLAMMS_OUT/Run_CLAMMS.sh -i $InpFil -r $RefFil -l $LogFil"
#	BatchNam="CLAMMScnv1"
	funcPipeline
	NextJob="XHMM workflow on $NoSamples samples"
	NextCmd="bash $XHMM_OUT/Run_XHMM.sh -i $InpFil r $RefFil -l $LogFil"
	BatchNam="XHMMcnv1"
	funcPipeBatch
#	NextJob="CANOES workflow on $NoSamples samples"
#	NextCmd="bash $CANOES_OUT/Run_CANOES.sh"
#	BatchNam="CANOEScnv1"
#	funcPipeBatch
#	NextJob="notification of pipeline completion"
#	NextCmd=`mailx -s "XHMM pipeline run completed" $USER < $LogFil`
#	BatchNam="cnvNote1"
#	funcPipeline CLAMMScnv1, XHMMcnv1, CANOEScnv1 
else
	echo "CNV calling workflows not started" >> $TmpLog
	echo "Cannot start next step without -P flag" >> $TmpLog
fi

funcWriteEndLog
