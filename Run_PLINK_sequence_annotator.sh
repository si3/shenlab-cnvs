#!/bin/bash

# Script to convert capture kit *.bed to *.targets.reg file, then find locus complexity and GC content
# Run the above first then vi and remove trailing whitespace from header
#echo -e "#CHR\tBP1\tBP2\tID" "\n$(cat /home/local/users/sai2116/cnv_calling/$1.targets.bed)" | awk -F "\t" '{if(NR==1){print $0} else {print "chr"$0, $NF="target_"NR-1}}' OFS="\t" > $1.targets.reg

#cat $1.targets.reg | head -n1 | awk '{$4=$4; print}' # remove trailing whitespace?

pseq . loc-load --locdb $1.targets.LOCDB --file $1.targets.reg --group targets --out $1.LOCDB.loc-load.log

pseq . loc-stats --locdb $1.targets.LOCDB --group targets --seqdb /home/local/users/sai2116/bin/plinkseq-0.10/hg19/seqdb.hg19 | awk '{if (NR > 1) print $_}' | sort -k1 -g | awk '{print $10}' | paste /home/local/users/sai2116/cnv_calling/$1.targets.bed - | awk '{print $1"\t"$2"\t"$3"\t"$4}' > $1.locus_complexity.txt

cat $1.locus_complexity.txt | awk '{if ($4 > 0.25) print $0}' | awk '{split ($0,a); print (a[1]":"a[2]"-"a[3])}' > $1.low_complexity_targets.txt

# Run the following to get extreme GC from *windows.bed file

#cat $1.windows.bed | awk '{if ($6 < 0.1 || $6 > 0.9) print $4}' > $1.extreme_gc_targets.txt

pseq . loc-stats --locdb $1.LOCDB --group targets --seqdb /home/local/users/sai2116/bin/plinkseq-0.10/hg19/seqdb.hg19 | awk '{if (NR > 1) print $_}' | awk '{if ($8 <0.1 || $8 > 0.9) print $4}' | sed 's/chr//' | sed 's/\../-/' > $1.extreme_gc_targets.txt

# 1bp adjustement to prevent book ended intervals

cat $1.low_complexity_targets.txt | awk '{split($0,1,"-"); print a[1]"-"a[2]-1}' > $1.xhmm.low_complexity_targets.txt
