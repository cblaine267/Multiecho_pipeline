#!/bin/bash

# =============================================================================
# R61 LOCAL PIPELINE CONFIGURATION
# =============================================================================
# Central location for paths used by all R61 pipeline scripts.
#
# Other scripts load this with:
#
#   source "$(dirname "$0")/R61_paths.sh"
#
# =============================================================================


if [[ -d "/data" ]]; then

    # -------------------------------------------------------------------------
    # INSIDE DOCKER
    # -------------------------------------------------------------------------

    PROJECT="/data"
    ENVIRONMENT="docker"

else

    # -------------------------------------------------------------------------
    # LOCAL MAC - adjust for each user
    # -------------------------------------------------------------------------

    PROJECT="/Users/chblaine/Documents/Multiecho_pipeline"
    ENVIRONMENT="local"

fi
echo "$ENVIRONMENT"

# -----------------------------------------------------------------------------
# PROJECT ROOT
# -----------------------------------------------------------------------------
SOURCEDATA="${PROJECT}/scan_data"
DERIVATIVE="${PROJECT}/derivatives"
LOGS="${PROJECT}/logs"


# -----------------------------------------------------------------------------
# PIPELINE
# -----------------------------------------------------------------------------

PIPELINE="${PROJECT}/pipeline/MultiEchofMRI-Pipeline"

RESOURCE="${PROJECT}/pipeline/res0urces"

ENVIRONMENTSCRIPT="${PROJECT}/pipeline/HCPpipelines_4.7.0/Examples/Scripts/SetUpHCPPipeline.sh"

# -----------------------------------------------------------------------------
# DATA
# -----------------------------------------------------------------------------

BIDS="${SOURCEDATA}/bids"

FMRIPREP="${DERIVATIVE}/fmriprep/prerun_output"

FMRIPREP_WORK="${DERIVATIVE}/fmriprep/work"

ACPC="${DERIVATIVE}/ME_acpc"

HCP_DIR="${DERIVATIVE}/HCP"

MATLAB_DEPENDENCY="${PROJECT}/dependencies/matlab_dependency"




# -----------------------------------------------------------------------------
# DOCKER IMAGES
# -----------------------------------------------------------------------------

HCP_IMAGE="hcp-pipeline4.7.0:v6"

FMRIPREP_IMAGE="nipreps/fmriprep:23.2.3"

# TEDANA


# -----------------------------------------------------------------------------
# FREESURFER
# -----------------------------------------------------------------------------

FS_LICENSE="/usr/local/freesurfer-license/license.txt"


# -----------------------------------------------------------------------------
# TEMPLATEFLOW
# -----------------------------------------------------------------------------

TEMPLATEFLOW="${PROJECT}/dependencies/templateflow"


# =============================================================================
# SUBJECT-SPECIFIC PATHS
# =============================================================================
#
# Call:
#
#   set_subject "$id"
#
# before using these.
# =============================================================================

set_subject() {

    id="$1"

    SUBJECT="sub-${id}"

    HCP="${DERIVATIVE}/HCP/${id}"

    SUBJECT_BIDS="${BIDS}/${SUBJECT}"

    SUBJECT_FMRIPREP="${FMRIPREP}/${SUBJECT}"

    SUBJECT_WORK="${FMRIPREP_WORK}/${SUBJECT}"

    SUBJECT_ACPC="${ACPC}/${id}"

    ECHO="${SUBJECT_ACPC}/echoes"

}



