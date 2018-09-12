#Library of functions that will be used in CNV exome pipeline


# Function to set target file location when given a target file
funcGetTargetFile (){
    if [[ "$TGTCODES" == *"$TgtBed"* ]];then
        eval TgtBed=\$$TgtBed
    fi
}

# Function to get input file name from a list of files in an array job
funcFilfromList() {
ChecList=${InpFil##*.}
if [[ "$ChecList" == "list" ]];then
    echo $ChecList
    InpFil=$(head -n $ArrNum $InpFil | tail -n 1)
fi
}

# Function to enter information about script initiation into the log
funcWriteStartLog () {
uname -a >> $TmpLog
echo "Start "$ProcessName" - $0:`date`" >> $TmpLog
echo " Input File: "$InpFil >> $TmpLog
if [[ -n "$BamFil" ]]; then echo " Bam File: "$BamFil >> $TmpLog; fi
if [[ -n "$BamNam" ]]; then echo " Base name for outputs: $BamNam" >> $TmpLog; fi
#if [[ -n "$VcfFil" ]]; then echo " Vcf File: "$VcfFil >> $TmpLog; fi
#if [[ -n "$VcfNam" ]]; then echo " Base name for outputs: $VcfNam" >> $TmpLog; fi
if [[ -n "$TgtBed" ]]; then echo " Target Intervals File: "$TgtBed >> $TmpLog; fi
if [[ -n "$RefFil" ]]; then echo " Batch Reference File: "$RefFil >> $TmpLog; fi
echo "----------------------------------------------------------------" >> $TmpLog
}

# Function to log the start of each step
funcLogStepStart () { echo "- Start $StepNam `date`...">> $TmpLog ; } 

# Function to check that step has completed and print error message if not
funcLogStepFinit () { 
if [[ $? -ne 0 ]]; then #check exit status and if error then...
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $TmpLog
    echo "     $StepNam failed `date`" >> $TmpLog
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $TmpLog
    echo "=================================================================" >> $TmpLog
fi
echo "- End $StepNam `date`...">> $TmpLog # if no error log the completion of the step
echo "-----------------------------------------------------------------------" >> $TmpLog
}

# Function to run and log initiation of step
funcRunStep (){
funcLogStepStart
if [[ `type -t "$StepCmd"` ]]; then 
    type $StepCmd | tail -n +3  >> $TmpLog
else
    echo $StepCmd >> $TmpLog
fi
eval $StepCmd
funcLogStepFinit
}

# Function to run and log batch jobs, variable will be the name of the batch job
funcRunBatch () {
if [[ `type -t "$StepCmd"` ]]; then
        type $StepCmd | tail -n +3  >> $LogFil
else
	echo $StepCmd >> $LogFil
fi
echo "    "$StepNam  >> $LogFil
echo "Using qsub to submit as batch job with ID="$BatchNam >> $LogFil
echo "#!/bin/batch" > $BatchNam.$$.sh
echo $StepCmd >> $BatchNam.$$.sh
# checks for arguments, if present uses them as jobIDs that need completion
if [[ -n $1 ]]; then
	StepCmd="qsub -hold_jid $1 -N $BatchNam -pe smp $NoJobs -l h_vmem=$MaxMem -V -cwd $BatchNam.$$.sh"
	eval $StepCmd
else
	StepCmd="qsub -N $BatchNam -pe smp $NoJobs -pe smp $NoJobs -l h_vmem=$MaxMem -V -cwd $BatchNam.$$.sh"
	eval $StepCmd
fi
}



#Function to run and log batch jobs, as part of pipeline
funcPipeBatch () {
if [[ "$Pipeline" == "true" ]]; then
	echo "- Call $NextJob `date`:" >> $LogFil
	echo "	"$NextCmd >> $LogFil
	echo "Using qsub to submit as batch job with ID="$BatchNam >> $LogFil
	echo "#!/bin/batch" > $BatchNam.$$.sh
	echo $NextCmd >> $BatchNam.$$.sh
	if [[ -n $1 ]]; then
		NextCmd="qsub -hold_jid $1 -N $BatchNam -pe smp $NoJobs -l h_vmem=$MaxMem -V -cwd $BatchNam.$$.sh"
		eval $NextCmd
	else
		NextCmd="qsub -N $BatchNam -pe smp $NoJobs -l h_vmem=$MaxMem -V -cwd $BatchNam.$$.sh"
		eval $NextCmd
	fi
else
	echo $NextCmd >> $LogFil
	echo "Cannot start next qsub job without -P flag" >> $LogFil
fi
}

# Function to log the end of each script and transfer the contents of temporary log file to the main log file
funcWriteEndLog () {
echo "End "$0" $0:`date`" >> $TmpLog
echo "===========================================================================================" >> $TmpLog
echo "" >> $TmpLog
cat $TmpLog >> $LogFil
rm $TmpLog
}

# Function to call next step in pipeline
funcPipeline (){
if [[ "$Pipeline" == "true" ]]; then
    echo "- Call $NextJob `date`:" >> $TmpLog
    echo "    "$NextCmd  >> $TmpLog
    NextCmd=$NextCmd" &"
    eval $NextCmd
    echo "----------------------------------------------------------------" >> $TmpLog
else
    echo "- To start $NextJob run the following command:" >> $TmpLog
    echo "    "$NextCmd  >> $TmpLog
    echo "----------------------------------------------------------------" >> $TmpLog
fi
}
