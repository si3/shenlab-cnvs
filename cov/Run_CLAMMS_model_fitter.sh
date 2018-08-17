#!/bin/bash

# This script trains models on pre-determined K-nn reference panel
# Then fits them to normalized RD for each sample and calls CNVs
# Script has to be in COV_DIR (same as output from mosdepth) for ref.panel files to work
# 
# InpFil - (required) path to bam file or bam_list
# RefFil - (required) path to shell file containing resources for this batch run
# LogFil - (optional) log to monitor progress
# TgtBed - (optional) path to target bed, unless specified in RefFil

# Script has to be in the same folder as coverage files (COV_DIR) for ref.panel files to work during model fitting

# List of tools used in this script:
# CLAMMS <https://github.com/rgcgithub/clamms>

usage="
	This script runs the final step in the CLAMMS workflow
	Fits mixture models based on reference panels to normalized RD
	Then makes CNV calls in samples of interest
	Output will go into CLAMMS_out

	Run_CLAMMS_model_fitter.sh

	-i (required) path to bam_list
        -r (required) path to shell ref file
        -l (optional) path to log
        -t (optional) path to target file, used when not in -r
        -H (flag) returns this message

        Usage: bash Run_XHMM -i InpFil -r RefFil -l LogFil
"

while getopts i:r:l:H opt; do
        case "$opt" in
                i) InpFil="$OPTARG";;
                r) RefFil="$OPTARG";;
                l) LogFil="$OPTARG";;
                t) TgtBed="$OPTARG";; # support pending
                H) echo "$usage"; exit;;
        esac
done

# Checks for required input
if [[ ! -e "$InpFil" ]] || [[ ! -e "$RefFil" ]]; then echo "Missing/Incorrect required arguments"; echo "$usage"; exit; fi

# Call the RefFil to load variables
RefFil=`readlink -f $RefFil`
source $RefFil

# Set all variables
InpFil=`readlink -f $InpFil`
BATCH=`basename $InpFil | cut -f1 -d"."`

NoSamples=`wc -l $InpFil | cut -f1 -d" "`
WindFil=`readlink -f $WindFil`
LogFil=`readlink -f $LogFil`

TmpLog="RD_CLAMMS_fitter_"$LogFil

# Loading script library

source $PROJ_DIR/cnv.exome.lib.sh

ProcessName="Running CLAMMS fit_models and call_cnv on $NoSamples samples"
funcWriteStartLog

# Extract sex information

StepNam="Extracting sex information"
StepCmd="cut -f2 $InpFil | while read SAMPLE; do
       FILE=`echo "$SAMPLE".norm.cov.bed`
       echo -e -n "$SAMPLE\t$FILE\t"
       grep "^Y" $COV_DIR/mosdepth/$SAMPLE.norm.cov.bed | awk '{ x += $4; n++; } END { if (x/n >= 0.1) print "M"; else print "F"; }'
done > $CLAMMS_OUT/$BATCH.samples.sex.txt"
funcRunStep

# Housekeeping

sort $CLAMMS_OUT/$BATCH.samples.sex.txt > $CLAMMS_OUT/$BATCH.samples.sex.sorted.txt
rm $CLAMMS_OUT/$BATCH.samples.sex.txt
mkdir $CLAMMS_OUT/models
mkdir $CLAMMS_OUT/calls

# Fit models, call CNVs using CLAMMS

StepNam="Running fit_models and call_cnv"
StepCmd="cut -f2 $InpFil | while read SAMPLE; do
	SEX=`echo "$SAMPLE" | join - $CLAMMS_OUT/$BATCH.samples.sex.sorted.txt | tr ' ' '\t' | cut -f 3`
	join $CLAMMS_OUT/knn/$SAMPLE.50nns.txt.sorted $CLAMMS_OUT/$BATCH.samples.sex.sorted.txt | tr ' ' '\t' | cut -f 2- > $COV_DIR/mosdepth/$SAMPLE.ref.panel.txt 
	$CLAMMS_DIR/fit_models $COV_DIR/mosdepth/$SAMPLE.ref.panel.txt $2 > $CLAMMS_OUT/models/$SAMPLE.models.bed
	$CLAMMS_DIR/call_cnv $COV_DIR/mosdepth/$SAMPLE.norm.cov.bed $CLAMMS_OUT/models/$SAMPLE.models.bed --sex $SEX > $CLAMMS_OUT/calls/$SAMPLE.cnv.bed
done"
funcRunStep

echo "All CNV calls from CLAMMS were stored in $CLAMMS_OUT/calls" >> $TmpLog
funcWriteEndLog

