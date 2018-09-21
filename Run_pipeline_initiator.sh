#!/bin/bash

# This script initializes the CNV calling pipeline from exomes in batches
# Make sure that the preparatory steps detailed in README were completed

# InpFil - (required) path to bam file or bam list
# RefFil - (required) shell file containing resources for this batch run
# LogFil - (optional) log to monitor progress
# TgtBed - (optional) capture kit used in this batch, may be redundant
# Pipeline - initiates pipeline
# Help - get usage information

# Resources needed for reference file
# <capture kit>.windows.bed

# Set default arguments

usage="
	this script initializes RD estimation for CNV exome pipeline
	takes bam list file as input (2 columns, bamfile path + sample ID)
	a windows file is required in ref file (follow prep steps)
	can also start pipeline for a batch of samples

	Run_pipeline_initiator.sh

	-i (required) path/to/bam_list
	-r (required) path/to/cnv.exome.references.sh
	-l (optional) path/to/log
	-t (optional) path/to/targets.bed (unless specified in -r)
	-P (flag) initiates pipeline
	-H (flag) echo this message

	Usage: bash Run_pipeline_initiator.sh -i path/to/bam -r path/to/ref -l path/to/log -P

"

# Get arguments

while getopts i:r:l:t:PH opt; do
	case "$opt" in
		i) InpFil="$OPTARG";;
		r) RefFil="$OPTARG";;
	#	a) ArrNum="$OPTARG";;
		l) LogFil="$OPTARG";;
		t) TgtBed="$OPTARG";;
		P) Pipeline="true";;
		H) echo "$usage"; exit;;
	esac
done

# Call the RefFil to load variables, set other variables
RefFil=`readlink -f $RefFil`
source $RefFil

# Load function library
source $PROJ_DIR/cnv.exome.lib.sh

#InpFil=`readlink -f $SAMPLE_INFO_DIR/$InpFil`
InpFil=`readlink -f $InpFil`
#BamFil=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 1)
#BamNam=$(tail -n+$ArrNum $InpFil | head -n 1 | cut -f 2)


# Create log file unless specified
if [[ -z "$LogFil" ]]; then
	LogFil=StartRDexomeCNV.$$.log
else
	LogFil=`readlink -f $LogFil`
fi

# Check input, number of samples to be run
NoSamples=`wc -l $InpFil | cut -f1 -d" "`
NoCol=`awk '{print NF}' $InpFil | head -n1`
NoJobs=$NoJobs

echo "Welcome to CNV calling pipeline from exomes - direct questions to Stefano Iantorno (sai2116@columbia.edu)" >> $LogFil
echo "Number of samples is "$NoSamples >> $LogFil
echo "Input list has "$NoCol" columns" >> $LogFil
echo "Coverage information will go in"$COV_DIR >> $LogFil

if [[ $NoCol == 2 ]]; then
	StepNam="Starting CNV pipeline for $InpFil with $NoJobs parallel jobs, using $RefFil as reference"
	StepCmd="seq 1 $NoSamples | parallel -j $NoJobs --eta --joblog RD_calculator_parallel.$$.log sh Run_RD_calculator.sh -i $InpFil -r $RefFil -l $LogFil -a {}"
	echo "Log file for mosdepth/GNU parallel is RD_calculator_parallel.$$.log" >> $LogFil
	echo "Log file for bedtools/GNU parallel is RD_calculator_parallel_2.$$.log" >> $LogFil
	echo "~~~~" >> $LogFil
	BatchNam="RDcalc1"
	funcRunBatch
	StepCmd="seq 1 $NoSamples | parallel -j $NoJobs --eta --joblog RD_calculator_parallel_2.$$.log sh Run_RD_calculator_2.sh -i $InpFil -r $RefFil -l $LogFil -a {}"
	BatchNam="RDcalc2"
	funcRunBatch
	if [[ $Pipeline == "true" ]]; then
		NextJob="mosdepth and bedtools reformatter scripts"
		NextCmd="bash $PROJ_DIR/Run_RD_reformatters.sh -i $InpFil -r $RefFil -l $LogFil -P"
		BatchNam="RDref1"
		funcPipeBatch RDcalc1,RDcalc2
		NextJob="CLAMMS workflow on $NoSamples samples"
		NextCmd="seq 1 $NoSamples | parallel -j $NoJobs --eta --joblog CLAMMS_normalizer_parallel.$$.log sh $COV_DIR/Run_CLAMMS_normalizer.sh -i $InpFil -r $RefFil -l $LogFil -a {}"
		#NextCmd="bash $CLAMMS_OUT/Run_CLAMMS.sh -i $InpFil -r $RefFil -l $LogFil"
		BatchNam="CLAMMSnorm1"
		funcPipeBatch RDref1
		NextJob="Fitting CLAMMS models and discovering CNVs"
		NextCmd="bash $COV_DIR/mosdepth/Run_CLAMMS_model_fitter.sh -i $InpFil -r $RefFil -l $LogFil"
		BatchNam="CLAMMSfit1"
		funcPipeBatch RDref1,CLAMMSnorm1
		NextJob="XHMM workflow on $NoSamples samples"
		NextCmd="bash $XHMM_OUT/Run_XHMM.sh -i $InpFil -r $RefFil -l $LogFil"
		BatchNam="XHMMcnv1"
		funcPipeBatch RDref1
	fi
else
	echo "Input has incorrect number of columns. Pipeline needs both bam files and sample IDs."
	exit 1
fi



