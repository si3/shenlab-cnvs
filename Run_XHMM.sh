#!/bin/bash
# Split up the BAM files into two or more files, then for each run GATK
# the following script accepts two variables, $1 is the data-set identifier and $2 is the name of the list of DoC files

# Directories:
XHMM_DIR="/home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909"
RES_DIR="/home/local/users/sai2116/cnv_calling"
PROJECT_DIR="/home/local/users/sai2116/shenlab-cnvs"

date > $1.start.log

# xhmm --mergeGATKdepths -o $1.RD.txt --GATKdepthsList $1.DOC.list #list of DoC files

# For the next step, you need an extreme gc target file and a low complexity region file if you want to filter them out

xhmm --matrix -r $PROJECT_DIR/Cov_output/$1.RD.txt --centerData --centerType target -o $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt --outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt --excludeTargets $RES_DIR/extreme_gc_targets.txt --excludeTargets $RES_DIR/low_complexity_targets.txt --minTargetSize 10 --maxTargetSize 10000 --minMeanTargetRD 10 --maxMeanTargetRD 500 --minMeanSampleRD 25 --maxMeanSampleRD 200 --maxSdSampleRD 150

xhmm --PCA -r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA

xhmm --normalize -r $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt --PCAfiles $PROJECT_DIR/XHMM_output/$1.RD_PCA --normalizeOutput $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt --PCnormalizeMethod PVE_mean --PVE_mean_factor 0.7

# You can change the maximum SD allowed in targets

xhmm --matrix -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.txt --centerData --centerType sample --zScoreData -o $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt --outputExcludedTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --outputExcludedSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt --maxSdTargetRD 30

xhmm --matrix -r $PROJECT_DIR/Cov_output/$1.RD.txt --excludeTargets $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_targets.txt --excludeTargets $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --excludeSamples $PROJECT_DIR/XHMM_output/$1.filtered_centered.RD.txt.filtered_samples.txt --excludeSamples $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt -o $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt

# Discover CNVs step, will output xcnv files and posterior probability files

xhmm --discover -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt -R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt --discoverSomeQualThresh 0 -c $PROJECT_DIR/XHMM_output/$1.xcnv -a $PROJECT_DIR/XHMM_output/$1.aux_xcnv -s $1

# Genotype all samples across the court

xhmm --genotype -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $PROJECT_DIR/XHMM_output/$1.PCA_normalized.filtered.sample_zscores.RD.txt -R $PROJECT_DIR/XHMM_output/$1.same_filtered.RD.txt -g $PROJECT_DIR/XHMM_output/$1.xcnv -F $RES_DIR/hg19.fasta -v $PROJECT_DIR/XHMM_output/$1.vcf

date > $1.end.log
