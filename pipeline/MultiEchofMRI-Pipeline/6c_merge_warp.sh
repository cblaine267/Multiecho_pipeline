#!/bin/bash

# R61 Pipeline Step 9b
# Merge output of echo warps and generate masks in preparation for tedana
# JD 8/28/24 - adapted from steps defined by Chuck Lynch and Julie Grier

### CHANGE LOG ###
# 2/27/25 - JD added "id=$1" functionality for submitting to cluster

# Have to wait to run this until the bsub applywarp scripts are done running

id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo $id

start=$SECONDS
# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"
set_subject "$id"

# define pathways & ref files
# R61=/project/oathes_analysis2/R61
# HCP=/project/oathes_analysis2/R61/$id
# BIDS=/project/oathes_analysis2/R61/bids
# FMRIPREP=/project/oathes_analysis2/R61/fmriprep/prerun_output
# RESOURCE=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/res0urces
# ACPC=/project/oathes_analysis2/R61/ME_acpc
# ECHO=/project/oathes_analysis2/R61/ME_acpc/$id/echoes

epi=sub-${id}_ses-baseline_task-rest_dir-AP_desc-coreg_boldref.nii.gz

echo $epi

# Merge the output volumes from applywarp into each echo
echo "Merging volumes..."
for i in $(seq 1 5) ; do
	fslmerge -t $ECHO/Rest_E${i}_acpc_nomask.nii.gz $ECHO/echo${i}/E_${i}_*.nii.gz
done
echo "Merging volumes complete!"
echo "Running FLIRT..."
# Use flirt to register brain mask from HCP output to MNI space
flirt -interp nearestneighbour \
-in "$HCP/anat/T1w/T1w_acpc_brain_mask.nii.gz" \
-ref "$RESOURCE/MNI152_T1_2mm.nii.gz" \
-out "$ACPC/$id/T1w_acpc_brain_func_mask.nii.gz" \
-applyxfm \
-init "$RESOURCE/ident.mat"
echo "FLIRT complete!"
# Copy to HCP folder with Tedana-compliant name
mkdir -p $HCP/func/rest/session_1/run_1
cp "$ACPC/$id/T1w_acpc_brain_func_mask.nii.gz" "$HCP/func/rest/session_1/run_1/brain_mask.nii.gz"

# Create masked image of all 5 echoes, copy output to HCP
echo "Masking echoes..."
for i in $(seq 1 5) ; do
	fslmaths $ECHO/Rest_E${i}_acpc_nomask -mas $ACPC/$id/T1w_acpc_brain_func_mask.nii.gz $ECHO/Rest_E${i}_acpc.nii.gz
	cp "$ECHO/Rest_E${i}_acpc.nii.gz" "$HCP/func/rest/session_1/run_1/"
done
echo "Echoes masked!"
# Copy TE.txt from resources to $HCP/func/rest/session_1/run_1 for tedana

TE_FILE="$HCP/func/rest/session_1/run_1/TE.txt"

echo "Creating TE.txt from BIDS EchoTime values..."

> "$TE_FILE"

for i in $(seq 1 5); do

    JSON="${BIDS}/sub-${id}/ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-${i}_bold.json"

    if [[ ! -f "$JSON" ]]; then
        echo "ERROR: Missing JSON file:"
        echo "$JSON"
        exit 1
    fi

    TE=$(python -c "import json; print(json.load(open('$JSON'))['EchoTime'])")

    printf "%s " "$TE" >> "$TE_FILE"

done

# Replace final space with newline
sed -i 's/ $//' "$TE_FILE"

echo "Remember to check alignment of Rest_E*_acpc.nii.gz and brain_mask.nii.gz in fsleyes"

duration=$(( $SECONDS - $start ))
hours=$(( $duration/3600 ))
minutes=$(( ($duration%3600)/60 ))
seconds=$(( ($duration%3600)%60 ))
echo "Duration: $hours hour(s), $minutes minute(s), $seconds seconds"








