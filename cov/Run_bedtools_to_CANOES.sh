#!/bash/bin

# This script takes output from bedtools and reformats it for input to CANOES
# Script needs to be in COV_DIR (same intended directory as output from bedtools)

# $1 variable - (required) path to batch *.bam_list (InpFil)
# $2 variable - (required) path to batch *.windows.bed (WinFil)
# windows.bed and bam_list.txt files need not have same prefix
# *identifiers cannot contain "."

# Set variables
BATCH=`basename $1 | cut -f1 -d"."`
WIND=`basename $2 | cut -f1 -d"."`

awk '{OFS="\t"};{print $1, $2, $3}' $2 > $BATCH.RD.coords.txt
cut $1 -f2 | while read SAMPLE; do
	awk '{print $4}' $SAMPLE.coverage.bed > $SAMPLE.tmp.cov
done

FILES=""
for FILE in $(ls *.tmp.cov | sort); do
    FILES=$FILES$FILE" "
done

paste $FILES > $BATCH.RD.txt
paste $BATCH.RD.coords.txt $BATCH.RD.txt > $BATCH.canoes.RD.txt # RD counts used by CANOES

# Clean up
rm *.tmp.cov
rm $BATCH.RD.coords.txt
rm $BATCH.RD.txt
