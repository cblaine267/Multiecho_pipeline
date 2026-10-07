id=$1
if [[ -z $id ]]; then 
	echo "Please enter subject's 4-digit ID (ex. C123):"
	read id
fi

echo "$id"
source "$(dirname "$0")/pipeline_paths.sh"
set_subject $id

clusterPull=$2
if [[ -z $clusterPull ]]; then 
	echo "Tedana reclass processed locally? (y/n) :"
	read clusterPull
fi

if [[ "$clusterPull" == "n" ]]; then

    source "$PIPELINE/cluster_help.sh" 
    REQUEST="ICAMix"
    pull_request $id $REQUEST

fi

echo "$id"


echo $TEDANA_SESSION
python creating_ica_mixing_file_local.py $id $TEDANA_SESSION
mv sub-$(echo $id)_ses-baseline_task-rest_dir-AP_desc-confounds_timeseries.tsv ${ICA_MIX}
