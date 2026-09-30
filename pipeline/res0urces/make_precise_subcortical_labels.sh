Labels=(8 47 26 58 18 54 11 50 17 53 13 52 12 51 10 49 16 28 60)
sub=$1
echo $sub
tmp_dir=/project/oathes_analysis2/R61/$(echo $sub)/func/rois/tmp
mkdir $tmp_dir
module unload workbench
export SURFER_SIDEDOOR=1
count=1
for i in "${Labels[@]}";do
	echo $i
	mri_binarize --i /project/oathes_analysis2/R61/$(echo $sub)/anat/T1w/aparc+aseg.nii.gz --match $i --o $(echo $tmp_dir)/Label$(echo $count).nii.gz
	flirt -interp trilinear -in $(echo $tmp_dir)/Label$(echo $count).nii.gz -ref MNI152_T1_2mm.nii.gz -applyxfm -init ident.mat -out $(echo $tmp_dir)/Label$(echo $count)_Interp.nii.gz
	#mri_binarize --i /project/oathes_analysis2/R61/fmriprep/prerun_output/sub-$(echo $sub)/sub-$(echo $sub)/ses-baseline/anat/sub-$(echo $sub)_ses-baseline_acq-MPR_desc-aparcaseg_dseg.nii.gz --match $i --o $(echo $tmp_dir)/Label$(echo $count).nii.gz
	#mri_binarize --i /project/oathes_analysis2/R61/C542/func/transformed_T1w_to_scannernative_aparc+aseg.nii.gz  --match $i --o $(echo $tmp_dir)/Label$(echo $count).nii.gz
	
	#fslmaths $(echo $tmp_dir)/Label$(echo $count).nii.gz -thr 0.6 -bin $(echo $tmp_dir)/Label$(echo $count)_Interp_Thresh_Bin.nii.gz
	fslmaths $(echo $tmp_dir)/Label$(echo $count)_Interp.nii.gz -thr 0.6 -bin $(echo $tmp_dir)/Label$(echo $count)_Interp_Thresh_Bin.nii.gz
	fslmaths $(echo $tmp_dir)/Label$(echo $count)_Interp_Thresh_Bin.nii.gz -mul $i $(echo $tmp_dir)/Label$(echo $count)_Final.nii.gz

	count=$((count + 1))
done

fslmerge -t $(echo $tmp_dir)/FinalLabels.nii.gz $(echo $tmp_dir)/Label*Final.nii.gz
fslmaths $(echo $tmp_dir)/FinalLabels.nii.gz -Tmax $(echo $tmp_dir)/FinalLabels.nii.gz

module load workbench
wb_command -volume-label-import $(echo $tmp_dir)/FinalLabels.nii.gz SubcorticalLabels.txt /project/oathes_analysis2/R61/$(echo $sub)/func/rois/Subcortical_ROIs_acpc.nii.gz -discard-others
cp $(echo $tmp_dir)/FinalLabels.nii.gz .
cp /project/oathes_analysis2/R61/$(echo $sub)/func/rois/Subcortical_ROIs_acpc.nii.gz .
