# =============================================================================
# HCP Pipelines processing image
#   FSL 6.0.3 | FreeSurfer 7.4.0 + 6.0.0 | Connectome Workbench 2.0.0
#   MSM | Python 3.9 | HCPpipelines_4.7.0 custom FreeSurfer scripts
#
# Build:
#   docker build -t hcp-pipelines:4.7.0 .
#
# Run (mounting the pieces that can't be baked into the image):
#   docker run --rm -it \
#     -v /path/to/license.txt:/opt/freesurfer/license.txt \
#     -v /path/to/data:/data \
#     -v /path/to/logs:/logs \
#     hcp-pipelines:4.7.0
# =============================================================================

FROM --platform=linux/amd64 ubuntu:20.04
LABEL maintainer="camille.blaine@pennmedicine.upenn.edu"
LABEL description="FSL 6.0.3 / FreeSurfer 7.4.0+6.0.0 / Workbench 2.0.0 / MSM / HCPpipelines 4.7.0 / Miniconda / Tedana23.0.2"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# SET ENVIRONMENTS
WORKDIR /tmp



# -----------------------------------------------------------------------------
# 1. Base OS packages
#    FreeSurfer (esp. the 6.0.0 CentOS6 build) and FSL both need a pile of
#    32/64-bit runtime libs that Ubuntu doesn't install by default.
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    ca-certificates \
    unzip \
    gzip \
    tar \
    git \
    tcsh \
    csh \
    perl \
    bc \
    dc \
    python3.9 \
    python3-pip \
    python2.7 \
    nano \
    file \
    dc \
    libgomp1 \
    libxt6 \
    libxmu6 \
    libxext6 \
    libsm6 \
    libice6 \
    libglu1-mesa \
    libgl1-mesa-glx \
    libxrender1 \
    libxrandr2 \
    libxfixes3 \
    libxcursor1 \
    libopenblas0 \
    libopenblas-dev \
    libxi6 \
    libxinerama1 \
    gfortran \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN python3.9 -m pip install --no-cache-dir numpy==1.24.4 \
    scipy==1.10.1 \
    nibabel==5.2.1 \
    h5py==3.10.0 \
    dill==0.3.8 \
    fslpy==3.19.0

RUN ln -sf /usr/bin/python3.9 /usr/bin/python

# 4. Download and run the Miniconda installer silently (-b for batch mode)
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh

# 5. Add Miniconda to the system PATH so 'conda' commands work immediately
ENV PATH=$CONDA_DIR/bin:$PATH

RUN wget -q \
    https://www.mathworks.com/mpm/glnxa64/mpm \
    -O /usr/local/bin/mpm && \
    chmod +x /usr/local/bin/mpm

RUN mpm install \
    --release=R2023b \
    --destination=/opt/matlab \
    --products=MATLAB Statistics_and_Machine_Learning_Toolbox

ENV MATLAB_ROOT="/opt/matlab"
ENV PATH="${MATLAB_ROOT}/bin:${PATH}"


# =============================================================================
# TEDANA ENVIRONMENT
# =============================================================================

COPY docker/tedana_environment.yml /tmp/tedana_environment.yml

ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# Accept Anaconda channel Terms of Service
RUN conda tos accept \
        --override-channels \
        --channel https://repo.anaconda.com/pkgs/main \
    && conda tos accept \
        --override-channels \
        --channel https://repo.anaconda.com/pkgs/r

RUN conda env create \
        -p /opt/conda-envs/tedana \
        -f /tmp/tedana_environment.yml \
    && conda clean -afy \
    && rm /tmp/tedana_environment.yml

ENV TEDANA_ENV=/opt/conda-envs/tedana
ENV PATH="${TEDANA_ENV}/bin:${PATH}"

# Verify Tedana during the Docker build
RUN echo "Checking Tedana environment..." \
    && which python \
    && python --version \
    && which tedana \
    && tedana --version \
    && python -c "import tedana; print('Tedana Python package:', tedana.__version__)"


### FSL
RUN wget -q \
    https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.3-centos6_64.tar.gz \
    && tar --no-same-owner -xzvf fsl-6.0.3-centos6_64.tar.gz \
    && mv ./fsl /usr/local \
    && rm -f ./fsl-6.0.3.tar.gz



ENV FSLDIR=/usr/local/fsl

ENV PATH=${FSLDIR}/bin:${PATH}

# Remove any bad cluster-specific wrappers
RUN rm -f \
    /usr/local/fsl/bin/imcp \
    /usr/local/fsl/bin/immv \
    /usr/local/fsl/bin/imglob

# Put the fslpy commands where HCP Pipelines expects them
RUN ln -s "$(command -v imcp)" /usr/local/fsl/bin/imcp \
 && ln -s "$(command -v immv)" /usr/local/fsl/bin/immv \
 && ln -s "$(command -v imglob)" /usr/local/fsl/bin/imglob


## FreeSurfer

RUN wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.0/freesurfer-linux-ubuntu20_amd64-7.4.0.tar.gz -O fs.tar.gz && \
    tar --no-same-owner -xzvf fs.tar.gz && \
    mv ./freesurfer /usr/local && \
    rm fs.tar.gz





# setup fs env


ENV PATH=/usr/local/freesurfer/bin:/usr/local/freesurfer/fsfast/bin:/usr/local/freesurfer/tktools:/usr/local/freesurfer/mni/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV FREESURFER_HOME=/usr/local/freesurfer

# Confirm freesurfer license.txt is inside your dockerfile folder
RUN mkdir /usr/local/freesurfer-license/
COPY ./license.txt /usr/local/freesurfer-license/

ENV FS_LICENSE=/usr/local/freesurfer-license/license.txt
ENV FREESURFER=/usr/local/freesurfer
ENV SUBJECTS_DIR=/usr/local/freesurfer/subjects
ENV LOCAL_DIR=/usr/local/freesurfer/local
ENV FSFAST_HOME=/usr/local/freesurfer/fsfast
ENV FMRI_ANALYSIS_DIR=/usr/local/freesurfer/fsfast
ENV FUNCTIONALS_DIR=/usr/local/freesurfer/sessions

# set default fs options
ENV FS_OVERRIDE=0
ENV FIX_VERTEX_AREA=""
ENV FSF_OUTPUT_FORMAT=nii.gz

# mni env requirements
ENV MINC_BIN_DIR=/usr/local/freesurfer/mni/bin
ENV MINC_LIB_DIR=/usr/local/freesurfer/mni/lib
ENV MNI_DIR=/usr/local/freesurfer/mni
ENV MNI_DATAPATH=/usr/local/freesurfer/mni/data
ENV MNI_PERL5LIB=/usr/local/freesurfer/mni/share/perl5
ENV PERL5LIB=/usr/local/freesurfer/mni/share/perl5





# Workbench
RUN git clone https://github.com/cblaine267/workbench-2.0.0.git \
    && mv ./workbench-2.0.0 /opt/workbench-2.0.0



ENV CARET7DIR=/opt/workbench-2.0.0/bin_rh_linux64

ENV PATH=${CARET7DIR}:${PATH}




#MSM

RUN mkdir -p /opt/msm/ && \
    curl -sSL https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_ubuntu_v3 -o /opt/msm/msm && \
    chmod 777 /opt/msm/msm

ENV MSMBINDIR=/opt/msm/msm
ENV PATH=${MSMBINDIR}:${PATH}

RUN ln -sf /opt/msm/msm /opt/msm/msm_centos

## HCP Pipeline
COPY HCPpipelines_4.7.0 /opt/HCPpipelines_4.7.0
RUN chmod -R a+rx /opt/HCPpipelines_4.7.0/FreeSurfer/custom
ENV PATH=/opt/HCPpipelines_4.7.0/FreeSurfer/custom:${PATH}

ENV HCPPIPEDIR=/opt/HCPpipelines_4.7.0
ENV PATH=${HCPPIPEDIR}:${PATH}





RUN mv /opt/workbench-2.0.0/libs_rh_linux64/libglapi.so.0 \
       /opt/workbench-2.0.0/libs_rh_linux64/libglapi.so.0.bundled





COPY docker/entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh
WORKDIR /data
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/bin/bash"]
