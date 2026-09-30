docker run --rm -it \
  -v "$(pwd)/license.txt":/usr/local/freesurfer/license.txt \
  -v /Users/chblaine/Documents/R61:/data \
  -v "$(pwd)/anat_highres_HCP_wrapper_par.sh":/opt/anat_highres_HCP_wrapper_par.sh \
  hcp-pipeline4.7.0:v6 \
  bash
