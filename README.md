# CNV Calling Pipeline

We used XHMM and CANOES to call CNVs on 100 trios from the PCGC study for QC of our variant calling methods.

All bams for the PCGC study can be found here: 
/home/local/ARCS/hq2130/WES/CHD_NimbleGenV2/bam/

The path to the 300 trio bams can be found here: 
/home/local/users/sai2116/PCGC_QC/100_trios.list 

The results of the QC analysis can be found in: 
/home/local/users/sai2116/PCGC_QC/

We then used XHMM to call CNVs in 1338 samples sequenced by Regeneron.
The bam files are split among the following directories:

/mnt/BigData/WENDY/BreastCancer/WES_data/Regeneron/bams/

/home/local/users/sai2116/RGN_BigData_bams (for bams in the above path that needed RG fixing*)

/mnt/BigData/WENDY/RGN_rare_disease/bams/

/home/local/users/sai2116/RGN_WES_rare_bams (for bams in the above path that needed RG fixing*)

Please refer to Qiang's github for a description of the RG error present in some bams, which was due to a plate swap that happened at Regeneron during sequencing. The RG in the header was fixed but the RG flag for each read still retained the wrong sample ID.
