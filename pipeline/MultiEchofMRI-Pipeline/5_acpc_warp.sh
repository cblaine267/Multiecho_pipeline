#!/bin/bash

# R61 Pipeline Step 8
# AC/PC Alignment - extract and apply warps
# JD 8/27/24 - adapted from steps defined by Chuck Lynch and Julie Grier
# CHB 9/21/26 - adapt to local pipeline
# =============================================================================
# R61 Local Pipeline
#
# Combined former Steps 8 + 9:
#   1. Register fMRIPrep BOLD reference -> HCP ACPC T1w
#   2. Create BOLD -> ACPC warp
#   3. Create BOLD -> MNI composite warp
#   4. Split five preprocessed echoes
#   5. Average echoes at each timepoint
#   6. Reconstruct averaged BOLD time series
#   7. Estimate motion with MCFLIRT
#
# Usage:
#   ./5_acpc_warp.sh J007
#
# =============================================================================

# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo $id
set_subject "$id"

# define pathways

# R61=/project/oathes_analysis2/R61
# HCP=/project/oathes_analysis2/R61/$id
# BIDS=/project/oathes_analysis2/R61/bids
# FMRIPREP=/project/oathes_analysis2/R61/fmriprep/prerun_output
# RESOURCE=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/res0urces
# ACPC=/project/oathes_analysis2/R61/ME_acpc

# Make directory for acpc warps/outputs, echo splits, etc
mkdir -p "$SUBJECT_ACPC"

# Define dependent fmriprep/HCP files, copy to acpc

epi=sub-${id}_ses-baseline_task-rest_dir-AP_desc-coreg_boldref.nii.gz
t1=T1w_acpc_dc_restore.nii.gz
t1brain=T1w_acpc_dc_restore_brain.nii.gz
ostem_sbref2acpc=AvgSBref2acpc_EpiReg
ostem_sbref2mni=AvgSBref2nonlin_EpiReg

# -----------------------------------------------------------------------------
# Check required inputs
# -----------------------------------------------------------------------------

EPI_SOURCE="${SUBJECT_FMRIPREP}/${SUBJECT}/ses-baseline/func/${epi}"

T1_SOURCE="${HCP}/anat/T1w/${t1}"

T1BRAIN_SOURCE="${HCP}/anat/T1w/${t1brain}"

HCP_MNI_WARP="${HCP}/anat/MNINonLinear/xfms/acpc_dc2standard.nii.gz"


for file in \
    "$EPI_SOURCE" \
    "$T1_SOURCE" \
    "$T1BRAIN_SOURCE" \
    "$HCP_MNI_WARP"
do

    if [[ ! -f "$file" ]]; then
        echo "ERROR: Required file does not exist:"
        echo "$file"
        exit 1
    fi

done
###
# Copy to acpc
cp $FMRIPREP/sub-$id/sub-$id/ses-baseline/func/$epi $SUBJECT_ACPC
cp $HCP/anat/T1w/$t1 $SUBJECT_ACPC
cp $HCP/anat/T1w/$t1brain $SUBJECT_ACPC

# Run epi_reg_dof - register epi image to T1w_acpc w/ 6 DOF (BOLD-->T1w)

echo "Performing epi_reg_dof on $id"

$RESOURCE/epi_reg_dof --dof=6 \
--epi=$ACPC/$id/$epi \
--t1=$ACPC/$id/$t1 \
--t1brain=$ACPC/$id/$t1brain \
--out=$ACPC/$id/$ostem_sbref2acpc \
--echospacing=0.01771 \
--nofmapreg

echo "epi_reg_dof complete"
echo "Converting and applying warps..."
# Create warp img using the .mat from previous step w/ T1w_acpc aligned image as reference
convertwarp --ref=$ACPC/$id/$t1 \
--premat=$ACPC/$id/${ostem_sbref2acpc}.mat \
--out=$ACPC/$id/${ostem_sbref2acpc}_warp.nii.gz

# Apply the warp to the epi image using MNI space image as reference; coreg --> ACPC aligned
applywarp --interp=spline \
--in=$ACPC/$id/$epi \
--ref=$RESOURCE/MNI152_T1_2mm.nii.gz \
--out=$ACPC/$id/${ostem_sbref2acpc}.nii.gz \
--warp=$ACPC/$id/${ostem_sbref2acpc}_warp.nii.gz

# Create warp using acpc and HCP MNI as ref
convertwarp --ref=$RESOURCE/MNI152_T1_2mm.nii.gz \
--warp1=$ACPC/$id/${ostem_sbref2acpc}_warp.nii.gz \
--warp2=$HCP/anat/MNINonLinear/xfms/acpc_dc2standard.nii.gz \
--out=$ACPC/$id/${ostem_sbref2mni}_warp.nii.gz

# Apply nonlinear warp to original boldref; BOLD --> MNI
applywarp --interp=spline \
--in=$ACPC/$id/$epi \
--ref=$RESOURCE/MNI152_T1_2mm.nii.gz \
--out=$ACPC/$id/${ostem_sbref2mni}.nii.gz \
--warp=$ACPC/$id/${ostem_sbref2mni}_warp.nii.gz

echo "$id warping complete!"

# Likely a lot of cleanup potential here - lots of files that we don't end up needing or using

echo "time for step 9"
# bsub -q bsc_normal /project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/9_echo_warp.sh $id
