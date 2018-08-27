#!/bash/bin

# This script takes output from bedtools and reformats it for input to CANOES
# Script needs to be in COV_DIR (same intended directory as output from bedtools)

# $1 variable - (required) path to batch *.bam_list (InpFil)
# $2 variable - (required) path to batch *.windows.bed (WinFil)
# $3 variable - (required) directory of coverage files (COV_DIR/bedtools)

# windows.bed and bam_list.txt files need not have same prefix
# *identifiers cannot contain "."

# Set variables
BATCH=`basename $1 | cut -f1 -d"."`
WIND=`basename $2 | cut -f1 -d"."`

awk '{OFS="\t"};{print $1, $2, $3}' $2 > $3/$BATCH.RD.coords.txt
cut $1 -f2 | while read SAMPLE; do
	awk '{print $NF}' $3/$SAMPLE.coverage.bed > $3/$SAMPLE.tmp.cov
done

#chmod 755 $3/*.tmp.cov
#chmod 755 $3/$BATCH.RD.coords.txt

FILES=""
for FILE in $(ls $3/*.tmp.cov | sort); do
    FILES=$FILES$FILE" "
done

paste $FILES > $3/$BATCH.RD.txt
paste $3/$BATCH.RD.coords.txt $3/$BATCH.RD.txt > $3/$BATCH.canoes.RD.txt # RD counts used by CANOES

# Clean up
rm $3/*.tmp.cov
rm $3/$BATCH.RD.coords.txt
rm $3/$BATCH.RD.txt
