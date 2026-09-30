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

start=$SECONDS
# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"
set_subject "$id"


# =============================================================================
# TEDANA ENVIRONMENT
# =============================================================================

# Conda itself is installed at /opt/conda
source /opt/conda/etc/profile.d/conda.sh

# Tedana environment created in Dockerfile
conda activate /opt/conda-envs/tedana


echo "Conda environment: $CONDA_PREFIX"
echo "Python:            $(which python)"

# Only run this if the environment actually contains tedana
if command -v tedana >/dev/null 2>&1; then
    echo "Tedana:            $(which tedana)"
    tedana --version
fi

#echo "Did you edit res0urces/auto_screen_parse_man_rej.m for the Subject ID? Cntrl + C if no"
#read y

#echo "Did you ibash + load the necessary modules & paths? Cntrl + C if no"
#read y


echo "$i"

TEDDIR="${HCP}/func/rest/session_1/run_1"

if [[ ! -f "$TEDDIR/TE.txt" ]]; then

    echo "TE.txt not found. Copying from resources..."

    if [[ ! -f "$RESOURCE/TE.txt" ]]; then
        echo "ERROR: Resource TE.txt does not exist:"
        echo "$RESOURCE/TE.txt"
        exit 1
    fi

    cp "$RESOURCE/TE.txt" "$TEDDIR/TE.txt"

else

    echo "TE.txt already exists."

fi


echo "Running ME-ICA denoising for $i..."

bash "$PIPELINE/adjusted_func_denoise_meica.sh" "$PROJECT" "$id"
