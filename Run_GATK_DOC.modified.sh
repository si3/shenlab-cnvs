#!/bin/bash

#make sure PCR duplicates are marked in bams
#set default arguments

usage="
 (this script is optimized to get DoC in exome intervals for CNV calling with XHMM) 
 
 Run_GATK_DOC.sh 

 -i (required) <path to bam file or list file> 
 -a (required) <set to {} for parallel jobs>  
 -H (flag) <echo this message and exit>

 to execute with GNU Parallel run this line:

 seq 1 n | parallel -j m --eta sh path/to/Run_GATK_DOC.sh -i path/to/bam -a {}

 where n is the number of bams and j is the number of jobs to execute in parallel."

#get arguments
while getopts i:a:H opt; do
    case "$opt" in
        i) InpFil="$OPTARG";;
        a) ArrNum="$OPTARG";;
        H) echo "$usage"; exit;;
    esac
done
#set variables
InpFil=`readlink -f $InpFil` #resolve absolute path to bam

BamFil=$(tail -n+$ArrNum $InpFil | head -n 1)

BamNam=`basename $BamFil | sed s/.bam//` #change based on bam file ending

StepCmd="java -Xmx10G -XX:ParallelGCThreads=2 -jar $GATK
 -T DepthOfCoverage
 -R /home/local/ARCS/hq2130/Exome_Seq/resources/hg19.fasta
 -I $BamFil
 -o /home/local/users/sai2116/cnv_calling/docfiles_RGN_WES_rare/RGN_WES_rare.$BamNam
 -L RGN_PCGC.bed
 -dt BY_SAMPLE
 -dcov 5000
 -l INFO
 --omitDepthOutputAtEachBase
 --omitLocusTable
 --minBaseQuality 0
 --minMappingQuality 20
 --start 1
 --stop 5000
 --nBins 200
 --includeRefNSites
 --countType COUNT_FRAGMENTS
 --allow_potentially_misencoded_quality_scores
 -log RGN_WES_rare.DoC.gatklog" #command to be run

eval $StepCmd
