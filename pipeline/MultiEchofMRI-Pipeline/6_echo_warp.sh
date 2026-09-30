#!/bin/bash

# R61 Pipeline Step 9
# Split echoes and apply warpfields to each individual volume
# JD 8/28/24 - adapted from steps defined by Chuck Lynch and Julie Grier


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

# define pathways

# R61=/project/oathes_analysis2/R61
# HCP=/project/oathes_analysis2/R61/$id
# BIDS=/project/oathes_analysis2/R61/bids
# FMRIPREP=/project/oathes_analysis2/R61/fmriprep/prerun_output
# RESOURCE=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/res0urces
# ACPC=/project/oathes_analysis2/R61/ME_acpc

# Make directory for acpc warps/outputs, echo splits, etc
mkdir -p "$SUBJECT_ACPC"



epi=sub-${id}_ses-baseline_task-rest_dir-AP_desc-coreg_boldref.nii.gz

# Create directories for echo manipulation
mkdir $ECHO

for i in $(seq 1 5) ; do
	mkdir $ECHO/echo${i}
done

mkdir $ECHO/avg

# Split each echo into 886 individual images each containing the information for one time point

for i in $(seq 1 5) ; do
	echo "Splitting echo_${i} into individual volumes..."
	fslsplit $FMRIPREP/sub-$id/sub-$id/ses-baseline/func/sub-${id}_ses-baseline_task-rest_dir-AP_echo-${i}_desc-preproc_bold.nii.gz $ECHO/echo${i}/E_${i}"$n_te"_
done

# Loop through full range of split files and assign each to a variable for averaging
for i in {0000..0885} ; do
	echo "Merging volumes across echoes..."
	echo $i
	file1="$ECHO/echo1/E_1_${i}.nii.gz"
	file2="$ECHO/echo2/E_2_${i}.nii.gz"
	file3="$ECHO/echo3/E_3_${i}.nii.gz"
	file4="$ECHO/echo4/E_4_${i}.nii.gz"
	file5="$ECHO/echo5/E_5_${i}.nii.gz"

	# Merge the files into a single output
	fslmerge -t "$ECHO/avg/AVG_${i}.nii.gz" "$file1" "$file2" "$file3" "$file4" "$file5"

	# Compute the mean of the merged output
	echo "Computing mean..."
	fslmaths "$ECHO/avg/AVG_${i}.nii.gz" -Tmean "$ECHO/avg/AVG_${i}.nii.gz"

	# Basically taking the n-th time point for each of the five echoes and averaging it
done

# Merge all of the averaged vols back into one large time-series image calles Rest_AVG
echo "Merging averaged volumes into single time series..."
fslmerge -t $ACPC/$id/Rest_AVG.nii.gz $ECHO/avg/AVG_*.nii.gz

# Generate MAT file for each time point that contains transformation info for Rest_AVG --> coreg epi image
echo "Generating MAT file for each time point..."
mcflirt -dof 6 -mats -stages 4 -in "$ACPC/$id/Rest_AVG.nii.gz" \
-r "$FMRIPREP/sub-$id/sub-$id/ses-baseline/func/$epi" \
-out "$ACPC/$id/Rest_AVG_mcf"

#### Julie's SOP has a seemingly redundant step here where we fslsplit the echoes AGAIN and rename them?
#### May be used for slice timing but not something we worry about atp
#### applywarp will overwrite the original files, could be good to retain unwarped just in case? Discuss w Desmond
#### should make a new dir for the new warps

duration=$(( $SECONDS - $start ))
hours=$(( $duration/3600 ))
minutes=$(( ($duration%3600)/60 ))
seconds=$(( ($duration%3600)%60 ))
echo "Submitting to cluster. Time from start to submission: $hours hour(s), $minutes minute(s), $seconds seconds" 

# Make new dir for warped echo outputs & submit applywarp.sh

mkdir -p "$R61/logs/warp"

for i in $(seq 1 5) ; do

    mkdir -p "$ECHO/warp_echo${i}"

    echo "Running applywarp for echo ${i}..."

    bash "$RESOURCE/6b_applywarp.sh" "$id" "$i" \
        > "$R61/logs/warp/${id}_warp_echo${i}.o" \
        2> "$R61/logs/warp/${id}_warp_echo${i}.e"

    echo "Echo ${i} complete."

done

# Have to wait a while for these to be done - need another script to run... 9.5? 9a --> 9b?
# Again a lot of cleanup potential - generating a lot of files we likely won't use/files that are redundant




