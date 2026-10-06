#!/bin/bash

# R61 Pipeline Step 5 - ACPC warp wrapper script

# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo $id
set_subject "$id"

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

    bash "$PIPELINE/5_acpc_warp.sh" $id



else

        source "$PIPELINE/cluster_help.sh"
        DATA="warp"
        cluster_submit $id $DATA

fi
