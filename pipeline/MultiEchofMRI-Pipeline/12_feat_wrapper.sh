#!/bin/bash

# CHB; (camilleblaine23@gmail.com)
# note: this script is a wrapper to submit fmriprep
# Docker > 32 GB RAM available --> fmriprep runs locally using docker container ;
# Docker < 32 GB RAM --> submit fmriprep job to HPC (cluster)


# Enter Subject ID

id=$1
if [[ -z $id ]]; then
    echo "Please enter subject's 4-digit ID (ex. C123):"
    read id
fi

echo $id
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pipeline_paths.sh"

ok=$2
if [[ -z $ok ]]; then
		echo "More than 32 GB of memory available for docker (y/n)? if no, job submitted to cluster:"
		read ok
fi
if [[ "$ok" == "y" ]]; then
		# =============================================================================
		# DOCKER FMRIPREP
		# =============================================================================
    echo "Running docker"

    # Uncomment if outputs needed from LPC to run feat
    #source "$PIPELINE/cluster_help.sh"
    #PULL="xcpd"
    #pull_request $id $PULL

    docker run --rm -it \
    -v "${PROJECT}:/data" \
    chblaine/multiecho_pipeline:v5 \
    bash /data/pipeline/MultiEchofMRI-Pipeline/12_feat_prep.sh "$id"
		



    #bash "$PIPELINE/11_transform_mni_to_t1w.sh" $id



else

	echo "Script already submitted. Pull feat output from LPC."
	 	source "$PIPELINE/cluster_help.sh"
	 	PUSH="ants"
		cluster_submit $id $PUSH

fi