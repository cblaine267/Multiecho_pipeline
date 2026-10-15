#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# Adjusted by JAG; (juliegrier11@gmail.com)
# CHANGE LOG
# JD - 1/15/25
#	Changed "auto_screen_parse_man_rej.m" call to refer to subject-specific copy in TEDDIR

#bash "$PIPELINE/adjusted_func_denoise_meica.sh" "$PROJECT" "$i"

id=$2

source "$(dirname "$0")/pipeline_paths.sh"
set_subject "$id"
Subject="${Subject:-$id}"
echo "Subject=$Subject"

StudyFolder=${PROJECT}
Subdir=${HCP}
NTHREADS=1
MEPCA=kundu
#MEPCA=500
MaxIterations=500
MaxRestarts=10
StartSession=1


# Docker paths
MEDIR=${PIPELINE}
RESOURCE=${RESOURCE}
TEDDIR="${HCP}/func/rest/session_1/run_1"


EnvironmentScript="/opt/HCPpipelines_4.7.0/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script



# count the number of sessions
sessions=("$Subdir"/func/rest/session_*)
echo "Subdir:" $Subdir
sessions=$(seq $StartSession 1 "${#sessions[@]}")
echo "Sessions:" $sessions

touch "$Subdir"/DataDirs.txt

# sweep the sessions;
for s in $sessions ; do

	# count number of runs for this session;
	runs=("$Subdir"/func/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")

	# sweep the runs;
	for r in $runs; do

		# "DataDirs.txt" contains
		# dir. paths to every scan.
		echo session_"$s"/run_"$r" \
		>> "$Subdir"/DataDirs.txt
		echo "CREATED DATADIRS.txt"
	done

done

# define a list of directories;
DataDirs=$(cat "$Subdir"/DataDirs.txt) # note: this is used for parallel processing purposes.
echo $DataDirs
rm "$Subdir"/DataDirs.txt # remove intermediate file;

# remove any existing Tedana dirs.;
rm -rf "$Subdir"/func/rest/"$DataDirs"/Tedana* > /dev/null 2>&1

# activate tedana v10;
#source activate me_v10

# Note: that in the make_adaptive_mask function in utils.py, following change is made...
# masksum = (np.abs(echo_means) > lthrs).sum(axis=-1) <-- this is the original code in Tedana; uses an arbitrary 33rd percentile cutoff.
# masksum = (np.abs(echo_means) > 0).sum(axis=-1) <--- this is effectively forces tedana to consider all in-brain voxels as "good".


# make sure that the explicit brain mask and T2* map match;
#fslmaths "$Subdir"/func/rest/"$DataDirs"/Rest_E1_acpc.nii.gz -Tmin "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz # remove any negative values introduced by spline interpolation;
#fslmaths "$Subdir"/func/xfms/rest/T1w_acpc_brain_func.nii.gz -mas "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz


echo "Checking Tedana inputs..."

for echo_num in 1 2 3 4 5; do

    echo_file="$Subdir/func/rest/$DataDirs/Rest_E${echo_num}_acpc.nii.gz"

    if [[ ! -f "$echo_file" ]]; then
        echo "ERROR: Missing echo:"
        echo "$echo_file"
        exit 1
    fi

    echo "FOUND: $echo_file"

done


# run the "tedana" workflow;
tedana -d "$Subdir"/func/rest/"$DataDirs"/Rest_E*_acpc.nii.gz -e $(cat "$Subdir"/func/rest/"$DataDirs"/TE.txt) --out-dir "$Subdir"/func/rest/"$DataDirs"/Tedana/ \
--tedpca "$MEPCA" --fittype curvefit --mask "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz --maxit "$MaxIterations" --maxrestart "$MaxRestarts" --seed 42 --verbose # specify more iterations / restarts to increase likelihood of ICA convergence (also increases possible runtime).
tedana_rc=$?
if [[ $tedana_rc -ne 0 || ! -f "$Subdir/func/rest/$DataDirs/Tedana/desc-tedana_metrics.tsv" ]]; then
    echo "ERROR: tedana failed (exit code $tedana_rc)"
    exit 1
fi
# # remove temporary files;
#rm "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz
rm -f "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz

# move some files;
cp "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-optcom_bold.nii.gz \
	"$Subdir"/func/rest/"$DataDirs"/Rest_OCME.nii.gz # optimally combined time-series;

cp "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-optcomDenoised_bold.nii.gz \
	"$Subdir"/func/rest/"$DataDirs"/Rest_OCME+MEICA.nii.gz # multi-echo denoised time-series;

# make some folders for manual
# acceptance / rejection of ICA components;
mkdir "$Subdir"/func/rest/"$DataDirs"/Tedana/figures/ManuallyAccepted/
mkdir "$Subdir"/func/rest/"$DataDirs"/Tedana/figures/ManuallyRejected/

echo
echo "============================================================"
echo "CREATING SUBCORTICAL ROIs"
echo "============================================================"
echo

ROI_DIR="$Subdir/func/rois"
tmp_dir="$ROI_DIR/tmp"

mkdir -p "$tmp_dir"


Labels=(8 47 26 58 18 54 11 50 17 53 13 52 12 51 10 49 16 28 60)


export SURFER_SIDEDOOR=1
count=1
for i in "${Labels[@]}";do
	echo $i
	mri_binarize --i ${HCP}/anat/T1w/aparc+aseg.nii.gz --match $i --o $(echo $tmp_dir)/Label$(echo $count).nii.gz
	flirt -interp trilinear -in $(echo $tmp_dir)/Label$(echo $count).nii.gz -ref ${RESOURCE}/MNI152_T1_2mm.nii.gz -applyxfm -init ${RESOURCE}/ident.mat -out $(echo $tmp_dir)/Label$(echo $count)_Interp.nii.gz
	fslmaths $(echo $tmp_dir)/Label$(echo $count)_Interp.nii.gz -thr 0.6 -bin $(echo $tmp_dir)/Label$(echo $count)_Interp_Thresh_Bin.nii.gz
	fslmaths $(echo $tmp_dir)/Label$(echo $count)_Interp_Thresh_Bin.nii.gz -mul $i $(echo $tmp_dir)/Label$(echo $count)_Final.nii.gz
	count=$((count + 1))
done


# =============================================================================
# MERGE SUBCORTICAL ROIs
# =============================================================================


fslmerge -t $(echo $tmp_dir)/FinalLabels.nii.gz $(echo $tmp_dir)/Label*Final.nii.gz
fslmaths $(echo $tmp_dir)/FinalLabels.nii.gz -Tmax $(echo $tmp_dir)/FinalLabels.nii.gz

wb_command -volume-label-import $(echo $tmp_dir)/FinalLabels.nii.gz ${RESOURCE}/SubcorticalLabels.txt ${HCP}/func/rois/Subcortical_ROIs_acpc.nii.gz -discard-others


#wb_command -volume-label-import /project/oathes_analysis2/R61/$(echo $Subject)/func/rois/Subcortical_ROIs_acpc.nii.gz res0urces/SubcorticalLabels.txt /project/oathes_analysis2/R61/$(echo $Subject)/func/rois/Subcortical_ROIs_acpc.nii.gz -discard-others

# sweep through files of interest
for i in desc-ICA_stat-z_components desc-limited_T2starmap desc-limited_S0map; do

	# sweep through hemispheres;
	for hemisphere in lh rh ; do

		# set a bunch of different
		# ways of saying left and right
		if [ $hemisphere = "lh" ] ; then
			Hemisphere="L"
		elif [ $hemisphere = "rh" ] ; then
			Hemisphere="R"
		fi

		# define all of the the relevant surfaces & files;
		PIAL="$Subdir"/anat/T1w/Native/"$Subject".$Hemisphere.pial.native.surf.gii
		WHITE="$Subdir"/anat/T1w/Native/"$Subject".$Hemisphere.white.native.surf.gii
		MIDTHICK="$Subdir"/anat/T1w/Native/"$Subject".$Hemisphere.midthickness.native.surf.gii
		MIDTHICK_FSLR32k="$Subdir"/anat/T1w/fsaverage_LR32k/"$Subject".$Hemisphere.midthickness.32k_fs_LR.surf.gii
		ROI="$Subdir"/anat/MNINonLinear/Native/"$Subject".$Hemisphere.roi.native.shape.gii
		ROI_FSLR32k="$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".$Hemisphere.atlasroi.32k_fs_LR.shape.gii
		REG_MSMSulc="$Subdir"/anat/MNINonLinear/Native/"$Subject".$Hemisphere.sphere.MSMSulc.native.surf.gii
		REG_MSMSulc_FSLR32k="$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".$Hemisphere.sphere.32k_fs_LR.surf.gii

		# map functional data from volume to surface;
		wb_command -volume-to-surface-mapping "$Subdir"/func/rest/"$DataDirs"/Tedana/"$i".nii.gz "$MIDTHICK" \
		"$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".native.shape.gii -ribbon-constrained "$WHITE" "$PIAL"

		# dilate metric file 10mm in geodesic space;
		wb_command -metric-dilate "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".native.shape.gii \
		"$MIDTHICK" 10 "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".native.shape.gii -nearest

		# remove medial wall in native mesh;
		wb_command -metric-mask "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".native.shape.gii \
		"$ROI" "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".native.shape.gii

		# resample metric data from native mesh to fs_LR_32k mesh;
		wb_command -metric-resample "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".native.shape.gii "$REG_MSMSulc" \
		"$REG_MSMSulc_FSLR32k" ADAP_BARY_AREA "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".32k_fs_LR.shape.gii \
		-area-surfs "$MIDTHICK" "$MIDTHICK_FSLR32k" -current-roi "$ROI"

		# remove medial wall in fs_LR_32k mesh;
		wb_command -metric-mask "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".32k_fs_LR.shape.gii \
		"$ROI_FSLR32k" "$Subdir"/func/rest/"$DataDirs"/Tedana/"$hemisphere".32k_fs_LR.shape.gii

	done
		# map betas to cortical surface (good for manual review of component classification)
	wb_command -cifti-create-dense-timeseries "$Subdir"/func/rest/"$DataDirs"/Tedana/"$i".dtseries.nii -volume "$Subdir"/func/rest/"$DataDirs"/Tedana/"$i".nii.gz "$Subdir"/func/rois/Subcortical_ROIs_acpc.nii.gz \
	-left-metric "$Subdir"/func/rest/"$DataDirs"/Tedana/lh.32k_fs_LR.shape.gii -roi-left "$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".L.atlasroi.32k_fs_LR.shape.gii \
	-right-metric "$Subdir"/func/rest/"$DataDirs"/Tedana/rh.32k_fs_LR.shape.gii -roi-right "$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".R.atlasroi.32k_fs_LR.shape.gii
done

# fresh workspace dir.
rm -rf "$Subdir"/workspace/ > /dev/null 2>&1
mkdir "$Subdir"/workspace/ > /dev/null 2>&1

# count the number of sessions
sessions=("$Subdir"/func/rest/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions;
for s in $sessions ; do

	# count number of runs for this session;
	runs=("$Subdir"/func/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")

	# sweep the runs;
	for r in $runs ; do



		# create temporary parse_man_rej.m

		#sed -e "11 s|SUBJECTID|$Subject|" $res0urces/auto_screen_parse_man_rej_TEMPLATE.m > $res0urces/auto_screen_parse_man_rej.m
		#cp -rf ${RESOURCE}/auto_screen_parse_man_rej.m \
		#"$Subdir"/workspace/temp.m
		#cp -rf "$TEDDIR"/auto_screen_parse_man_rej.m \
		#"$Subdir"/workspace/temp.m

		#sed -e "11 s|SUBJECTID|${Subject}|" \
    #"${RESOURCE}/auto_screen_parse_man_rej_TEMPLATE.m" \
    #> "${Subdir}/workspace/temp.m"

		# define some Matlab variables
		# ---------------------------------------------------------------------
        # ADD MATLAB PATHS
        # ---------------------------------------------------------------------

        #{
				#		echo "addpath(genpath('${MEDIR}'));"
				#		echo "resource_dir='${RESOURCE}';"
				#		echo "data_dir='${Subdir}/func/rest/session_${s}/run_${r}';"

            #echo "addpath(genpath('${MEDIR}'));"

        #    if [[ -d "$MATLAB_DEPENDENCY" ]]; then
        #        echo "addpath(genpath('${MATLAB_DEPENDENCY}'));"
        #    fi
#    cat "$Subdir/workspace/temp.m"

#        } > "$Subdir/workspace/temp_new.m"


#        mv \
#            "$Subdir/workspace/temp_new.m" \
#            "$Subdir/workspace/temp.m"
		RUN_DIR="${Subdir}/func/rest/session_${s}/run_${r}"

    # Remove previous classification output
    rm -rf "${RUN_DIR}"/Tedana+*

    # ---------------------------------------------------------------------
    # Automatic ICA component classification
    # ---------------------------------------------------------------------

    echo "Running automatic ICA component classification..."
    echo "Subject: ${id}"
    echo "Run: ${RUN_DIR}"

    if ! python3 "${MEDIR}/auto_screen_parse_man_rej.py" \
        "${id}" \
        "${RUN_DIR}" \
        "${RESOURCE}/Priors.mat"; then

        echo "ERROR: ICA component classification failed for ${id}"
        exit 1
    fi

    # Record processed run
    echo "/session_${s}/run_${r}/" \
        >> "${Subdir}/data_dirs.txt"
		#echo "addpath(genpath('${MEDIR}'))" | echo "addpath(genpath('/project/oathes_analysis2/R61/matlab_dependency'))" | cat - "$Subdir"/workspace/temp.m > temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1
		#echo data_dir=["'$Subdir/func/rest/session_$s/run_$r'"] | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1



		#cd "$Subdir"/workspace/ # run script via Matlab
		#matlab -nodesktop -nosplash -r "temp; exit" #JAG removed 06/07> /dev/null 2>&1
		#rm "$Subdir"/workspace/temp.m # delete some files

		# "data_dirs.txt" contains
		# dir. paths to every scan.
		echo /session_"$s"/run_"$r"/ \
		>> "$Subdir"/data_dirs.txt

	done


done

# define a list of directories;
DataDirs=$(cat "$Subdir"/data_dirs.txt) # note: this is used for parallel processing purposes.
cat "$Subdir"/data_dirs.txt
rm "$Subdir"/data_dirs.txt # remove intermediate file;

# delete some files;
rm -rf "$Subdir"/workspace/
cd "$Subdir" # go back to subject dir.

echo "DATA DIRS:"
echo $DataDirs

# make sure that the explicit brain mask and T2* map match;
#fslmaths "$Subdir"/func/rest/"$DataDirs"/Rest_E1_acpc.nii.gz -Tmin "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz # remove any negative values introduced by spline interpolation;
#fslmaths "$Subdir"/func/xfms/rest/T1w_acpc_brain_func.nii.gz -mas "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz

# run the "tedana" workflow;
#tedana -d "$Subdir"/func/rest/"$DataDirs"/Rest_E*_acpc.nii.gz -e $(cat "$Subdir"/func/rest/"$DataDirs"/TE.txt) --out-dir "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/ \
#--tedpca "$MEPCA" --fittype curvefit --mask "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz --mix "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-ICA_mixing.tsv \
#--ctab "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-tedana_metrics.tsv --manacc $(cat "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/AcceptedComponents.txt) \
#--maxit "$MaxIterations" --maxrestart "$MaxRestarts" --seed 42 --verbose # specify more iterations / restarts to increase likelihood of ICA convergence (also increases possible runtime).

ica_reclassify "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-tedana_registry.json --manacc "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/AcceptedComponents.txt --manrej "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/RejectedComponents.txt --tedort  --out-dir "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/

# remove temporary files;
#rm "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz
#rm "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz

# move some files;
cp "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/desc-optcom_bold.nii.gz "$Subdir"/func/rest/"$DataDirs"/Rest_OCME_manclass.nii.gz # optimally combined time-series;
cp "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/desc-optcomDenoised_bold.nii.gz "$Subdir"/func/rest/"$DataDirs"/Rest_OCME+MEICA_manclass.nii.gz # multi-echo denoised time-series;





#module load workbench

# sweep through files of interest
#for i in desc-ICA_components_MNI152NLin6Asym-res2 desc-limited_T2starmap_MNI152NLin6Asym-res2 desc-limited_S0map_MNI152NLin6Asym-res2; do

#	# sweep through hemispheres;
#	for hemisphere in lh rh ; do

		# set a bunch of different
		# ways of saying left and right
#		if [ $hemisphere = "lh" ] ; then
#			Hemisphere="L"
#		elif [ $hemisphere = "rh" ] ; then
#			Hemisphere="R"
#		fi

		# define all of the the relevant surfaces & files;
#		PIAL="$Subdir"/anat/T1w/Native/"$Subject".$Hemisphere.pial.native.surf.gii
#		WHITE="$Subdir"/anat/T1w/Native/"$Subject".$Hemisphere.white.native.surf.gii
#		MIDTHICK="$Subdir"/anat/T1w/Native/"$Subject".$Hemisphere.midthickness.native.surf.gii
#		MIDTHICK_FSLR32k="$Subdir"/anat/T1w/fsaverage_LR32k/"$Subject".$Hemisphere.midthickness.32k_fs_LR.surf.gii
#		ROI="$Subdir"/anat/MNINonLinear/Native/"$Subject".$Hemisphere.roi.native.shape.gii
#		ROI_FSLR32k="$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".$Hemisphere.atlasroi.32k_fs_LR.shape.gii
#		REG_MSMSulc="$Subdir"/anat/MNINonLinear/Native/"$Subject".$Hemisphere.sphere.MSMSulc.native.surf.gii
#		REG_MSMSulc_FSLR32k="$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".$Hemisphere.sphere.32k_fs_LR.surf.gii

		# map functional data from volume to surface;
#		wb_command -volume-to-surface-mapping "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$i".nii.gz "$MIDTHICK" \
#		"$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".native.shape.gii -ribbon-constrained "$WHITE" "$PIAL"

		# dilate metric file 10mm in geodesic space;
#		wb_command -metric-dilate "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".native.shape.gii \
#		"$MIDTHICK" 10 "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".native.shape.gii -nearest

		# remove medial wall in native mesh;
#		wb_command -metric-mask "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".native.shape.gii \
#		"$ROI" "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".native.shape.gii

		# resample metric data from native mesh to fs_LR_32k mesh;
#		wb_command -metric-resample "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".native.shape.gii "$REG_MSMSulc" \
#		"$REG_MSMSulc_FSLR32k" ADAP_BARY_AREA "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".32k_fs_LR.shape.gii \
#		-area-surfs "$MIDTHICK" "$MIDTHICK_FSLR32k" -current-roi "$ROI"

		# remove medial wall in fs_LR_32k mesh;
#		wb_command -metric-mask "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".32k_fs_LR.shape.gii \
#		"$ROI_FSLR32k" "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$hemisphere".32k_fs_LR.shape.gii

#	done

	# map betas to cortical surface (good for manual review of component classification)
#	wb_command -cifti-create-dense-timeseries "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$i".dtseries.nii -volume "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/"$i".nii.gz "$Subdir"/func/rois/Subcortical_ROIs_acpc.nii.gz \
#	-left-metric "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/lh.32k_fs_LR.shape.gii -roi-left "$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".L.atlasroi.32k_fs_LR.shape.gii \
#	-right-metric "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/rh.32k_fs_LR.shape.gii -roi-right "$Subdir"/anat/MNINonLinear/fsaverage_LR32k/"$Subject".R.atlasroi.32k_fs_LR.shape.gii
	#rm "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/*shape* # remove left over files

#done
