#!/bin/bash
set -euo pipefail


export FSLDIR=/usr/local/fsl
export FSL_DIR="${FSLDIR}"
export FSLOUTPUTTYPE=NIFTI_GZ

export FREESURFER_HOME=/usr/local/freesurfer
export FS_LICENSE=/opt/freesurfer-license/license.txt

export HCPPIPEDIR=/opt/HCPpipelines_4.7.0

export CARET7DIR=/opt/workbench-2.0.0/bin_rh_linux64

export MSMBINDIR=/opt/msm/bin
export MSMCONFIGDIR="${HCPPIPEDIR}/MSMConfig"

export HCPCIFTIRWDIR="${HCPPIPEDIR}/global/matlab/cifti-matlab"
export HCPPIPEDIR_Config="${HCPPIPEDIR}/global/config"
export HCPPIPEDIR_Templates="${HCPPIPEDIR}/global/templates"

export PATH="${FSLDIR}/bin:${FREESURFER_HOME}/bin:${CARET7DIR}:${MSMBINDIR}:${HCPPIPEDIR}/FreeSurfer/custom:${PATH}"

set +u
source "${FSLDIR}/etc/fslconf/fsl.sh" 2>/dev/null || true
source "${FREESURFER_HOME}/SetUpFreeSurfer.sh" 2>/dev/null || true
set -u

# Reassert our container paths after package setup scripts.
export FSLDIR=/usr/local/fsl
export FSL_DIR="${FSLDIR}"
export FREESURFER_HOME=/usr/local/freesurfer
export FS_LICENSE=/usr/local/freesurfer-license/license.txt
export HCPPIPEDIR=/opt/HCPpipelines_4.7.0
export CARET7DIR=/opt/workbench-2.0.0/bin_rh_linux64
export MSMBINDIR=/opt/msm/bin
export TEDANA_ENV=/opt/conda-envs/tedana

export PATH="${FSLDIR}/bin:${FREESURFER_HOME}/bin:${CARET7DIR}:${MSMBINDIR}:${HCPPIPEDIR}/FreeSurfer/custom:${PATH}"

echo "============================================================"
echo "HCP Pipelines Docker container"
echo "============================================================"
echo "HCPPIPEDIR       = ${HCPPIPEDIR}"
echo "FSLDIR           = ${FSLDIR}"
echo "FREESURFER_HOME  = ${FREESURFER_HOME}"
echo "CARET7DIR        = ${CARET7DIR}"
echo "MSMBINDIR        = ${MSMBINDIR}"
echo "TEDANA        = ${TEDANA_ENV}"
echo "============================================================"

# Verify critical executables before doing any processing.
required_commands=(
    fslmaths
    recon-all
    wb_command
)

for cmd in "${required_commands[@]}"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: required command not found: ${cmd}" >&2
        echo "PATH=${PATH}" >&2
        exit 10
    fi
done

# Verify the HCP pipeline scripts.
for script in \
    "${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh" \
    "${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh" \
    "${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh"; do
    if [ ! -x "${script}" ]; then
        echo "ERROR: HCP pipeline script missing or not executable: ${script}" >&2
        exit 11
    fi
done

# License is required for FreeSurfer processing.
if [ ! -f "${FS_LICENSE}" ]; then
    echo "ERROR: FreeSurfer license not found at:"
    echo "       ${FS_LICENSE}"
    echo
    echo "Run the container with, for example:"
    echo "  -v /path/to/license.txt:/opt/freesurfer-license/license.txt:ro"
    exit 12
fi

# If arguments were supplied, execute them. Otherwise provide a shell.
if [[ $# -eq 0 ]]; then
    exec /bin/bash
else
    exec "$@"
fi
