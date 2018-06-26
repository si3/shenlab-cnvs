#!/bin/bash

# Script to fit models to pre-determined K-nn reference samples
# Takes in $1 variable for batch (bam_list file) and $2 variable for windows.bed file
# First run Normalizer script for all batches, then run this script
# Script has to be in the same folder as coverage files (COV_DIR) for ref.panel files to work during model fitting
# Directories
SAMPLE_INFO_DIR="/home/local/users/sai2116/CDH_CNVs/CDH_sample_info"
WINDOWS_DIR="/home/local/users/sai2116/cnv_calling"
COV_DIR="/home/local/users/sai2116/CDH_CNVs/Cov_output_4"
CLAMMS_DIR="/home/local/users/sai2116/bin/clamms"
CLAMMS_OUTPUT_DIR="/home/local/users/sai2116/CDH_CNVs/CLAMMS_output"

#cat $SAMPLE_INFO_DIR/$1.bam_list.txt | cut -f2 | while read SAMPLE; do
#       FILE=`echo "$SAMPLE".norm.cov.bed`
#       echo -e -n "$SAMPLE\t$FILE\t"
#       grep "^Y" $COV_DIR/$SAMPLE.norm.cov.bed | awk '{ x += $4; n++; } END { if (x/n >= 0.1) print "M"; else print "F"; }'
#done > $CLAMMS_OUTPUT_DIR/$1.samples.sex.txt

#sort $CLAMMS_OUTPUT_DIR/$1.samples.sex.txt > $CLAMMS_OUTPUT_DIR/$1.samples.sex.sorted.txt

cat $SAMPLE_INFO_DIR/$1.bam_list.txt | cut -f2 | while read SAMPLE; do
        SEX=`echo "$SAMPLE" | join - $CLAMMS_OUTPUT_DIR/$1.samples.sex.sorted.txt | tr ' ' '\t' | cut -f 3`
        #cat $CLAMMS_OUTPUT_DIR/CLAMMS_knn/$SAMPLE.50nns.txt.sorted | awk '{ print "$COV_DIR" $0;}' > $CLAMMS_OUTPUT_DIR/CLAMMS_knn/$SAMPLE.50nns.txt.sorted.path
        join $CLAMMS_OUTPUT_DIR/CLAMMS_knn/$SAMPLE.50nns.txt.sorted $CLAMMS_OUTPUT_DIR/$1.samples.sex.sorted.txt | tr ' ' '\t' | cut -f 2- > $COV_DIR/$SAMPLE.ref.panel.txt
        $CLAMMS_DIR/fit_models $COV_DIR/$SAMPLE.ref.panel.txt $WINDOWS_DIR/$2.windows.bed > $CLAMMS_OUTPUT_DIR/CLAMMS_models/$SAMPLE.models.bed
        #$CLAMMS_DIR/call_cnv $COV_DIR/$SAMPLE.norm.cov.bed $CLAMMS_OUTPUT_DIR/$SAMPLE.models.bed --sex $SEX > $CLAMMS_OUTPUT_DIR/CLAMMS_calls/$SAMPLE.cnv.bed
done
