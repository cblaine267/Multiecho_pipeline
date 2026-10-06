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
  elif [[ "$PUSH" == "warp" ]];then
    SCRIPT=$WARP_SCRIPT
    # 8_acpc_warp calls 9_echo_warp in lpc
  fi


  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_SCRIPT_DIR && bsub -q bsc_long -e ${LOCAL_SUBMIT_LOG}/${id}_${PUSH}.e -o ${LOCAL_SUBMIT_LOG}/${id}_${PUSH}.o bash $SCRIPT $id")
  echo "$JOB_OUTPUT"



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
  

    scp -r -v ${SUBJECT_FMRIPREP} "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/" 


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
  

    scp -r -v "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/" ${SUBJECT_FMRIPREP}


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

  fi

}




### OLD FUNCTIONS REPLACED BY CLUSTER SUBMIT

tedana_cluster_submit(){

  id=$1
  echo "Adding relevant files to HPC..."


  echo "Submitting job to cluster..."
  # Triggers sbatch inside the remote directory
  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_SCRIPT_DIR && bsub -q bsc_long -e ${LOCAL_SUBMIT_LOG}/${id}_reclass.e -o ${LOCAL_SUBMIT_LOG}/${id}_reclass.o bash $TEDANA_SCRIPT $id")
  echo "$JOB_OUTPUT"

}

reclass_cluster_submit(){

  id=$1
  echo "Adding relevant files to LPC..."
  PUSH=$2


  push_request $id $PUSH

  echo "Submitting job to cluster..."
  # Triggers sbatch inside the remote directory
  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_SCRIPT_DIR && bsub -q bsc_long -e ${LOCAL_SUBMIT_LOG}/${id}_reclass.e -o ${LOCAL_SUBMIT_LOG}/${id}_reclass.o bash $RECLASS_SCRIPT $id")
  echo "$JOB_OUTPUT"

}



fmriprep_cluster_submit(){
  
  # script to submit fmriprep cluster job. Inputs needed- HCP/anat/T1w and bids.

  source "$(dirname "$0")/pipeline_paths.sh"

  id=$1

  set_subject "$id"
  echo "Adding bids and freesurfer files to HPC..."
  


  ################
  # Uncomment to upload data to remote cluster


  #scp -r -v  ${SUBJECT_BIDS} "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/bids"
  #scp -r -v "${HCP}/anat/T1w/$id/*" "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/sourcedata/freesurfer/sub-$(echo $id)"
  #scp -r -v "${HCP}/anat/T1w/fsaverage" "${HPC_USER}@${HPC_HOST}://${REMOTE_PROJECT_DIR}/fmriprep/prerun_output/sub-$(echo $id)/sourcedata/freesurfer"

  



  echo "Submitting job to cluster..."
  # Triggers sbatch inside the remote directory
  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_SCRIPT_DIR && bsub -q bsc_normal -e ${LOCAL_SUBMIT_LOG}/fmriprep_$id.e -o ${LOCAL_SUBMIT_LOG}/fmriprep_$id.o bash $FMRIPREP_SCRIPT $id")
  echo "$JOB_OUTPUT"

}

# How to run command: bash "$PIPELINE/pull_request.sh" $id $data




