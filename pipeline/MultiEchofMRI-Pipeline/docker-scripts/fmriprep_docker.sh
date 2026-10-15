#!/bin/bash

set -e

# ============================================================
# SUBJECT
# ============================================================

# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then
    echo "Please enter subject's 4-digit ID (ex. C123):"
    read id
fi

echo $id
set_subject "$id"
SUBJECT="sub-${id}"


# ============================================================
# PATHS
# ============================================================

inputdir="${BIDS}"

outputdir="${SUBJECT_FMRIPREP}"

fsdir="${SUBJECT_FMRIPREP}/sourcedata/freesurfer"
echo "fsdir:      ${fsdir}"

hcpfs="${HCP}/anat/T1w"

echo "hcpfs:      ${hcpfs}"
# ============================================================
# CREATE OUTPUT DIRECTORIES
# ============================================================

mkdir -p "${fsdir}"


# ============================================================
# COPY EXISTING HCP/FREESURFER OUTPUT
# ============================================================

echo "Copying FreeSurfer subject..."

cp -r \
    "${hcpfs}/${id}" \
    "${fsdir}/${SUBJECT}"


echo "Copying fsaverage..."

cp -rL "${hcpfs}/fsaverage" "${fsdir}/"


# ============================================================
# CHECK
# ============================================================

echo ""
echo "BIDS input:"
echo "${inputdir}"

echo ""
echo "fMRIPrep output:"
echo "${outputdir}"

echo ""
echo "FreeSurfer subjects:"
ls -lah "${fsdir}"



templateflow=${TEMPLATEFLOW}

FS_LICENSE="${PIPELINE}/license.txt"
echo "${FS_LICENSE}"


# ============================================================
# CHECK INPUTS
# ============================================================


if [[ ! -d "${inputdir}" ]]; then
    echo "ERROR: BIDS input directory does not exist:"
    echo "${inputdir}"
    exit 1
fi

if [[ ! -f "${FS_LICENSE}" ]]; then
    echo "ERROR: FreeSurfer license does not exist:"
    echo "${FS_LICENSE}"
    exit 1
fi


# ============================================================
# CREATE OUTPUT DIRECTORIES
# ============================================================

mkdir -p "${outputdir}"
mkdir -p "${templateflow}"


# ============================================================
# TEMPORARY WORKING DIRECTORY
# ============================================================

workdir="${FMRIPREP_WORK}/${SUBJECT}"
#workdir="/Users/chblaine/Documents/R61/fmriprep/work/sub-J007"
#echo "Working directory:"
echo "${workdir}"
echo ""


# Remove temporary directory when script exits
# trap 'rm -rf "${workdir}"' EXIT


# ============================================================
# RUN FMRIPREP
# ============================================================


    echo "Running docker"

  docker run --rm \
      --platform linux/amd64 \
      -e TEMPLATEFLOW_HOME=/templateflow \
      -v "${workdir}:/work" \
      -v "${templateflow}:/templateflow" \
      -v "$(pwd)/license.txt":/usr/local/freesurfer/license.txt \
      -v "${inputdir}:/data/input:ro" \
      -v "${outputdir}:/data/output" \
      nipreps/fmriprep:23.2.3 \
      /data/input \
      /data/output \
      participant \
      --skull-strip-template OASIS30ANTs \
      --fs-license-file /usr/local/freesurfer/license.txt \
      --fs-subjects-dir /fssubdir/sourcedata/freesurfer \
      --output-spaces fsaverage T1w fsnative fsLR MNI152NLin6Asym:res-2 \
      --cifti-output 91k \
      --bold2t1w-dof 6 \
      --dvars-spike-threshold 1.5 \
      --fd-spike-threshold 0.5 \
      --ignore slicetiming \
      --me-output-echos \
      --notrack \
      --nthreads 16 \
      --omp-nthreads 15 \
      --work-dir /work \
      --low-mem \
      --verbose \
      --skip-bids-validation \
      --stop-on-first-crash \
      --participant-label "${SUBJECT}"
