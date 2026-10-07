#!/bin/bash

# R61 Pipeline Step 13
# Transform the MNI space denoised image to T1w space to be used for targetting
# JD 9/13/24 - adapted from steps defined by Julie Grier and Chuck Lynch

# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi
start=$SECONDS

echo $id
set_subject "$id"



# define pathways & ref files
R61=${PROJECT}
HCP=${HCP}
#BIDS=/project/oathes_analysis2/R61/bids
#FMRIPREP=/project/oathes_analysis2/R61/fmriprep/prerun_output
#RESOURCE=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/res0urces
#ACPC=/project/oathes_analysis2/R61/ME_acpc
#ECHO=/project/oathes_analysis2/R61/ME_acpc/$id/echoes

ANAT="$SUBJECT_FMRIPREP/sub-${id}/ses-baseline/anat"
XCP=$SUBJECT_XCP

prefix="MNI152-res2_to_T1w"

# Disassemble the .h5 file related to the transform you need
# In this case, MNI to T1w
CompositeTransformUtil --disassemble "$ANAT/sub-${id}_ses-baseline_from-MNI152NLin6Asym_to-T1w_mode-image_xfm.h5" $prefix
echo $ANAT/sub-${id}_ses-baseline_from-MNI152NLin6Asym_to-T1w_mode-image_xfm.h5
echo $prefix
wd=$(pwd)
mv $wd/00_${prefix}*.nii.gz $ANAT
mv $wd/01_${prefix}*.mat $ANAT

# Apply the transform
# Input = MNI denoised image
# Ref = T1w preprocessed anatomical image
# Transforms = 00 and 01 files from above

antsApplyTransforms -d 3 -e 3 \
-i $XCP/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-MNI152NLin6Asym_res-2_desc-denoised_bold.nii.gz \
-r $ANAT/sub-${id}_ses-baseline_desc-preproc_T1w.nii.gz \
-t $ANAT/00_${prefix}_DisplacementFieldTransform.nii.gz \
-t $ANAT/01_${prefix}_AffineTransform.mat \
-o $XCP/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-T1w_desc-denoised_bold.nii.gz

echo "T1w transform complete: $XCP/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-T1w_desc-denoised_bold.nii.gz"
# Perform same transformation on Liston sgACC (ref file in res0urces)

cp $RESOURCE/Liston_sgACCgm.nii.gz $ANAT

antsApplyTransforms -d 3 \
-i $ANAT/Liston_sgACCgm.nii.gz \
-r $ANAT/sub-${id}_ses-baseline_desc-preproc_T1w.nii.gz \
-t $ANAT/00_${prefix}_DisplacementFieldTransform.nii.gz \
-t $ANAT/01_${prefix}_AffineTransform.mat \
-o $ANAT/Liston_sgACCgm_sub-${id}.nii.gz

echo "sgACC transform complete: $ANAT/Liston_sgACCgm_sub-${id}.nii.gz"

#echo "Running 14_feat_prep.sh"
#bsub -q bsc_short /project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/14_feat_prep.sh $id



