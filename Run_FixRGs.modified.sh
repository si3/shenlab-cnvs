#!/bin/bash

# Run this for individual bam files

#NUML=$1

#bamfiles="/home/local/users/sai2116/cnv_calling/RGN_WES_rare_FixRGs.list"
#bamfiles="../Regeneron/BRHIFixRGbams.txt"
#bamfiles="../Regeneron/BRAJFixRGsecondrun.txt"
#bamfiles="../RGN3/RGN3FixRGlists.txt"

InputBam="/home/local/users/sai2116/RGN_BigData_bams/COL-CHUNG_FBC_220365_220365.merged.rehead.first.bam"
#InputBam=`awk 'NR=='$NUML' {print}' $bamfiles`

#get the bad readgroup from one of the read lines of the bam
BadRG=`samtools view -h $InputBam | head -n  200 | tail -n 1 | tr '\t' '\n' | grep -e "^RG" | sed s/RG:Z://`
#get the good readgroup from the readgroup header
GoodRG=`samtools view -H $InputBam | grep ^@RG | tr '\t' '\n' | grep -e "^ID" | sed s/ID://`

#Write to a new output file
subject=`basename $InputBam | sed s/.bam//`
OUT="/home/local/users/sai2116/RGN_BigData_bams"
#OUT=`dirname $InputBam`
OutBam=`echo $OUT/$subject'.second.bam'`
#OutBam=`echo $subject'.fixed.bam'`


# Temporary sam files
TmpSam=`basename $OutBam`
TmpSam=Temp.${TmpSam/bam/sam}
FxdSam=${TmpSam/sam/second.sam}

#echo $FxdSam > FixRGs.$1.log

#bam --[samtools]--> sam
samtools view -h $InputBam > $TmpSam
# sam --[sed - replace bad RG with good RG]--> sam 
#sed s/$BadRG/$GoodRG/g $TmpSam > $FxdSam
sed s/$BadRG/$GoodRG/g $TmpSam > $FxdSam
#remove temporary sam file
rm -f $TmpSam
# sam --[samtools]--> bam
samtools view -bS $FxdSam > $OutBam
#samtools view -b $FxdSam > $OutBam
# remove temporary file
rm -f $FxdSam

### index new bam files
#samtools index $OutBam
