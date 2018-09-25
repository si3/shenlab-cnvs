#!/bin/bash

# This script generates K-nearest neighbours using Run_FNN.R script
# This script when run on a given target files creates windows for CNV calling
# This script also outputs extreme GC and low mappability regions given a target file
# Needs the following information from reference shell script specific to batch of interest

# QC BAM STATS FILE (from Picard)
# TARGET FILE (can also be given with -t option)
# FASTA REFERENCE
# MAPPABILITY BED (for appropriate read length)
# SPECIAL REGIONS BED (from CLAMMS)
# INSERT SIZE
# SEQDB (from PLINK)
# MAX and MIN GC
# COMPLEXITY THRESHOLD

# WIll out put the following:

# WINDOWS BED
# TARGET REG
# LOW COMPLEXITY
# EXTREME GC
# k-NN REFERENCES (one file per sample)

# Requires PLINK/SEQ installed and in pathi

usage="
        this script prepares reference files for CNV calling with XHMM, CANOES, CLAMMS
        it requires an cnv.exome.references.sh containing correct path to each file
        and will generate K-nearest neighbours for input to CLAMMS 
        as well as a windows.bed file for given exon capture kit
        along with extreme GC and low complexity targets for input to XHMM

        Run_ref_prepper.sh

        -r (required) path/to/cnv.exome.references.sh
        -t (optional) path/to/targets.bed (unless specified in -r)
        -H (flag) echo this message

        Usage: bash Run_ref_prepper.sh -r path/to/RefFil -t path/to/TgtFil
        
        (make sure to run on compute node rather than head node on biocluster
        and update cnv.exome.references.sh with path to windows.bed afterwards)
"

while getopts r:t:H opt; do
        case "$opt" in
                r) RefFil="$OPTARG";;
                t) TgtFil="$OPTARG";;
                H) echo "$usage"; exit;;
        esac
done

# Import variables / read in reference file

RefFil=`readlink -f $RefFil`
source $RefFil

# Double check that TgtFil is loaded
TgtFil=`readlink -f $TgtFil`
TgtNam=`basename $TgtFil | cut -f1 -d "."`

# Find K nearest neighbours based on QC file 

Rscript $RES_DIR/Run_FNN.R $RES_DIR/knn/$BATCH.QC.bam_stats.txt &

# Create a windows file based on capture kit to calculate read counts

$CLAMMS/annotate_windows.sh $TgtFil $REF $MAP_REG $INSERT_SIZE $SPEC_REG > $RES_DIR/$TgtNam.windows.bed &

# Create locus complexity and gc content files

echo -e "#CHR\tBP1\tBP2\tID" "\n$(cat $TgtFil)" | awk -F "\t" '{if(NR==1){print $0} else {print "chr"$0, $NF="target_"NR-1}}' OFS="\t" | sed -e 's/[[:space:]]*$//' > $RES_DIR/$TgtNam.targets.reg

pseq . loc-load --locdb $RES_DIR/$TgtNam.targets.LOCDB --file $RES_DIR/$TgtNam.targets.reg --group targets --out $RES_DIR/$TgtNam.LOCDB.loc-load.log --noweb

pseq . loc-stats --locdb $RES_DIR/$TgtNam.targets.LOCDB --group targets --seqdb /home/sai2116/bin/plinkseq/hg19/seqdb.hg19 --noweb | awk '{if (NR > 1) print $_}' | sort -k1 -g | awk '{print $10}' | paste $TgtFil - | awk '{print $1"\t"$2"\t"$3"\t"$4}' > $RES_DIR/$TgtNam.locus_complexity.txt

cat $RES_DIR/$TgtNam.locus_complexity.txt | awk '{if ($4 > 0.25) print $0}' | awk '{split ($0,a); print (a[1]":"a[2]"-"a[3])}' > $RES_DIR/$TgtNam.low_complexity_targets.txt

pseq . loc-stats --locdb $RES_DIR/$TgtNam.targets.LOCDB --group targets --seqdb /home/sai2116/bin/plinkseq/hg19/seqdb.hg19 --noweb | awk '{if (NR > 1) print $_}' | awk '{if ($8 < $minGC || $8 > $maxGC) print $4}' | sed 's/chr//' | sed 's/\../-/' > $RES_DIR/$TgtNam.extreme_gc_targets.txt

# 1 bp adjustement for book ended intervals

#cat $1.low_complexity_targets.txt | awk '{split($0,1,"-"); print a[1]"-"a[2]-1}' > $1.xhmm.low_complexity_targets.txt


