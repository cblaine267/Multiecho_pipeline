#!/bin/bash

# ============================================================
# Flywheel -> BIDS Organization Script
#
# command:
#   ./flywheel_to_bids.sh C123
#
# ============================================================

set -e

source "$(dirname "$0")/pipeline_paths.sh"

# ------------------------------------------------------------
# Get subject ID
# ------------------------------------------------------------

id=$1

if [[ -z "$id" ]]; then
    echo "Please enter subject's 4-digit ID (ex. C123):"
    read -r id
fi

# Remove accidental "sub-" prefix
id="${id#sub-}"

# Set all subject-specific paths
set_subject "$id"


# =============================================================================
# FLYWHEEL PATHS
# =============================================================================

FLYWHEEL="${PROJECT}/scan_data/flywheel"

SUBJECT_FLYWHEEL="${FLYWHEEL}/${id}"

TEMPDIR="${SUBJECT_FLYWHEEL}/flywheel/oathes_lab/R61/${id}/ses-baseline"


# =============================================================================
# BIDS PATHS
# =============================================================================

BIDS_SUB="${SUBJECT_BIDS}/ses-baseline"


# =============================================================================
# HCP INPUT PATHS
# =============================================================================

HCP_UNPROCESSED="${HCP}/anat/unprocessed"

mkdir -p "$HCP_UNPROCESSED/T1w"
mkdir -p "$HCP_UNPROCESSED/T2w"
# ------------------------------------------------------------
# Check that Flywheel subject directory exists
# ------------------------------------------------------------

if [[ ! -d "$SUBJECT_FLYWHEEL" ]]; then
    echo "ERROR: Flywheel subject directory does not exist:"
    echo "  $SUBJECT_FLYWHEEL"
    echo ""
    echo "Make sure the Flywheel data has been downloaded into:"
    echo "  $FLYWHEEL"
    exit 1
fi

if [[ ! -d "$TEMPDIR" ]]; then
    echo "ERROR: Expected Flywheel session directory does not exist:"
    echo "  $TEMPDIR"
    exit 1
fi

# ------------------------------------------------------------
# Create BIDS directories
# ------------------------------------------------------------

echo "Creating BIDS directories..."

mkdir -p "$BIDS_SUB/anat"
mkdir -p "$BIDS_SUB/func"
mkdir -p "$BIDS_SUB/fmap"

echo "BIDS directories created."
echo ""

# ------------------------------------------------------------
# PA SBRef directory
# ------------------------------------------------------------

if [[ -d "$TEMPDIR/rsfMRI_multiecho_PA_SBRef" ]]; then
    echo "Renaming PA SBRef directory..."
    mv "$TEMPDIR/rsfMRI_multiecho_PA_SBRef" "$TEMPDIR/PA_SBRef"
fi

# ------------------------------------------------------------
# Function to find a file
# ------------------------------------------------------------

find_file() {
    local pattern="$1"

    local file
    file=$(find "$TEMPDIR" -type f -name "$pattern" -print -quit 2>/dev/null)

    if [[ -z "$file" ]]; then
        echo "ERROR: Could not find:"
        echo "  $pattern"
        exit 1
    fi

    echo "$file"
}

# ------------------------------------------------------------
# Find anatomical files
# ------------------------------------------------------------

echo "Locating anatomical files..."

T1w_nii=$(find_file "*_anat_T1w_*.nii.gz")
T2w_nii=$(find_file "*_anat_T2w_*.nii.gz")
T1w_json=$(find_file "*_anat_T1w_*.json")
T2w_json=$(find_file "*_anat_T2w_*.json")

# ------------------------------------------------------------
# Find AP multiecho files
# ------------------------------------------------------------

echo "Locating AP multiecho files..."

AP_DIR="$TEMPDIR/rsfMRI_multiecho"

ap_e1_nii=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e1.nii.gz" -print -quit)
ap_e2_nii=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e2.nii.gz" -print -quit)
ap_e3_nii=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e3.nii.gz" -print -quit)
ap_e4_nii=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e4.nii.gz" -print -quit)
ap_e5_nii=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e5.nii.gz" -print -quit)

ap_e1_json=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e1.json" -print -quit)
ap_e2_json=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e2.json" -print -quit)
ap_e3_json=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e3.json" -print -quit)
ap_e4_json=$(find "$TEMPDIR" -type f -path "${AP_DIR}/*multiecho*_e4.json" -print -quit)
ap_e5_json=$(find "$TEMPDIR" -type f -path "${AP_DIR}*multiecho*_e5.json" -print -quit)



# ------------------------------------------------------------
# Find PA multiecho files
# ------------------------------------------------------------

echo "Locating PA multiecho files..."

pa_e1_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA/*multiecho_PA*_e1.nii.gz" -print -quit)
pa_e2_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e2.nii.gz" -print -quit)
pa_e3_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e3.nii.gz" -print -quit)
pa_e4_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e4.nii.gz" -print -quit)
pa_e5_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e5.nii.gz" -print -quit)

pa_e1_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA/*multiecho_PA*.json" -print -quit)
pa_e2_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e2.json" -print -quit)
pa_e3_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e3.json" -print -quit)
pa_e4_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e4.json" -print -quit)
pa_e5_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA*/*multiecho_PA*_e5.json" -print -quit)

# ------------------------------------------------------------
# Find AP SBRef files
# ------------------------------------------------------------

echo "Locating AP SBRef files..."

sbref_e1_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e1.nii.gz" -print -quit)
sbref_e2_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e2.nii.gz" -print -quit)
sbref_e3_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e3.nii.gz" -print -quit)
sbref_e4_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e4.nii.gz" -print -quit)
sbref_e5_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e5.nii.gz" -print -quit)

sbref_e1_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e1.json" -print -quit)
sbref_e2_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e2.json" -print -quit)
sbref_e3_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e3.json" -print -quit)
sbref_e4_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e4.json" -print -quit)
sbref_e5_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_SBRef/*multiecho*_e5.json" -print -quit)

# ------------------------------------------------------------
# Find PA fieldmap
# ------------------------------------------------------------

echo "Locating PA fieldmap..."

fmap_nii=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA/*multiecho_PA*.nii.gz" -print -quit)
fmap_json=$(find "$TEMPDIR" -type f -path "*/rsfMRI_multiecho_PA/*multiecho_PA*.json" -print -quit)

# ------------------------------------------------------------
# Copy anatomical files
# ------------------------------------------------------------

echo ""
echo "Copying anatomical files..."

cp "$T1w_nii" \
   "$BIDS_SUB/anat/sub-${id}_ses-baseline_T1w.nii.gz"

cp "$T1w_json" \
   "$BIDS_SUB/anat/sub-${id}_ses-baseline_T1w.json"

cp "$T2w_nii" \
   "$BIDS_SUB/anat/sub-${id}_ses-baseline_T2w.nii.gz"

cp "$T2w_json" \
   "$BIDS_SUB/anat/sub-${id}_ses-baseline_T2w.json"

echo "Copying anatomical files for HCP pipeline..."

cp "$T1w_nii" \
   "$HCP_UNPROCESSED/T1w/T1w_1.nii.gz"

cp "$T1w_json" \
   "$HCP_UNPROCESSED/T1w/T1w_1.json"

cp "$T2w_nii" \
   "$HCP_UNPROCESSED/T2w/T2w_1.nii.gz"

cp "$T2w_json" \
   "$HCP_UNPROCESSED/T2w/T2w_1.json"

# ------------------------------------------------------------
# Copy AP multiecho BOLD
# ------------------------------------------------------------

echo "Copying AP multiecho BOLD files..."
echo "${ap_e1_nii}"

cp "$ap_e1_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-1_bold.nii.gz"
cp "$ap_e1_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-1_bold.json"

cp "$ap_e2_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-2_bold.nii.gz"
cp "$ap_e2_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-2_bold.json"

cp "$ap_e3_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-3_bold.nii.gz"
cp "$ap_e3_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-3_bold.json"

cp "$ap_e4_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-4_bold.nii.gz"
cp "$ap_e4_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-4_bold.json"

cp "$ap_e5_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-5_bold.nii.gz"
cp "$ap_e5_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-5_bold.json"

# ------------------------------------------------------------
# Copy AP SBRef
# ------------------------------------------------------------

echo "Copying AP SBRef files..."

cp "$sbref_e1_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-1_sbref.nii.gz"
cp "$sbref_e1_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-1_sbref.json"

cp "$sbref_e2_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-2_sbref.nii.gz"
cp "$sbref_e2_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-2_sbref.json"

cp "$sbref_e3_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-3_sbref.nii.gz"
cp "$sbref_e3_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-3_sbref.json"

cp "$sbref_e4_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-4_sbref.nii.gz"
cp "$sbref_e4_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-4_sbref.json"

cp "$sbref_e5_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-5_sbref.nii.gz"
cp "$sbref_e5_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-5_sbref.json"


# ------------------------------------------------------------
# Copy PA multiecho BOLD
# ------------------------------------------------------------

echo "Copying PA multiecho BOLD files..."

cp "$pa_e1_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-1_bold.nii.gz"
cp "$pa_e1_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-1_bold.json"

cp "$pa_e2_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-2_bold.nii.gz"
cp "$pa_e2_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-2_bold.json"

cp "$pa_e3_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-3_bold.nii.gz"
cp "$pa_e3_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-3_bold.json"

cp "$pa_e4_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-4_bold.nii.gz"
cp "$pa_e4_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-4_bold.json"

cp "$pa_e5_nii" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-5_bold.nii.gz"
cp "$pa_e5_json" "$BIDS_SUB/func/sub-${id}_ses-baseline_task-rest_dir-PA_echo-5_bold.json"

# ------------------------------------------------------------
# Copy PA fieldmap
# ------------------------------------------------------------

echo "Copying PA fieldmap..."


cp $fmap_nii "${BIDS_FMAP}.nii.gz"
cp $fmap_json "${BIDS_FMAP}.json"

BIDS_FMAP="$BIDS_SUB/fmap/sub-${id}_ses-baseline_dir-PA_run-01_epi.json"

# ------------------------------------------------------------
# Add BIDS metadata to fieldmap JSON
# ------------------------------------------------------------

echo "Updating fieldmap JSON..."

# append "IntendedFor" section to fmap json
#echo "Append the following to $bids_fmap:"
IntendedFor=$(echo \"IntendedFor\": [\"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-1_bold.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-2_bold.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-3_bold.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-4_bold.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-5_bold.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-1_sbref.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-2_sbref.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-3_sbref.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-4_sbref.nii.gz\", \"ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-5_sbref.nii.gz\"],)
RawSources=$(echo \"RawSources\": [\"/data/input/sub-${id}/ses-baseline/fmap/sub-${id}_ses-baseline_dir-PA_run-01_epi.nii.gz\"],)
TaskName=$(echo \"TaskName\": \"rest\")


# Using 'sed' to automatically append IntendedFor fields
# -i : overwrites file with changes
# -e : used to allow multiple arguments
# "$(( $( cat $bids_fmap | wc -l ) )) : generates line number of last element before }
# ...s/$/,/" : (s)ubstitute end of line ($) with comma (,)
# "$ i \  $IntendedFor" : (i)nsert tab ( \	) and $IntendedFor substitution
# $bids_fmap : perform these substitutions and commands on $bids_fmap

sed -i -e "$(( $( cat $bids_fmap | wc -l ) - 1 ))s/$/,/" -e "$ i \	$IntendedFor" -e "$ i \	$RawSources" -e "$ i \	$TaskName" $bids_fmap


# ------------------------------------------------------------
# Final check
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "BIDS organization complete for $id"
echo "=============================================="
echo ""
echo "Output:"
echo "  $BIDS_SUB"
echo ""

echo "Files created:"
find "$BIDS_SUB" -type f | sort

echo ""
echo "Total files:"
find "$BIDS_SUB" -type f | wc -l
echo ""
