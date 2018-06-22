#!/bin/bash

# this script will format target BED file (targets.bed) according to CLAMMS reqs
# Large intervals (e.g. > 1000bp) will be broken down into ~500bp windows
# Information about 
#	- mappability from UCSC wig file with appropriate read length (mappability.bed)
# 	- reference fasta (genome.fa)
#	- CLAMMS special regions (clamms_special_regions.bed)
#	- insert size
# Will also be included as metadata. Sort all bed files with bedtools sort or sort -k1,1 -k2,2n
# chmod +x any CLAMMS scripts
# Run this for each capture kit separately

CLAMMS_DIR="/home/local/users/sai2116/bin/clamms" # where CLAMMS was installed
RES_DIR="/home/sai2116/" # where fasta files etc are
INSERT_SIZE=250 # average insert size for batch


#genome.fa
#targets.bed
#mappability.be


INSERT_SIZE=250
$CLAMMS_DIR/annotate_windows.sh $RES_DIR/$1.targets.bed $RES_DIR/hg19.fasta $RES_DIR/mappability.75mer.clamms.sorted.bed $INSERT_SIZE $CLAMMS_DIR/data/clamms_special_regions.grch38.bed > $RES_DIR/$1.250bp.windows.bed

# $CLAMMS_DIR/annotate_windows.sh $1.sorted.targets.bed hg19.clamms.fasta mappability.75mer.clamms.sorted.bed $INSERT_SIZE $CLAMMS_DIR/data/clamms_special_regions.grch38.bed > $1.windows.bed



#/home/local/ARCS/hq2130/Exome_Seq/resources/CaptureKitBeds/SeqCap_EZ_Exome_v2.hg19.targets.bed #UW with human_g1k_v37_decoy
#/home/local/ARCS/hq2130/Exome_Seq/resources/CaptureKitBeds/SureSelect_All_Exon_V2_b37.ordered.bed #DHREAM with and without decoy sequences
#/home/local/ARCS/hq2130/Exome_Seq/resources/CaptureKitBeds/SureSelect_All_Exon_V4_b37.ordered.bed #DHREAM without decoy sequences

#while read line; do
        #FILENAME=`basename ${i%%.bam}`;        
        #FILENAME=`basename ${line%%.bam}`;
        #samtools bedcov -Q 20 $1 $line | awk -F $'\t' 'BEGIN {OFS = FS}{ print $1, $2, $3, $NF/($3-$2);}' > /home/local/users/sai2116/CDH_CNVs/Cov_output_2/$FILENAME.coverage.bed
#done
