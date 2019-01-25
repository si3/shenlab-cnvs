# CNV exome pipeline - Shen Lab

Direct questions to Stefano Iantorno (sai2116@columbia.edu, si3@github)

This integrated pipeline aims to call CNVs from whole-exome sequencing (WES) data with three different read-depth based tools (CLAMMS, XHMM, CANOES) and is designed to consolidate commonalities while minimizing redundancy at each step of the workflow. The rationale behind integrating three different tools stems from the fact that each tool has specific strengths and weaknesses, and relies on different approaches to modeling read depth variation, GC, and sequence complexity. We provide a blueprint of a typical workflow that is customizable with minimal modification of shell scripts. More information on each tool is available from the respective websites.

To install, type the following while in your destination path:

`git clone git@github.com:si3/shenlab-cnvs.git`

Then rename the directory to a specific project name:

`mv shenlab-cnvs <name of project>`

This can be done to start a new project. The pipeline is designed to run on SGE HPC (biocluster). It uses a combination of GNU parallel and qsub to parallelize processes, and therefore needs to be started on a head node. The pipeline requires GNU parallel, XHMM, CLAMMS, mosdepth, and bedtools to be installed and in path. For some of the preparatory and analysis steps, PICARD and PLINK/PSEQ are also required. These are not part of the pipeline but they are only needed to create the windows file from the capture kit regions. The `Run_ref_prepper.sh` script performs these preparatory steps, but they can also be run manually. Please refer to individual scripts for requirements of each step.

-----------------------------------

The general directory structure is as follows:

- /PROJ_DIR
  - Run_pipeline_initiator.sh
  - Run_RD_calculator.sh
  - Run_RD_calculator_2.sh
  - Run_RD_reformatters.sh
  - cnv.exome.lib.sh
  - cnv.exome.references.sh

- /COV_DIR
  - Run_bedtools_to_CANOES.sh
  - Run_mosdepth_to_XHMM.sh
  - Run_CLAMMS_normalizer.sh
  - Run_CLAMMS_model_fitter.sh
	
- /CANOES_OUT
  - Run_CANOES.sh

- /CLAMMS_OUT
  - Run_CLAMMS.sh

- /XHMM_OUT
  - Run_XHMM.sh
  - Run_XHMM_reformatter.sh

The file cnv.exome.references.sh contains all the variables called by the different scripts. Two more directories, /RES_DIR and /SAMPLE_INFO_DIR, need to be created by user in /PROJ_DIR, and the reference shell script `cnv.exome.references.sh` needs to be updated with the correct path for various reference files to be loaded correctly in the pipeline. The file `cnv.exome.lib.sh` contains functions used by several steps of the pipeline.

-----------------------------------

The workflow is organized in ordered steps to ensure that the results are internally consistent and that calls can be compared across methods. The pipeline relies on a windows.bed file as the interval file used to estimate read depth in exon capture regions. These “windows” will be based on the capture kit intervals used for each batch of samples, but won’t have the same coordinates. Specifically, large exons will be broken down into ~500bp segments. Please refer to CLAMMS github page for more information. The initial steps of the XHMM workflow are modified to eliminate unnecessary extra steps. The pipeline uses the windows.bed file instead of a interval_list file as input. The pipeline uses the KNN option to build models for CNV detection in the CLAMMS algorithm. Please ensure that these unsorted files (e.g. 50nns files named in "sampleID.50nns.txt" format) have been generated and are in the appropriate directory in /CLAMMS_OUT.

First you need to configure each reference shell script with the path to the correct interval files, samples, and sample information files, as well as any other parameters specific to CLAMMS and XHMM workflow for your pipeline run. For each batch of bam files with the same intervals (i.e. generated with same capture kit) you can run the following using the same reference shell script. Multiple cnv.exome.references.sh can be created if you plan on running multiple pipelines at the same time for different batches of samples.

`bash Run_pipeline_initiator.sh -i path/to/bam_list -r path/to/cnv.exome.references.sh -P`

The -P flag will call all subsequent steps of the pipeline. If you would like to do each step manually, omit the -P flag and follow the instructions below. 
Briefly, the flow is structured as follows:

1) Run_pipeline_initiator.sh -> calls Run_RD_calculator.sh and Run_RD_calculator_2.sh
2) Run_RD_reformatter.sh -> calls Run_bedtools_to_CANOES.sh and Run_mosdepth_to_XHMM.sh
3) Run_CLAMMS.sh -> calls Run_CLAMMS_normalizer.sh and Run_CLAMMS_model_fitter.sh
4) Run_XHMM.sh -> calls CLAMMS specific scripts
5) Run_CANOES.sh -> calls CANOES.R

At any point, you can type the following to get more information on each script:

`bash <script> -H`

The relevant usage information will be printed to screen.
NOTE: the CANOES workflow is still pending.

-----------------------------------

- CLAMMS <https://github.com/rgcgithub/clamms>
- XHMM <https://atgu.mgh.harvard.edu/xhmm/tutorial.shtml>
