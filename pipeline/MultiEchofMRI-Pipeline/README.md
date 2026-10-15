# Script Directory

```
SCRIPTS:
Multiecho_pipeline/
├── pipeline/
│   └── docker
│   └── HCPpipelines_4.7.0
│   └── license.txt
|   └── resOurces
│   └── MultiEchofMRI-Pipeline --> User scripts 
    │   └── pipeline_path.sh - *USER EDIT: define paths for local machine*
    │   └── cluster_help.sh - *USER EDIT: define cluster paths and scripts if using HPC*
    │   └── docker-scripts ---> folder with all scripts called on by wrapper for local execution

```

# User Specific Scripts

User must edit the following scripts inside pipeline/MultiEchofMRI-Pipeline/ prior to running pipeline

```
pipeline_paths.sh - sets all the paths for user's directory. User must edit this script.

cluster_help.sh - includes functions to push, pull, and submit jobs to LPC. Edit script
                  with LPC scripts, pathes, etc.

```

# Wrapper Scripts

User input if data is to be run locally or on LPC. Submits job locally using 
./docker-scripts or submits job to lpc using cluster_help.sh. 

    - If job is to be submitted to the cluster and data is already available, 
    confirm push_request() function inside cluster_help.sh has the appropriate 
    scp commands uncommented.  
 
* **Usage (inside /project/pipeline/MultiEchofMRI-Pipeline):**
  bash ./{wrapper_script_name} {SubjectID}
  
```
1_flywheel_to_bids.sh – creates subject directory for new R61 subject to run through HCP pipeline; 
      run as bash script. Bids formating and intended for. 
      
      
2_freesurfer_wrapper.sh - runs the anatomical portions of the pipeline, 
      Pre, Current, Post Freesurfer; must be run as bsub script on LPC.
      
      - Local processing: calls docker-scripts/anat_highres_HCP_wrapper_par_docker.sh
     
      
3_fmriprep_wrapper.sh - submits fmriprep job with freesurfer outputs. 
      Needs > 32 GB of memory to process locally. If submitted to LPC, 
      follow SOP for moving freesurfer outputs (6_copy_freesurfer_output_to_fmriprep_source_data.sh).
      
      - Local processing: docker-scripts/fmriprep_docker.sh
      
      
4_acpc_wrapper.sh - starts ACPC workflow. Generates ACPC aligned boldref images and MNI<->T1w warp files
      acpc warp on LPC and local, automatically call step echo_warp.sh (9_echo_warp.sh on LPC).
    
    - Local processing: docker-scripts/acpc_warp.sh --> docker-scripts/echo_warp.sh + docker-scripts/applywarp_docker.sh
    
    
5_tedana_sumbit - runs the final step in the acpc alignment, merging and masking the warp echoes 
      then submits the tedana job. 

    - Local processing: docker-scripts/merge_warp.sh --> docker-scripts/adjusted_func_denoise_meica.sh
    
    
6_ica_reclass_wrapper.sh - rerun ica_reclassify after manual reclassification of accepted/rejected components.

    - Local processing: docker-scripts/ica_reclass.sh

    - For cluster submit - scp the new ICA AcceptedComponents.txt and RejectedComponents.txt into Tedana+
    folder before submitting ICA reclass job. 
    
    
7_create_ica_mixing_file.sh - takes outputs from tedana and creates custom confounds file
      for XCP-D
      
      - Local processing: docker-scripts/creating_ica_mixing_file_local.py
      
      
8_xcpd_wrapper.sh - runs xcp_d processing. 

      - Local processing: docker-scripts/xcp_d_mni152_local.sh
      
      - LPC submit: pushes ica mix file to LPC before submitting xcp_d job.
      
      
9_MNITransform_wrapper.sh - transforms xcp-d output and sgACC region from MNI to native T1w space.

      - Local processing: docker-scripts/transform_mni_to_t1w.sh
      
      - For UPenn LPC: MNI transform script calls automatically 
        submits the final steps of the pipeline.
      
      
10_feat_wrapper.sh - calculates sgACC time series from denoised bold image and sgACC mask. 
    Automatically generates design.fsf file for subject, submits fsl_feat job. 
    
      - Local processing: docker-scripts/feat_prep.sh --> docker-scripts/fsl_feat_submit.sh 

      

```
 


```
Notes:

For running on UPenn LPC, only need to run




```
## Pipeline Processess and Versions

### 1. System Bootstrap (`setup/bootstrap.sh`)
Initializes the local development environment by checking for required CLI utilities and installing systemic configurations.
* **Language:** Bash
* **Dependencies:** `brew` (macOS) or `apt` (Linux)
* **Usage:**
  ```bash
  ./scripts/setup/bootstrap.sh
  ```

### 2. Freesurfer (`backups/db_backup.sh`)
Anatomical portion of HCP4.7.0 pipeline. 
* **Dependencies:** `pg_dump`, `aws-cli`
* **Inputs:** Bash
* **Outputs:** `pg_dump`, `aws-cli`
* **Usage:**
  ```bash
  # Runs locally using environment variables
  DB_NAME="production" ./scripts/backups/db_backup.sh
  ```
  
### 3. fMRIPREP (v23.2.3)
Dumps the core application database, compresses the output, and pushes it securely to remote storage.
* **Language:** Bash
* **Dependencies:** `pg_dump`, `aws-cli`
* **Usage:**
  ```bash
  # Runs locally using environment variables
  DB_NAME="production" ./scripts/backups/db_backup.sh
  ```
  
  
  
```
