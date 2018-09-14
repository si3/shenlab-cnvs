#!/bin/bash

# This script takes the mean RD output from mosdepth_to_XHMM reformatter script
# Contains all steps of the XHMM workflow to call CNVs
# Does not invoke any other steps, should be in XHMM_OUT

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
	This script runs all steps of the XHMM workflow
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
# if [[ ! -e "$InpFil" ]] || [[ ! -e "$RefFil" ]]; then echo "Missing/incorrect required arguments"; echo "$usage"; exit; fi

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
        LogFil=StartXHMMexomeCNV.$$.log
else
        LogFil=`readlink -f $LogFil`
fi

LogNam=`basename $LogFil`
TmpLog="XHMM_caller_"$LogNam


ProcessName="CNV calling using XHMM algorithm on $NoSamples samples"
funcWriteStartLog

# For the next step, you need an extreme gc target file and a low complexity region file if you want to filter them out

echo "Creating matrix and filtering out extreme GC and low complexity targets" >> $TmpLog
xhmm --matrix -r $COV_DIR/$BATCH.xhmm.mean.RD.txt --centerData --centerType target -o $XHMM_OUT/$BATCH.filtered_centered.RD.txt --outputExcludedTargets $XHMM_OUT/$BATCH.filtered_centered.RD.txt.filtered_targets.txt --outputExcludedSamples $XHMM_OUT/$BATCH.filtered_centered.RD.txt.filtered_samples.txt --excludeTargets $extremeGC --excludeTargets $lowcomp --minTargetSize $minTargetSize --maxTargetSize $maxTargetSize --minMeanTargetRD $minMeanTargetRD --maxMeanTargetRD $maxMeanTargetRD --minMeanSampleRD $minMeanSampleRD --maxMeanSampleRD $maxMeanSampleRD --maxSdSampleRD $maxSdSampleRD

#xhmm --matrix -r $PROJECT_DIR/Cov_output/$1.RD.txt --centerData --centerType target -o $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt --outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt --excludeTargets $RES_DIR/extreme_gc_targets.txt --excludeTargets $RES_DIR/low_complexity_targets.txt --minTargetSize 10 --maxTargetSize 10000 --minMeanTargetRD 10 --maxMeanTargetRD 500 --minMeanSampleRD 25 --maxMeanSampleRD 200 --maxSdSampleRD 150


echo "Doing PCA of filtered and centered RD data" >> $TmpLog
xhmm --PCA -r $XHMM_OUT/$BATCH.filtered_centered.RD.txt --PCAfiles $XHMM_OUT/$BATCH.RD_PCA

echo "Normalizing RD data based on PCA" >> $TmpLog
xhmm --normalize -r $XHMM_OUT/$BATCH.filtered_centered.RD.txt --PCAfiles $XHMM_OUT/$BATCH.RD_PCA --normalizeOutput $XHMM_OUT/$BATCH.PCA_normalized.txt --PCnormalizeMethod PVE_mean --PVE_mean_factor $PVEmean

#xhmm --PCA -r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA
#xhmm --normalize -r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA --normalizeOutput $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt --PCnormalizeMethod PVE_mean --PVE_mean_factor 0.7


# You can change the maximum SD allowed in targets

echo "Calculating z scores" >> $TmpLog
xhmm --matrix -r $XHMM_OUT/$BATCH.PCA_normalized.txt --centerData --centerType sample --zScoreData -o $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt -outputExcludedTargets $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --outputExcludedSamples $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt --maxSdTargetRD $maxSdTargetRD

echo "Excluding samples/targets based on chosen parameters" >> $TmpLog
xhmm --matrix -r $COV_DIR/$BATCH.xhmm.mean.RD.txt --excludeTargets $XHMM_OUT/$BATCH.filtered_centered.RD.txt.filtered_targets.txt --excludeTargets $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --excludeSamples $XHMM_OUT/$BATCH.filtered_centered.RD.txt.filtered_samples.txt --excludeSamples $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt -o $XHMM_OUT/$BATCH.same_filtered.RD.txt

# xhmm --matrix -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt --centerData --centerType sample --zScoreData -o $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt --outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt --maxSdTargetRD 30

# xhmm --matrix -r $PROJECT_DIR/Cov_output/$1.RD.txt --excludeTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt --excludeTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --excludeSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt --excludeSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt -o $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt

# Discover CNVs step, will output xcnv files and posterior probability files

echo "Discovering CNVs in $NoSamples samples" >> $TmpLog
xhmm --discover -p $XHMM/params.txt -r $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt -R $XHMM_OUT/$BATCH.same_filtered.RD.txt --discoverSomeQualThresh $discoverSQ -c $XHMM_OUT/$BATCH.xcnv -a $XHMM_OUT/$BATCH.aux_xcnv -s $BATCH

# xhmm --discover -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt -R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt --discoverSomeQualThresh 0 -c $PROJECT_DIR/XHMM_output/$1.xcnv -a $PROJECT_DIR/XHMM_output/$1.aux_xcnv -s $1

# Genotype all samples across the court

echo "Genotyping CNVs in $NoSamples samples" >> $TmpLog
xhmm --genotype -p $XHMM/params.txt -r $XHMM_OUT/$BATCH.PCA_normalized.filtered.sample_zscores.RD.txt -R $XHMM_OUT/$BATCH.same_filtered.RD.txt -g $XHMM_OUT/$BATCH.xcnv -F $RES_DIR/hg19.fasta -v $XHMM_OUT/$BATCH.vcf

# xhmm --genotype -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt -R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt -g $PROJECT_DIR/XHMM_output/$1.xcnv -F $RES_DIR/hg19.fasta -v $PROJECT_DIR/XHMM_output/$1.vcf

echo "$BATCH.vcf created in $XHMM_OUT" >> $TmpLog
funcWriteEndLog
mailx -s "XHMM pipeline run completed" $USER < $LogFil
