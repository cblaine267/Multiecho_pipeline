#!/bin/bash

# use sed to find and replace the relevant fields in the design.fsf file
	# ajay always liked to use grep & xargs rather than sed but we'll see
# submit to cluster

# Relevant fields
# Line 33: set fmri(outputdir) ""
	# FEAT output dir: /R61/fsl_feat/<sub-id>.feat
# Line 39: set fmri(npts) 
	# Number of volumes (grep 3dinfo)
# Line 269: set fmri(totalVoxels)
	# Number of voxels
	# (R/L 208 x A/P 300 x I/S 320) x # of volumes
# Line 279: set feat_files(1) ""
	# Input 4D image - denoised bold xcp_d output
# Line 317: set fmri(custom1) ""
	# Custom EV - sgACC time series text file


# SET PATHS
source "/data/pipeline/MultiEchofMRI-Pipeline/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi
start=$SECONDS

echo $id
set_subject "$id"
#module load fsl/6.0.3
#module load afni_openmp/20.1

fsf_template=${DERIVATIVE}/fsl_feat/R61_baseline_feat_template.fsf
xcp=${XCP_D}/sub-${id}/ses-baseline/func
featdir=${DERIVATIVE}/fsl_feat/baseline_feat
log=${LOGS}/feat
res0urces=$RESOURCE


bold=$(readlink -e $xcp/sub-${id}_ses-baseline_task-rest_dir-AP_space-T1w_desc-denoised_bold.nii.gz)
ev=$(readlink -e $xcp/sub-${id}_sgACC_fsl.txt)

#volumes=$(3dinfo -nv $bold)
#voxpervol=$(3dinfo -nijk $bold)

volumes=$(fslval $bold dim4)
nx=$(fslval $bold dim1)
ny=$(fslval $bold dim2)
nz=$(fslval $bold dim3)
voxpervol=$(($nx*$ny*$nz))
echo $voxpervol

voxels=$(($volumes*$voxpervol))



outputdir="$featdir/${id}.feat"

echo "The following updates will be made to the .fsf file:"
echo "Line 33: set fmri(outputdir) $outputdir"
echo "Line 39: set fmri(npts) $volumes"
echo "Line 269: set fmri(totalVoxels) $voxels"
echo "Line 279: set feat_files(1) $bold"
echo "Line 317: set fmri(custom1) $ev"
#echo "If this is correct, please enter y. Otherwise, ctrl + c to make corrections"
#read y

cp $fsf_template $featdir/${id}_feat.fsf

sed -e "33 s|DIR|$outputdir|" -e "39 s|0|$volumes|" -e "269 s|VOX|$voxels|" -e "279 s|BOLD|$bold|" -e "317 s|EV|$ev|" $fsf_template > $featdir/${id}_feat.fsf

#bsub -q bsc_normal -o $log/${id}_feat.o -e $log/${id}_feat.e -n 16 -M 150000 -R "rusage[mem=150000] span[hosts=1]" -N sh $res0urces/feat_call.sh $id
#bsub -q bsc_normal -o $log/${id}_feat.o -e $log/${id}_feat.e -N sh $res0urces/feat_call.sh $id
sh $res0urces/feat_call.sh $id
