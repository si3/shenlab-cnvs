#!/bin/bash
# Split up the BAM files into two or more files, then for each run GATK
# the following script accepts two variables, $1 is the data-set identifier and $2 is the name of the list of DoC files

date > $1.start.log

xhmm --mergeGATKdepths -o $1.RD.txt --GATKdepthsList $1.DOC.list #list of DoC files

# For the next step, you need an extreme gc target file and a low complexity region file if you want to filter them out

xhmm --matrix -r $1.RD.txt --centerData --centerType target -o $1.filtered_centered.RD.txt --outputExcludedTargets $1.filtered_centered.RD.txt.filtered_targets.txt --outputExcludedSamples $1.filtered_centered.RD.txt.filtered_samples.txt --excludeTargets extreme_gc_targets.txt --excludeTargets low_complexity_targets.txt --minTargetSize 10 --maxTargetSize 10000 --minMeanTargetRD 10 --maxMeanTargetRD 500 --minMeanSampleRD 25 --maxMeanSampleRD 200 --maxSdSampleRD 150

xhmm --PCA -r $1.filtered_centered.RD.txt --PCAfiles $1.RD_PCA

xhmm --normalize -r $1.filtered_centered.RD.txt --PCAfiles $1.RD_PCA --normalizeOutput $1.PCA_normalized.txt --PCnormalizeMethod PVE_mean --PVE_mean_factor 0.7

# You can change the maximum SD allowed in targets

xhmm --matrix -r $1.PCA_normalized.txt --centerData --centerType sample --zScoreData -o $1.PCA_normalized.filtered.sample_zscores.RD.txt --outputExcludedTargets $1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --outputExcludedSamples $1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt --maxSdTargetRD 30

xhmm --matrix -r $1.RD.txt --excludeTargets $1.filtered_centered.RD.txt.filtered_targets.txt --excludeTargets $1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_targets.txt --excludeSamples $1.filtered_centered.RD.txt.filtered_samples.txt --excludeSamples $1.PCA_normalized.filtered.sample_zscores.RD.txt.filtered_samples.txt -o $1.same_filtered.RD.txt

# Discover CNVs step, will output xcnv files and posterior probability files

xhmm --discover -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $1.PCA_normalized.filtered.sample_zscores.RD.txt -R $1.same_filtered.RD.txt --discoverSomeQualThresh 0 -c $1.xcnv -a $1.aux_xcnv -s $1

# Genotype all samples across the court

xhmm --genotype -p /home/local/users/sai2116/bin/statgen-xhmm-cc14e528d909/params.txt -r $1.PCA_normalized.filtered.sample_zscores.RD.txt -R $1.same_filtered.RD.txt -g $1.xcnv -F /home/local/ARCS/hq2130/Exome_Seq/resources/hg19.fasta -v $1.vcf

date > $1.end.log
