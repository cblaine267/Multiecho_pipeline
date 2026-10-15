#!/bin/bash

## CHANGE LOG ##
# JD - 1/15/25
#	Added sed command to create patient-specific copy of auto_screen_parse_man_rej.m
#	No longer have to manually edit in res0urces folder

#module load miniconda/3-22.11
#eval "$(/appl/miniconda3-22.11/bin/conda shell.bash hook)"
#conda activate /project/oathes_analysis2/R61/tedanacondaenv
#export PYTHONPATH=/project/oathes_analysis2/R61/tedanacondaenv/lib/python3.9/site-packages:$PYTHONPATH
#export PATH=/project/oathes_analysis2/R61/tedanacondaenv/bin:$PATH
#export PATH=/project/oathes_analysis2/R61/tedanacondaenv/lib:$PATH

#module load fsl
#module load workbench
#module load freesurfer
#source /appl/freesurfer-7.4.0/SetUpFreeSurfer.sh
#pip install pandas.api.types
# res0urces=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/res0urces

id=$1
if [[ -z $id ]]; then
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo $id

# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"
set_subject "$id"


ok=$2
if [[ -z $ok ]]; then
		echo "Does Docker have more than 32 GB of memory available (y/n)? if no, job submitted to cluster:"
		read ok
fi
if [[ "$ok" == "y" ]]; then
	start=$SECONDS

	echo "Running docker. Merging warps, then submitting tedana job."
	
	docker run --rm -it \
    -v "${PROJECT}:/data" \
    chblaine/multiecho_pipeline:v4 \
    bash /data/pipeline/MultiEchofMRI-Pipeline/docker-scripts/merge_warp.sh "$id"
	


	
else


 	source "$PIPELINE/cluster_help.sh"
 	PUSH="tedana"
	cluster_submit $id $tedana

fi
