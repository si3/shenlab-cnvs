#!/bin/bash

# Script needs to run in same directory as your XHMM xcnv calls
# Only needs name of *.xcnv file as argument
# NOTE: if a sample has no CNVs called, no *.cnv.bed file will be generated

cat $1.xcnv | cut -f1 | tail -n+2 | while read SAMPLE; do
        awk -v n=`echo $SAMPLE` '{OFS="\t"};{if ($1==n) {print $3, $1, $2, $6, $8, $10, $9, $11, $12, $13, $14, $15}}' $1.xcnv > $SAMPLE.xcnv
        cat $SAMPLE.xcnv | cut -f1 | awk -F'[:-]' -v OFS="\t" '{print $1, $2, $3}' > $SAMPLE.coords.bed
        paste $SAMPLE.coords.bed $SAMPLE.xcnv > ./XHMM_calls/$SAMPLE.cnv.bed
        #grep $SAMPLE $1.xcnv | awk '{OFS="\t"};{print $3, $1, $2, $6, $8, $10, $9, $11, $12, $13, $14, $15}' > $SAMPLE.xcnv
        #cat $SAMPLE.xcnv | awk -F'[:-]' -v OFS="\t" '{print $1, $2, $3}' > $SAMPLE.coords.bed
        #paste $SAMPLE.coords.bed $SAMPLE.xcnv > ./XHMM_calls/$SAMPLE.cnv.bed
        rm $SAMPLE.xcnv
        rm $SAMPLE.coords.bed
done
