#!/bin/bash

# This script is run on individual target files to create windows for CNV calling
# Needs the following information from reference shell script specific to batch of interest

# INSERT SIZE
# FASTA REFERENCE
# MAPPABILITY BED
# SPECIAL REGIONS BED
# SEQDB (from PLINK)
# MAX and MIN GC
# COMPLEXITY THRESHOLD
# QC FILE (from PICARD)

# WIll out put the following:

# WINDOWS BED
# TARGET REG
# LOW COMPLEXITY
# EXTREME GC
# k-NN REFERENCES (one per sample)


usage="
        this script is optimized for estimating RD in CNV exome pipeline
        using both mosdepth and bedtools, needs a ref file per batch run
        parallelizes jobs with GNU parallel
        
        Run_ref_prepper.sh

        -i (required) path/to/bam_list
        -r (required) path/to/cnv.exome.references.sh
        -l (optional) path/to/log
        -t (optional) path/to/targets.bed (unless specified in -r)
        -H (flag) echo this message

        Usage: seq 1 n | parallel -j m --eta --joblog tmp/log sh path/to/script.sh -i path/to/bam -a {} -P
        
        (where n is the total number of samples, and m is the number of jobs to run in parallel)
"
while getopts i:r:l:a:t:PH opt; do
        case "$opt" in
                i) InpFil="$OPTARG";;
                r) RefFil="$OPTARG";;
                l) LogFil="$OPTARG";;
                a) ArrNum="$OPTARG";;
                t) TgtBed="$OPTARG";;
                H) echo "$usage"; exit;;
        esac
done

WIND=`basename $1 | cut -f1 -d"."`

RefFil=`readlink -f $2`
source $RefFil

StepCmd="$CLAMMS_DIR/annotate_windows.sh $TgtFil $REF $MAP_REG $INSERT_SIZE $SPEC_REG > $RES_DIR/$WIND.windows.bed"

#StepCmd="bash Run_CLAMMS_window_annotator.sh"

StepCmd="bash Run_PLINK_annotator.sh"

pseq . loc-load --locdb $1.targets.LOCDB --file $1.targets.reg --group targets --out $1.LOCDB.loc-load.log

pseq . loc-stats --locdb $1.targets.LOCDB --group targets --seqdb /home/local/users/sai2116/bin/plinkseq-0.10/hg19/seqdb.hg19 | awk '{if (NR > 1) print $_}' | sort -k1 -g | awk '{print $10}' | paste /home/local/users/sai2116/cnv_calling/$1.targets.bed - | awk '{print $1"\t"$2"\t"$3"\t"$4}' > $1.locus_complexity.txt

cat $1.locus_complexity.txt | awk '{if ($4 > 0.25) print $0}' | awk '{split ($0,a); print (a[1]":"a[2]"-"a[3])}' > $1.low_complexity_targets.txt

pseq . loc-stats --locdb $1.LOCDB --group targets --seqdb /home/local/users/sai2116/bin/plinkseq-0.10/hg19/seqdb.hg19 | awk '{if (NR > 1) print $_}' | awk '{if ($8 <0.1 || $8 > 0.9) print $4}' | sed 's/chr//' | sed 's/\../-/' > $1.extreme_gc_targets.txt

# 1 bp adjustement for bokk ended intervals

cat $1.low_complexity_targets.txt | awk '{split($0,1,"-"); print a[1]"-"a[2]-1}' > $1.xhmm.low_complexity_targets.txt

# Generate k-NN reference panels

StepCmd="Rscript Run_FNN.R"


