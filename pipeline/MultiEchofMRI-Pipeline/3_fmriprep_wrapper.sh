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

    bash "$PIPELINE/4_fmriprep.sh" $id



else

	 	source "$PIPELINE/cluster_help.sh"
		fmriprep_cluster_submit $id

fi
