#!/bin/bash

# SET PATHS
source "$(dirname "$0")/pipeline_paths.sh"

id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo $id
set_subject "$id"

#echo "Did you move the reclassification files to /project/derivatives/HCP/$id/func/rest/session_1/run_1/?"
#read y

#R61=/project/oathes_analysis2/R61
#LOG=/project/oathes_analysis2/R61/logs/HCP
#scripts=/project/oathes_analysis2/R61/Liston-Laboratory-MultiEchofMRI-Pipeline-master/MultiEchofMRI-Pipeline

#bsub -q bsc_short -e $LOG/sub-${id}_RECLASS.e -o $LOG/sub-${id}_RECLASS.o -n 16 -M 50000 -R "rusage[mem=50000] span[hosts=1]" -N sh $scripts/ica_reclass_only.sh $R61 ${id}



#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# Adjusted by JAG; (juliegrier11@gmail.com) & CHB for local use (camilleblaine23@gmail.com)

Subject=$2
StudyFolder=${PROJECT}
Subdir="$HCP"
NTHREADS=1
MEPCA=kundu
MaxIterations=500
MaxRestarts=10
StartSession=1
MEDIR=${PIPELINE}


# =============================================================================
# TEDANA ENVIRONMENT
# =============================================================================

# Conda itself is installed at /opt/conda
source /opt/conda/etc/profile.d/conda.sh

# Tedana environment created in Dockerfile
conda activate /opt/conda-envs/tedana


echo "Conda environment: $CONDA_PREFIX"
echo "Python:            $(which python)"

# Only run this if the environment actually contains tedana
if command -v tedana >/dev/null 2>&1; then
    echo "Tedana:            $(which tedana)"
    tedana --version
fi


EnvironmentScript="/opt/HCPpipelines_4.7.0/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script
source ${EnvironmentScript}	# Set up pipeline environment variables and software

echo $PATH

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


# fresh workspace dir.
rm -rf "$Subdir"/workspace/ > /dev/null 2>&1 
mkdir "$Subdir"/workspace/ > /dev/null 2>&1 

# count the number of sessions
sessions=("$Subdir"/func/rest/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")
#cp "$Subdir"/func/rest/session_"$s"/run_"$r"/Tedana+*/RejectedComponents.txt "$Subdir"/func/rest/session_"$s"/run_"$r"
#cp "$Subdir"/func/rest/session_"$s"/run_"$r"/Tedana+*/AcceptedComponents.txt "$Subdir"/func/rest/session_"$s"/run_"$r"

# sweep the sessions;
#for s in $sessions ; do

	# count number of runs for this session;
#	runs=("$Subdir"/func/rest/session_"$s"/run_*)
#	runs=$(seq 1 1 "${#runs[@]}")
#
	# sweep the runs;
#	for r in $runs ; do

		# remove any existing Tedana+ dirs.;
#		rm -rf "$Subdir"/func/rest/session_"$s"/run_"$r"/Tedana+* \
#		> /dev/null 2>&1 

#	done


#done

# define a list of directories;
#DataDirs=$(cat "$Subdir"/data_dirs.txt) # note: this is used for parallel processing purposes.
#cat "$Subdir"/data_dirs.txt
#rm "$Subdir"/data_dirs.txt # remove intermediate file;

# delete some files;
rm -rf "$Subdir"/workspace/
cd "$Subdir" # go back to subject dir. 
DataDirs="session_1/run_1"
echo "DATA DIRS:"
echo $DataDirs
CLASS="$Subdir/func/rest/session_1/run_1/Tedana+ManualComponentClassification"

MANACC=$(tr '\n,' '  ' < "$CLASS/AcceptedComponents.txt" | xargs)
MANREJ=$(tr '\n,' '  ' < "$CLASS/RejectedComponents.txt" | xargs)

echo "MANACC=$MANACC"
echo "MANREJ=$MANREJ"

# make sure that the explicit brain mask and T2* map match; 
#fslmaths "$Subdir"/func/rest/"$DataDirs"/Rest_E1_acpc.nii.gz -Tmin "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz # remove any negative values introduced by spline interpolation;
#fslmaths "$Subdir"/func/xfms/rest/T1w_acpc_brain_func.nii.gz -mas "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz

# run the "tedana" workflow; 
#tedana -d "$Subdir"/func/rest/"$DataDirs"/Rest_E*_acpc.nii.gz -e $(cat "$Subdir"/func/rest/"$DataDirs"/TE.txt) --out-dir "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/ \
#--tedpca "$MEPCA" --fittype curvefit --mask "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz --mix "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-ICA_mixing.tsv \
#--ctab "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-tedana_metrics.tsv --manacc $(cat "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/AcceptedComponents.txt) \
#--maxit "$MaxIterations" --maxrestart "$MaxRestarts" --seed 42 --verbose # specify more iterations / restarts to increase likelihood of ICA convergence (also increases possible runtime).

#ica_reclassify "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-tedana_registry.json --manacc "$Subdir"/func/rest/"$DataDirs"/AcceptedComponents.txt --manrej "$Subdir"/func/rest/"$DataDirs"/RejectedComponents.txt --tedort  --out-dir "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/

ica_reclassify "$Subdir"/func/rest/"$DataDirs"/Tedana/desc-tedana_registry.json --manacc $MANACC --manrej $MANREJ --tedort  --out-dir "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/ 

# remove temporary files;
#rm "$Subdir"/func/rest/"$DataDirs"/brain_mask.nii.gz
#rm "$Subdir"/func/rest/"$DataDirs"/tmp.nii.gz

# move some files;
cp "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/desc-optcom_bold.nii.gz "$Subdir"/func/rest/"$DataDirs"/Rest_OCME_manclass.nii.gz # optimally combined time-series;
cp "$Subdir"/func/rest/"$DataDirs"/Tedana+ManualComponentClassification/desc-optcomDenoised_bold.nii.gz "$Subdir"/func/rest/"$DataDirs"/Rest_OCME+MEICA_manclass.nii.gz # multi-echo denoised time-series;











