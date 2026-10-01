#!/bin/bash

# CLUSTER HELPER SCRIPTS

# Set user variables
HPC_USER="chblaine"
HPC_HOST="bscsub.pmacs.upenn.edu"
REMOTE_DIR="/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/"
LOCAL_DIR="/Users/chblaine/R61"

# Set cluster script
TEDANA_SCRIPT="10_tedana_pipeline_submit.sh"


tedana_cluster_submit(){
  id=$1
  echo "Adding relevant files to HPC..."


  echo "Submitting job to cluster..."
  # Triggers sbatch inside the remote directory
  JOB_OUTPUT=$(ssh -Y "${HPC_USER}@${HPC_HOST}" \
    "cd $REMOTE_DIR && bsub -q bsc_long -e /project/oathes_analysis2/individual_projects/camille/logs/$id.e -o /project/oathes_analysis2/individual_projects/camille/logs/$id.o bash $TEDANA_SCRIPT $id")
  echo "$JOB_OUTPUT"

}
