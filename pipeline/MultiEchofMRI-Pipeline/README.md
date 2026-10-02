SCRIPTS:

```
pipeline_paths.sh - sets all the paths for user's directory. User must edit this script.

1_flywheel_to_bids.sh – creates subject directory for new R61 subject to run through HCP pipeline; 
      run as bash script. Bids formating and intended for. 
2_anat_highres_HCP_wrapper_par.sh – runs the anatomical portions of the pipeline, 
      Pre, Current, Post Freesurfer; must be run as bsub script
3_fmriprep_wrapper.sh - submits fmriprep job.
      if local host has enough RAM, submits on docker. If not, submits job to cluster.
4_fmriprep_docker.sh – creates bids directory for new R61 subject to run through fMRIPrep; 
      run as bash script. Unable to run locally with 32 gb of ram.
5_acpc_warp.sh - generates ACPC aligned boldref images and MNI<->T1w warp files
6_echo_warp.sh - splits echo images into individual volumes and applies warp to each - submitted to cluster bc it takes a long time for each
6b_applywarp.sh - puts volumes back together into one image per echo; applies MNI mask to echoes & preps for Tedana submit
6c_mergewarp.sh – 
7_tedana.sh - submits the functional portion of the pipeline – TEDANA portion to cluster
8_ica_reclass.sh - reruns ica_reclassify after manual reclassification of accepted/rejected components

```
Notes:
```


```
