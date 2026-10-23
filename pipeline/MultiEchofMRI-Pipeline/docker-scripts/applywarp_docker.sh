# JD - 8/29/24
# Adapted from commands outlined by Julie Grier, Chuck Lynch

# Script inputs from bsub call
source "/data/pipeline/MultiEchofMRI-Pipeline/pipeline_paths.sh"

id=$1
echo_val=$2

#set_subject "$id"
# Pathways

#RESOURCE=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline/res0urces
#ACPC=/project/oathes_analysis2/R61/ME_acpc
#ECHO=/project/oathes_analysis2/R61/ME_acpc/$id/echoes

ECHO="${ACPC}/${id}/echoes"

# -----------------------------------------------------------------------------
# Check that files were found
# -----------------------------------------------------------------------------

#if [[ ! -e "${images[0]}" ]]; then
#    echo "ERROR: No images found for echo ${echo_val}"
#    exit 1
#fi

#if [[ ! -e "${mats[0]}" ]]; then
 #   echo "ERROR: No MCFLIRT matrices found."
 #   exit 1
#fi


# -----------------------------------------------------------------------------
# Make sure number of images = number of matrices
# -----------------------------------------------------------------------------



if [[ ${#images[@]} -ne ${#mats[@]} ]]; then
    echo "ERROR: Number of images and motion matrices do not match."
    exit 1
fi


mkdir -p "$ECHO/warp_echo${echo_val}"

# Apply transform defined by premat MAT file to each echo E with SBref2ACPC as warp and MNI as ref
images=($ECHO/echo${echo_val}/E_${echo_val}_*.nii.gz)
mats=($ACPC/$id/Rest_AVG_mcf.mat/MAT_*)

echo "Images:   ${#images[@]}"
echo "Matrices: ${#mats[@]}"

for ((i=0; i<${#images[@]}; i++)); do
	echo "${images["$i"]}" 
	echo "${mats["$i"]}"

	applywarp --interp=spline \
	--in="${images["$i"]}" \
	--premat="${mats["$i"]}" \
	--warp=$ACPC/$id/AvgSBref2acpc_EpiReg_warp.nii.gz \
	--out="${images["$i"]}"  \
	--ref=$RESOURCE/MNI152_T1_2mm.nii.gz
done



