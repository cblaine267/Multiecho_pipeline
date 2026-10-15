#!/bin/bash

# R61 Pipeline Step 14
# Prep files for FSL FEAT
# JD 9/13/24 - adapted from steps defined by Julie Grier and Chuck Lynch

# SET PATHS
source "/data/pipeline/MultiEchofMRI-Pipeline/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi
start=$SECONDS

echo $id
set_subject "$id"
# load required modules
#module load fsl/6.0.3



ANAT="$SUBJECT_FMRIPREP/sub-${id}/ses-baseline/anat"
XCP="$SUBJECT_XCP/func"

# Create a mask of the sgACC
fslmaths $ANAT/Liston_sgACCgm_sub-${id}.nii.gz -thr 0.1 -bin $ANAT/Liston_sgACCgm_sub-${id}_bin.nii.gz

# Calculate mean timeseries of the sgACC within the denoised bold image 
fslmeants -i $XCP/sub-${id}_ses-baseline_task-rest_dir-AP_space-T1w_desc-denoised_bold.nii.gz \
-o $XCP/sub-${id}_sgACC_fsl.txt \
-m $ANAT/Liston_sgACCgm_sub-${id}_bin.nii.gz

echo "Time series generated: $XCP/sub-${id}_sgACC_fsl.txt"

#echo "Running feat_submit"

#source ./fsl_feat_submit.sh 

bash "$DOCKER_PIPELINE/fsl_feat_submit.sh" "$id"