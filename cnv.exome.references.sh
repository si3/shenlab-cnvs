# Directories of various resources used in scripts
# Path is per my home directory on biocluster
# Change accordingly to adapt to your preferences

PROJ_DIR="/home/sai2116/shenlab-cnvs"
SAMPLE_INFO_DIR="/home/sai2116/shenlab-cnvs/sample_info"
COV_DIR="/home/sai2116/shenlab-cnvs/cov"
RES_DIR="/home/sai2116/shenlab-cnvs/res"
CANOES_OUT="/home/sai2116/shenlab-cnvs/CANOES_output"
CLAMMS_OUT="/home/sai2116/shenlab-cnvs/CLAMMS_output"
XHMM_OUT="/home/sai2116/shenlab-cnvs/XHMM_output"

# Jar files and directories for software
# Other required software, make sure it's in PATH:
# mosdepth, bedtools, GNU parallel 

PICARD="/share/apps/jar/picard.jar"
CLAMMS="/home/sai2116/bin/clamms"
XHMM="/home/sai2116/bin/statgen-xhmm-cc14e528d909"

# Reference files

REF="/share/data/resources/hg19/references/hg19.fasta"
PedFil="/home/sai2116/shenlab-cnvs/sample_info/WES_DHREAM.SureSelectV4.ped.txt"

Min_MQ=20 # minimum mapping quality for Run_coverage_calculator.sh
NoJobs=10 # number of parallel jobs to perform 

# Capture kit files

SCv2="/share/data/resources/hg19/CaptureKitBeds/SeqCap_EZ_Exome_v2.hg19.targets.bed"
SSv2="/share/data/resources/hg19/CaptureKitBeds/SureSelect_All_Exon_V2_b37.ordered.bed"
SSv4="/share/data/resources/hg19/CaptureKitBeds/SureSelect_All_Exon_V4_b37.ordered.bed"
UnionCDH="/share/data/resources/hg19/CaptureKitBeds/custom_intervals/CDH_intervals_union.bed"
InterCDH="/share/data/resources/hg19/CaptureKitBeds/custom_intervals/CDH_intervals_intersection.bed"

SCv2win="/home/sai2116/shenlab-cnvs/res/SeqCap_EZ_Exome_v2.hg19.windows.bed"
SSv2win="/home/sai2116/shenlab-cnvs/res/SureSelect_All_Exon_V2_b37.windows.bed"
SSv4win="/home/sai2116/shenlab-cnvs/res/SureSelect_All_Exon_V4_b37.windows.bed"

WindFil=$SSv4win

# CLAMMS specific reference files
minGC=""
maxGC=""

INSERT_SIZE=250
SPEC_REG="$RES_DIR/clamms_special_regions.hg19.excluded_contigs.bed"
MAP_REG="$RES_DIR/mappability.75mer.clamms.bed"

# XHMM specific reference files
minTargetSize=10
maxTargetSize=10000
minMeanTargetRD=10
maxMeanTargetRD=500
minMeanSampleRD=25
maxMeanSampleRD=200
maxSdSampleRD=150
PVEmean="0.7"
maxSdTargetRD=30 # max SD allowed in targets
discoverSQ=0 # Q_SOME cutoff for CNV discover, set to 0 for all CNVs

extremeGC="$RES_DIR/SureSelect_All_Exon_V4_b37.extreme_gc_targets.txt"
lowcomp="$RES_DIR/SureSelect_All_Exon_V4_b37.low_complexity_targets.txt"

# CANOES specific reference files
