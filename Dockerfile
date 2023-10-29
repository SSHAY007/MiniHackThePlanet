FROM nvidia/cuda:11.4.3-devel-ubuntu20.04
LABEL authors="akshay"

ARG PYTHON_VERSION=3.8
ENV DEBIAN_FRONTEND=noninteractive
ENV SKILL_TRANSFER_HOME=skill_transfer_weights
ARG MUJOCO_FILEVERSION=mujoco210

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub

RUN apt-get update && apt-get install -yq \
        bison \
        build-essential \
        curl \
        flex \
        git \
    libbz2-dev \
    zlib1g-dev \
        ninja-build \
        wget
# zlib1g is for pip install -r requirements.txt for torchbeast
WORKDIR /opt/conda_setup

RUN curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
     chmod +x miniconda.sh && \
     ./miniconda.sh -b -p /opt/conda && \
     /opt/conda/bin/conda install -y python=$PYTHON_VERSION && \
     /opt/conda/bin/conda clean -ya
ENV PATH /opt/conda/bin:$PATH

RUN python -m pip install --upgrade pip ipython ipdb


# Installing mujoco for lower verions of gym
WORKDIR /root/.mujoco/${MUJOCO_FILEVERSION}
RUN curl -L -o mujoco.tar.gz https://github.com/google-deepmind/mujoco/releases/download/2.1.0/mujoco210-linux-x86_64.tar.gz && \
    tar -xzf mujoco.tar.gz --strip-components=1 --no-same-owner
ENV LD_LIBRARY_PATH /root/.mujoco/${MUJOCO_FILEVERSION}/bin:${LD_LIBRARY_PATH}
RUN apt-get install -y libosmesa6-dev patchelf && \
                pip install "cython<3"\
                gymnasium\
                mujoco-py\
                gymnasium[mujoco]

#installing minihack
WORKDIR /opt
RUN git clone https://github.com/facebookresearch/minihack.git && \
    #cmake on ubuntu not right version
    conda install cmake &&\
    cd minihack && \
    pip install '.[all]'

#installing plolybeast
RUN git clone https://github.com/facebookresearch/torchbeast.git && \
 conda create --name torchbeast && \
 activate torchbeast && \
 cd torchbeast && \
 git submodule update --init --recursive && \
 pip install -r requirements.txt && \
 pip install nest/ && \
 python setup.py install


WORKDIR /opt/minihack
RUN  pip install ".[polybeast]"

WORKDIR /workspace


RUN python -c "import mujoco_py"
CMD ["export SKILL_TRANSFER_HOME=${PWD}/${SKILL_TRANSFER_HOME}}"]
CMD ["export PATH=$PATH:~/.mujoco/${MUJOCO_FILEVERSION}/bin"]

CMD ["/bin/bash"]

# Docker commands:
#   docker rm nle -v
#   docker build -t nle -f docker/Dockerfile-focal .
#   docker run --gpus all --rm --name nle nle
# or
#   docker run --gpus all -it --entrypoint /bin/bash nle


