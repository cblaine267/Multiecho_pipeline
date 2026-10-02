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
TEDANA_SCRIPT="10_tedana_pipeline_submit.sh"
FMRIPREP_SCRIPT="7_submit_fmriprep_prerun_freesurfer.sh"


tedana_cluster_submit(){

  id=$1
  echo "Adding relevant files to HPC..."


  echo "Submitting job to cluster..."
  # Triggers sbatch inside the remote directory
  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_SCRIPT_DIR && bsub -q bsc_long -e ${LOCAL_SUBMIT_LOG}/$id.e -o ${LOCAL_SUBMIT_LOG}/$id.o bash $TEDANA_SCRIPT $id")
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
