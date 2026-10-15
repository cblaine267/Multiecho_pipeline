#!/bin/bash

# CLUSTER HELPER SCRIPTS

# Set user variables
HPC_USER="chblaine"
HPC_HOST="bscsub.pmacs.upenn.edu"
HPC_TRANSFER="transfer.pmacs.upenn.edu"
REMOTE_SCRIPT_DIR="/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/"
REMOTE_PROJECT_DIR="/project/oathes_analysis2/R61/"
LOCAL_DIR="/Users/chblaine/Multiecho_pipeline"
LOCAL_SUBMIT_LOG="/project/oathes_analysis2/individual_projects/camille/logs"

# Set cluster scripts
TEDANA_SCRIPT="9b_merge_and_mask.sh" # 9b calls 10_tedana.sh
FMRIPREP_SCRIPT="7_submit_fmriprep_prerun_freesurfer.sh"
RECLASS_SCRIPT="10b_ica_reclass.sh"
WARP_SCRIPT="8_acpc_warp.sh"
XCPD_SCRIPT="12_submit_xcp_d_mni152.sh"
ANTS_FEAT="13_transform_mni_to_t1w.sh"
FREESURFER_SCRIPT="3_freesurfer.sh"


##
# Script


cluster_submit(){

  id=$1

  PUSH=$2

  echo "Adding relevant files to LPC"


  push_request $id $PUSH

  if [[ "$PUSH" == "tedana" ]]; then
    SCRIPT=$TEDANA_SCRIPT
  elif [[ "$PUSH" == "fmriprep" ]];then
    SCRIPT=$FMRIPREP_SCRIPT
  elif [[ "$PUSH" == "ICAReclass" ]];then
    SCRIPT=$RECLASS_SCRIPT
  elif [[ "$PUSH" == "xcpd" ]];then
    SCRIPT=$XCPD_SCRIPT
  elif [[ "$PUSH" == "warp" ]];then
    SCRIPT=$WARP_SCRIPT
    # 8_acpc_warp calls 9_echo_warp in lpc
  elif [[ "$PUSH" == "ants" ]];then
    SCRIPT=$ANTS_FEAT
  elif [[ "$PUSH" == "freesurfer" ]];then
    SCRIPT=$FREESURFER_SCRIPT
  fi
  echo $SCRIPT

  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_SCRIPT_DIR && bsub -q bsc_long -e ${LOCAL_SUBMIT_LOG}/${id}_${PUSH}.e -o ${LOCAL_SUBMIT_LOG}/${id}_${PUSH}.o bash $SCRIPT "$id"")
  echo "$JOB_OUTPUT"

  if [[ "$PUSH" == "ants" ]];then
    echo "Steps 13, 14, and 15 submitted to LPC."

  fi

}


push_request(){
  source "$(dirname "$0")/pipeline_paths.sh"

  id=$1

  set_subject "$id"

  # Request to pull specific files from cluter 
  # Options: fmriprep, Tedana outputs, warps
  data=$2
  echo $data
  if [[ -z $data ]]; then 
    echo "Please enter data requested (fmriprep, tedana, warps, ICAMix ):"
    read data
  fi

  if [[ "$data" == "fmriprep" ]]; then
    echo "fressurfer data being pushed to LPC"

    #scp -r -v ${SUBJECT_FMRIPREP} "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/" 


  elif [[ "$data" == "tedana" ]]; then

    # COPY all echoes
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/" ${TEDANA_SESSION}


  elif [[ "$data" == "ICAReclass" ]]; then
    echo "Pushing Reclass"
    echo ${TEDANA_SESSION}
    scp -v "${TEDANA_SESSION}/Tedana+ManualComponentClassification/AcceptedComponents.txt" "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/${id}/func/rest/session_1/run_1/" 
    scp -v "${TEDANA_SESSION}/Tedana+ManualComponentClassification/RejectedComponents.txt" "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/${id}/func/rest/session_1/run_1/" 
  elif [[ "$data" == "warp" ]]; then

    echo "No data pushed. Inputs already on LPC"
  elif [[ "$data" == "xcpd" ]]; then
     echo "Comment out if xcpd ran on cluster"
    #scp -r -v "${SUBJECT_XCP}/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-MNI152NLin6Asym_res-2_desc-denoised_bold.nii.gz"  "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/xcp_d/xcp_d/sub-${id}/ses-baseline/func/" 

  elif [[ "$data" == "ICA_MIX" ]]; then

    scp -r -v "${ICA_MIX}/sub-$(echo $id)_ses-baseline_task-rest_dir-AP_desc-confounds_timeseries.tsv" "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/xcp_d/xcp_d/sub-${id}/ses-baseline/func/" 

  elif [[ "$data" == "ants" ]]; then
    echo "No data pushed. Inputs already on LPC"
  elif [[ "$data" == "freesurfer" ]]; then
    echo "Comment out if bids already on cluster"
    #scp -r -v "${SUBJECT_BIDS}"  "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/bids/" 
    #scp -r -v "${HCP}"  "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/" 

  fi

}


pull_request(){
  source "$(dirname "$0")/pipeline_paths.sh"

  id=$1

  set_subject "$id"

  # Request to pull specific files from cluter 
  # Options: fmriprep, Tedana outputs, warps
  data=$2
  if [[ -z $data ]]; then 
    echo "Please enter data requested (fmriprep, tedana, warps, ICAMix ):"
    read data
  fi

  if [[ "$data" == "fmriprep" ]]; then
  

    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/" ${FMRIPREP}


  elif [[ "$data" == "tedana" ]]; then

    # COPY all echoes
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/" ${TEDANA_SESSION}


  elif [[ "$data" == "ICAMix" ]]; then

    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/Tedana+ManualComponentClassification/desc-tedana_metrics.tsv" "${TEDANA_SESSION}/Tedana+ManualComponentClassification/"
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/Tedana+ManualComponentClassification/desc-ICAOrth_mixing.tsv" "${TEDANA_SESSION}/Tedana+ManualComponentClassification/"



  elif [[ "$data" == "TedanaComponents" ]]; then

    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/Tedana+ManualComponentClassification/figures/" "${TEDANA_SESSION}/Tedana+ManualComponentClassification/"
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/Tedana+ManualComponentClassification/AcceptedComponents.txt" "${TEDANA_SESSION}/Tedana+ManualComponentClassification/"
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/$id/func/rest/session_1/run_1/Tedana+ManualComponentClassification/RejectedComponents.txt" "${TEDANA_SESSION}/Tedana+ManualComponentClassification/"

  elif [[ "$data" == "ICAMix" ]]; then
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/xcp_d/xcp_d/sub-${id}/ses-baseline/func/" "${ICA_MIX}/sub-$(echo $id)_ses-baseline_task-rest_dir-AP_desc-confounds_timeseries.tsv"

  elif [[ "$data" == "xcpd" ]]; then

    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/xcp_d/xcp_d/sub-${id}/ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-MNI152NLin6Asym_res-2_desc-denoised_bold.nii.gz" "${SUBJECT_XCP}/func"
    #scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/xcp_d/xcp_d/sub-${id}/ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-T1w_desc-denoised_bold.nii.gz" "${SUBJECT_XCP}/func"

  elif [[ "$data" == "t1w" ]]; then

    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/xcp_d/xcp_d/sub-${id}/ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_space-T1w_desc-denoised_bold.nii.gz" "${SUBJECT_XCP}/func"
    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/sub-${id}/ses-baseline/anat/Liston_sgACCgm_sub-${id}.nii.gz" "${SUBJECT_FMRIPREP}/sub-${id}/ses-baseline/anat"

  fi

}






