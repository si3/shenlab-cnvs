#!/bin/bash

# This script takes a list of bam files and estimates RD in intervals defined by a windows.bed file
# Script needs to be in COV_DIR (same intended directory as RD output)

# InpFil - (required) path to bam file or bam list
# RefFil - (required) shell file containing resources for this batch run
# ArrNum - (optional) line argument of input file to process, defaults to 1
# LogFil - (optional) log to monitor progress
# TgtBed - (optional) capture kit used in this batch, may be redundant
# Pipeline - continues pipeline by invoking bedtools RD_calculator
# Help - get usage information

# List of variables used in this script

# PROJ_DIR
# RES_DIR
# COV_DIR
# SAMPLE_INFO_DIR
# Min_MQ

# List of tools used in this script:
# mosdepth <https://github.com/brentp/mosdepth>
# bedtools <http://bedtools.readthedocs.io/en/latest/>
# GNU parallel <https://www.gnu.org/software/parallel/>

usage="
	this script is optimized for estimating RD in CNV exome pipeline
	using mosdepth to get mean RD in intervals, needs a ref file per batch run
	parallelizes jobs with GNU parallel
	
	Run_RD_calculator.sh

        -i (required) path/to/bam_list
        -r (required) path/to/cnv.exome.references.sh
	-l (optional) path/to/log
	-a (optional) set to {} for parallel jobs
        -t (optional) path/to/targets.bed (unless specified in -r)
        -P (flag) initiates pipeline
        -H (flag) echo this message

        Usage: seq 1 n | parallel -j m --eta --joblog tmp/log sh path/to/script.sh -i path/to/bam -a {} -P
	
	(where n is the total number of samples, and m is the number of jobs to run in parallel)
"

Pipeline="false"
ArrNum=1

while getopts i:r:l:a:t:PH opt; do
	case "$opt" in
		i) InpFil="$OPTARG";;
		r) RefFil="$OPTARG";;
		l) LogFil="$OPTARG";;
		a) ArrNum="$OPTARG";;
		t) TgtBed="$OPTARG";;
		P) Pipeline="true";;
		H) echo "$usage"; exit;;
	esac
done

# Check for required arguments

if [[ ! -e "$InpFil" ]] || [[ ! -e "$RefFil" ]]; then echo "Missing/Incorrect required arguments"; echo "$usage"; exit; fi

# Call the RefFil to load variables
RefFil=`readlink -f $RefFil`
source $RefFil

# Set all variables
InpFil=`readlink -f $InpFil`
NoSamples=`wc -l $InpFil | cut -f1 -d" "`
BamFil=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 1)
BamNam=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 2)
WindFil=`readlink -f $WindFil`
LogFil=`readlink -f $LogFil`
LogNam=`basename $LogFil`

TmpLog="RD_calculator_"$LogNam

# Load function library
source $PROJ_DIR/cnv.exome.lib.sh

ProcessName="calculating RD in intervals"

if [[ $ArrNum == 1 ]]; then
	funcWriteStartLog
	echo "Considering reads with minimum MQ="$Min_MQ >> $TmpLog
fi

# Check if BAM or CRAM

#StepNam="Running dummy test"
#StepCmd="echo $BamNam >> $PROJ_DIR/dummy.test"

StepNam="Running mosdepth for "$BamNam
StepCmd="mosdepth --by $WindFil $BamNam $BamFil -Q $Min_MQ -f $REF"
funcRunStep

#StepNam="Running bedtools for "$BamNam
#StepCmd="bedtools multicov -bams $BamFil -bed $WindFil -q $Min_MQ | awk '{print $1, $2, $3, $NF, $NF/($3-$2)}' > $COV_DIR/$BamNam.coverage.bed"
#funcRunStep

if [[ $ArrNum == $NoSamples ]]; then # Checks end job, does housekeeping
	echo "Parallel is done" >> $TmpLog
	mkdir $COV_DIR/mosdepth
	#mkdir bedtools
	mv *.regions.bed.gz $COV_DIR/mosdepth
	mv *.regions.bed.gz.csi $COV_DIR/mosdepth
	mv *.per-base.bed.gz $COV_DIR/mosdepth
	mv *.per-base.bed.gz.csi $COV_DIR/mosdepth
	mv *.mosdepth.global.dist.txt $COV_DIR/mosdepth
	mv *.mosdepth.region.dist.txt $COV_DIR/mosdepth
	mv $COV_DIR/Run_CLAMMS_model_fitter.sh $COV_DIR/mosdepth
	#mv *.coverage.bed ./bedtools 
	echo "Directory mosdepth created in "$COV_DIR >> $TmpLog
	if [[ $Pipeline == "true" ]]; then  
		NextJob="bedtools RD calculator script"
		NextCmd="seq 1 $NoSamples | parallel -j $NoJobs --eta --joblog RD_calculator_parallel_2.$$.log sh Run_RD_calculator_2.sh -i $InpFil -r $RefFil -l $LogFil -a {}"
		#NextCmd="bash Run_RD_reformatters.sh -i $InpFil -r $RefFil -l $LogFil -P"
		funcPipeBatch #checks if P is flagged automatically and writes to LogFil
	fi
	funcWriteEndLog
else
	echo "Parallel was working on sample number "$ArrNum >> $TmpLog
fi

#Housekeeping

#echo "Moving coverage files to new directories" >> $TmpLog

#mkdir mosdepth
#mkdir bedtools

#mv *.regions.bed.gz ./mosdepth
#mv *.regions.bed.gz.csi ./mosdepth
#mv *.per-base.bed.gz ./mosdepth
#mv *.per-base.bed.gz.csi ./mosdepth
#mv *.mosdepth.global.dist.txt ./mosdepth

#mv *.coverage.bed ./bedtools

# Start next step of pipeline

#NextJob="reformatting Mosdepth RD data"
#NextCmd="Run_MosDepth_reformatter"

#funcPipeline

#funcWriteEndLog

