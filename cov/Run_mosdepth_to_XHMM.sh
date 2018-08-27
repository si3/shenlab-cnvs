#!/bash/bin

# This script takes output from mosdepth and reformats it for input to XHMM
# Script needs to be in COV_DIR (same intended directory as mosdepth RD output)

# $1 variable - (required) path to batch *.bam_list (InpFil)
# $2 variable - (required) path to batch *.windows.bed (WinFil)
# $3 variable - (required) directory to mosdepth output (COV_DIR/mosdepth)

# windows.bed and bam_list.txt files need not have same prefix
# *identifiers cannot contain "."
# if your intervals are bookended, comment out 

# List of variables from cnv.exome.references.sh used in this script:

# COV_DIR
# SAMPLE_INFO_DIR
# RES_DIR

BATCH=`basename $1 | cut -f1 -d"."`
WIND=`basename $2 | cut -f1 -d"."`

cut $1 -f2 | while read SAMPLE; do
	echo $SAMPLE >> $3/$BATCH.sample.names.txt
	gzip -dc $3/$SAMPLE.regions.bed.gz | cut -f5 | paste -s >> $3/$BATCH.mean.RD.txt
done

#ls *.regions.bed.gz | while read FILE; do
#       FILENAME=`basename $FILE .regions.bed.gz`
#       echo $FILENAME >> sample.names.txt
#       gzip -dc $FILE | cut -f5 | paste -s >> mean.RD.txt
        #join $FILE /home/local/users/sai2116/CDH_CNVs/CDH_sample_info/$1.sorted.txt
#done

#use cut -f4 $2.windows.bed if no bookended or overlapping intervals
paste $3/$BATCH.sample.names.txt $3/$BATCH.mean.RD.txt >> $3/$BATCH.sample.names.mean.RD.txt
#cut -f4 $2 | paste -s | awk '{OFS="\t"} ; {print "Sample_mean_cvg", $0}' > $BATCH.header.txt
cut -f1,2,3 $2 | awk '{ print $1":"$2"-"$3-1}' | paste -s | awk '{OFS="\t"} ; {print "Sample_mean_cvg", $0}' > $3/$BATCH.header.txt
cat $3/$BATCH.header.txt $3/$BATCH.sample.names.mean.RD.txt > $3/$BATCH.xhmm.mean.RD.txt

# Clean up
rm $3/$BATCH.sample.names.mean.RD.txt
rm $3/$BATCH.mean.RD.txt
rm $3/$BATCH.sample.names.txt
rm $3/$BATCH.header.txt
