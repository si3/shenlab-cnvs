#!/bin/bash

# This script takes a list of coverage files from mosdepth output
# Then runs normalize_coverage from CLAMMS using GNU parallel
# Outputs <BamNam>.norm.cov.bed for each sample
# DOES NOT NEED to be in COV_DIR (same directory as mosdepth RD output)

# InpFil - (required) path to bam file or bam list
# RefFil - (required) shell file containing resources for this batch run
# ArrNum - (optional) line argument of input file to process, defaults to 1
# LogFil - (optional) log to monitor progress
# TgtBed - (optional) capture kit used in this batch, may be redundant
# Pipeline - continues pipeline in the CLAMMS workflow, default is false
# Help - get usage information

# List of variables used in script

# PROJ_DIR
# COV_DIR
# SAMPLE_INFO_DIR
# CLAMMS_DIR
# WindFil

# List of tools used in this script:
# CLAMMS <https://github.com/rgcgithub/clamms>
# bedtools <http://bedtools.readthedocs.io/en/latest/>
# GNU parallel <https://www.gnu.org/software/parallel/>

usage="
	this script is optimized for normalizing RD in CNV exome pipeline
        takes in mosdepth output as part of the CLAMMS workflow
        parallelizes jobs with GNU parallel
        
        Run_CLAMMS_normalizer.sh

        -i (required) path/to/bam_list
        -r (required) path/to/cnv.exome.references.sh
        -l (optional) path/to/log
        -a (optional) set to {} for parallel jobs
        -t (optional) path/to/targets.bed (unless specified in -r)
        -P (flag) initiates pipeline, default is false
        -H (flag) echo this message

        Usage: seq 1 n | parallel -j m --eta --joblog tmp/log sh path/to/script.sh -i path/to/bam -a {}
        
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
                t) TgtBed="$OPTARG";; # support pending
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

if [[ -z "$LogFil" ]]; then
        LogFil=NormCLAMMSexomeCNV.$$.log
else
        LogFil=`readlink -f $LogFil`
fi

LogNam=`basename $LogFil`
TmpLog="CLAMMS_normalizer_"$LogNam

# Load script library
source $PROJ_DIR/cnv.exome.lib.sh

ProcessName="RD normalizer in intervals for CLAMMS"

if [[ $ArrNum == 1 ]]; then
        funcWriteStartLog
        #echo "Considering reads with minimum MQ="$Min_MQ >> $TmpLog
fi

echo "Generating and sorting coverage file for $BamNam" >> $TmpLog
gzip -dc $COV_DIR/mosdepth/$BamNam.regions.bed.gz | awk 'BEGIN{OFS="\t"};{print $1, $2, $3, $5}' | bedtools sort > $COV_DIR/mosdepth/$BamNam.coverage.bed

# Run CLAMMS normalizer script
# StepNam="Generating and sorting coverage file for $BamNam"
# StepCmd="gzip -dc $COV_DIR/mosdepth/$BamNam.regions.bed.gz | awk -F"\t" '{print $1, $2, $3, $5}' | bedtools sort > $COV_DIR/mosdepth/$BamNam.coverage.bed"
# funcRunStep

StepNam="Running normalize_coverage for $BamNam"
StepCmd="$CLAMMS/normalize_coverage $COV_DIR/mosdepth/$BamNam.coverage.bed $WindFil > $COV_DIR/mosdepth/$BamNam.norm.cov.bed"
funcRunStep
 

if [[ $ArrNum == $NoSamples ]]; then # Checks end job, does housekeeping
        echo "Parallel is done" >> $TmpLog
        if [[ $Pipeline == "true" ]]; then
                mv $COV_DIR/Run_CLAMMS_model_fitter.sh $COV_DIR/mosdepth
		NextJob="CLAMMS workflow by fitting models based on knn reference samples and discover CNVs"
		NextCmd="bash $COV_DIR/mosdepth/Run_CLAMMS_model_fitter.sh -i $InpFil -r $RefFil -l $LogFil"
		BatchNam="CLAMMSfit1"
		funcPipeBatch #checks if P is flagged automatically and writes to TmpLog
        fi
	funcWriteEndLog
	rm $COV_DIR/mosdepth/*.coverage.bed
else
	echo "Parallel was working on sample number "$ArrNum >> $TmpLog
fi


