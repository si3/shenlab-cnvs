#!/bin/bash

# This script takes the mean RD output from mosdepth_to_XHMM reformatter script
# Contains all steps of the XHMM workflow to call CNVs
# Does not invoke any other steps

# InpFil - (required) path to bam_list
# RefFil - (required) shell file containing resources for this batch
# LogFil - (optional) log to monitor progress
# TgtBed - (optional) capture kit used in this batch, redundant
# Help - get usage information

# Required directories:
# XHMM="/home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909"
# RES_DIR="/home/local/users/sai2116/cnv_calling"
# PROJECT_DIR="/home/local/users/sai2116/shenlab-cnvs"

usage="
	This script runs the final step in the XHMM workflow
	Calls CNVs in samples based on mean RD and interval file
	Output will go into XHMM_output

	Run_XHMM.sh

	-i (required) path to bam_list
	-r (required) path to shell ref file
	-l (optional) path to log
	-t (optional) path to target file, used when not in -r
	-H (flag) returns this message

	Usage: bash Run_XHMM -i InpFil -r RefFil -l LogFil

"

while getopts i:r:l:a:t:PH opt; do
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

WindFil=`readlink -f $WindFil`
LogFil=`readlink -f $LogFil`

BATCH=""

ProcessNam="calling CNVs using XHMM algorithm"
funcWriteStartLog

# For the next step, you need an extreme gc target file and a low complexity region file if you want to filter them out

StepNam="Creating matrix and filtering out extreme GC and low complexity targets"
StepCmd="xhmm --matrix
	-r $PROJECT_DIR/Cov_output/$1.RD.txt
	--centerData --centerType target
	-o $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt
	--outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt
	--outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt
	--excludeTargets $RES_DIR/extreme_gc_targets.txt
	--excludeTargets $RES_DIR/low_complexity_targets.txt
	--minTargetSize $minTargetSize
	--maxTargetSize $maxTargetSize
	--minMeanTargetRD $minMeanTargetRD
	--maxMeanTargetRD $maxMeanTargetRD
	--minMeanSampleRD $minMeanSampleRD
	--maxMeanSampleRD $maxMeanSampleRD
	--maxSdSampleRD $maxSdSampleRD"
funcRunStep

#xhmm --matrix -r $PROJECT_DIR/Cov_output/$1.RD.txt --centerData --centerType target -o $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt --outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt --excludeTargets $RES_DIR/extreme_gc_targets.txt --excludeTargets $RES_DIR/low_complexity_targets.txt --minTargetSize 10 --maxTargetSize 10000 --minMeanTargetRD 10 --maxMeanTargetRD 500 --minMeanSampleRD 25 --maxMeanSampleRD 200 --maxSdSampleRD 150


StepNam="Doing PCA of filtered and centered RD data"
StepCmd="xhmm --PCA
	-r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt
	--PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA"
funcRunStep

StepNam="Normalizing RD data based on PCA"
StepCmd="xhmm --normalize
	-r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt
	--PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA
	--normalizeOutput $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt
	--PCnormalizeMethod PVE_mean
	--PVE_mean_factor $PVEmean"
funcRunStep


#xhmm --PCA -r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA

#xhmm --normalize -r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA --normalizeOutput $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt --PCnormalizeMethod PVE_mean --PVE_mean_factor 0.7


# You can change the maximum SD allowed in targets

StepNam="Calculating z scores"
StepCmd="xhmm --matrix
	-r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt
	--centerData --centerType sample
	--zScoreData -o $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt
	-outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt
	--outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt
	--maxSdTargetRD $maxSdTargetRD"
funcRunStep

StepNam="Excluding samples/targets based on chosen parameters"
StepCmd="xhmm --matrix 
	-r $PROJECT_DIR/Cov_output/$1.RD.txt 
	--excludeTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt 
	--excludeTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt 
	--excludeSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt 
	--excludeSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt 
	-o $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt"
funcRunStep

# xhmm --matrix -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt --centerData --centerType sample --zScoreData -o $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt --outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt --maxSdTargetRD 30

# xhmm --matrix -r $PROJECT_DIR/Cov_output/$1.RD.txt --excludeTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt --excludeTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --excludeSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt --excludeSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt -o $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt

# Discover CNVs step, will output xcnv files and posterior probability files

StepNam="Discovering CNVs in batch $BATCH"
StepCmd="xhmm --discover 
	-p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt 
	-r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt 
	-R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt 
	--discoverSomeQualThresh $discoverSQ 
	-c $PROJECT_DIR/XHMM_output/$1.xcnv 
	-a $PROJECT_DIR/XHMM_output/$1.aux_xcnv 
	-s $BATCH"
funcRunStep

# xhmm --discover -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt -R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt --discoverSomeQualThresh 0 -c $PROJECT_DIR/XHMM_output/$1.xcnv -a $PROJECT_DIR/XHMM_output/$1.aux_xcnv -s $1

# Genotype all samples across the court

StepNam="Genotyping CNVs in batch $BATCH"
StepCmd="xhmm --genotype 
	-p $XHMM/params.txt 
	-r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt 
	-R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt 
	-g $PROJECT_DIR/XHMM_output/$1.xcnv 
	-F $RES_DIR/hg19.fasta 
	-v $PROJECT_DIR/XHMM_output/$1.vcf"
funcRunStep

# xhmm --genotype -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt -R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt -g $PROJECT_DIR/XHMM_output/$1.xcnv -F $RES_DIR/hg19.fasta -v $PROJECT_DIR/XHMM_output/$1.vcf

funcWriteEndLog
