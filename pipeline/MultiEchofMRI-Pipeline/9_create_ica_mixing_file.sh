id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo "$id"
source "$(dirname "$0")/pipeline_paths.sh"

clusterPull=$2
if [[ -z $clusterPull ]]; then 
	echo "Tedana reclass processed locally? (y/n) :"
	read clusterPull
fi

if [[ "$clusterPull" == "n" ]]; then

    bash 
    source "$PIPELINE/cluster_help.sh" 
    REQUEST="ICAMix"
    pull_request $id $REQUEST

fi

echo "$id"

ICA_MIX_FILE="${DERIVATIVE}/ica_mixing_files"

python creating_ica_mixing_file_local.py $id
mv sub-$(echo $id)_ses-baseline_task-rest_dir-AP_desc-confounds_timeseries.tsv ${ICA_MIX_FILE}
