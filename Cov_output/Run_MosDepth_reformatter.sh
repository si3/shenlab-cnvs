#!/bash/bin
# use with $1 variable set to batch *.bam_list prefix
# use with $2 variable set to *.windows.bed
# windows.bed and bam_list.txt files need not have same prefix

#cat /home/local/users/sai2116/CDH_CNVs/CDH_sample_info/$1.bam_list.txt | cut -f2 | while read SAMPLE; do
#       echo $SAMPLE >> $1.sample.names.txt
#       gzip -dc $SAMPLE.regions.bed.gz | cut -f5 | paste -s >> $1.mean.RD.txt
#done

#ls *.regions.bed.gz | while read FILE; do
#       FILENAME=`basename $FILE .regions.bed.gz`
#       echo $FILENAME >> sample.names.txt
#       gzip -dc $FILE | cut -f5 | paste -s >> mean.RD.txt
        #join $FILE /home/local/users/sai2116/CDH_CNVs/CDH_sample_info/$1.sorted.txt
#done

#use cut -f4 $2.windows.bed if no bookended or overlapping intervals
paste $1.sample.names.txt $1.mean.RD.txt >> $1.xhmm.mean.RD.txt
#cut -f4 /home/local/users/sai2116/cnv_calling/$1.windows.bed | paste -s | awk '{OFS="\t"} ; {print "Sample_mean_cvg", $0}' > $1.header.txt
cut -f1,2,3 /home/local/users/sai2116/cnv_calling/$2.windows.bed | awk '{ print $1":"$2"-"$3-1}' | paste -s | awk '{OFS="\t"} ; {print "Sample_mean_cvg", $0}' > $1.header.txt
cat $1.header.txt $1.xhmm.mean.RD.txt > $1.header.xhmm.mean.RD.txt
