#!/bin/bash
#echo sub-$1_alff_cohort.csv
#if [[ "$SINGULARITY_TMPDIR" != "/scratch" ]]; then
#	echo "Setting SINGULARITY_TMPDIR" 
#	export SINGULARITY_TMPDIR=/scratch
#fi

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
clusterPull=$2
if [[ -z $clusterPull ]]; then 
  echo "fmriprep data available locally? (y/n) :"
  read clusterPull
fi

if [[ "$clusterPull" == "n" ]]; then

    source "$PIPELINE/cluster_help.sh" 
    REQUEST="fmriprep"
    pull_request $id $REQUEST

fi



#export SINGULARITYENV_TEMPLATEFLOW_HOME=/templateflow

#jobTmpDir=$( mktemp -d -p ${SINGULARITY_TMPDIR} xcp.XXXXXX.tmpdir )
#echo ${jobTmpDir}

#exit if temporary directory cannot be made
#echo ""
#if [[ ! -d "${jobTmpDir}" ]]; then
 #       echo "Could not create job temp dir ${jobTmpDir}"
#        exit 1
#fi

#export SINGULARITYENV_TMPDIR="/tmp"
#echo env tmp dir:  $SINGULARITYENV_TMPDIR
#echo reg tmp dir:  $SINGULARITY_TMPDIR

XCPD_OUTPUT="${DERIVATIVE}/xcp_d"
XCPD_WORK="${DERIVATIVE}/xcp_d/xcp_d_work"

mkdir -p "$XCPD_OUTPUT"
mkdir -p "$XCPD_WORK"

#input_dir=/project/oathes_analysis2/R61/fmriprep/prerun_output
#output_dir=/project/oathes_analysis2/R61/xcp_d
input_dir=${FMRIPREP}
output_dir=${XCP_D}

docker run --rm -it \
  --platform linux/amd64 \
  -v ${PROJECT}:/data \
  -v ${TEMPLATEFLOW}:/templateflow \
  -e TEMPLATEFLOW_HOME=/templateflow \
  pennlinc/xcp_d:0.6.3 \
  /data/derivatives/fmriprep/prerun_output \
  /data/derivatives/xcp_d \
  participant \
  --participant_label "$id" \
  --work_dir /data/derivatives/xcp_d/xcp_d_work \
  --bids-filter-file /data/pipeline/MultiEchofMRI-Pipeline/bids_filter_file.json \
  --fs-license-file /data/pipeline/license.txt \
  --nthreads 8 \
  --omp_nthreads 4 \
  -vvv \
  -f 0.5 \
  --input-type fmriprep \
  --smoothing 6 \
  -c /data/derivatives/ica_mixing_files \
  -p custom \
  --despike