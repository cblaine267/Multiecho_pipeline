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
		echo "Run locally (y/n)? if no, job submitted to cluster:"
		read ok
fi
if [[ "$ok" == "y" ]]; then
		# =============================================================================
		# DOCKER FMRIPREP
		# =============================================================================
    echo "Running docker"
    docker run --rm -it \
    -v "${PROJECT}:/data" \
    chblaine/multiecho_pipeline:v4 \
    bash /data/pipeline/MultiEchofMRI-Pipeline/docker-scripts/anat_highres_HCP_wrapper_freesurfer_docker.sh "$id"

else

	source "$PIPELINE/cluster_help.sh"
	PUSH="freesurfer"
	cluster_submit "$id" "$PUSH"

fi
