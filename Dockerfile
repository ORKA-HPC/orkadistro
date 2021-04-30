FROM ubuntu:bionic

# You can’t change ENV directly during the build
ARG ARG_MAX_CORES=""
ARG USER_ID=1000
ARG DEBIAN_FRONTEND=noninteractive # PLEASE APT SHUT uuuuuUP!!
ENV MAX_CORES=$ARG_MAX_CORES

SHELL [ "/bin/bash", "-c" ]

# ROSE dependencies
RUN apt-get update && apt-get install -y \
        git wget make automake libtool gcc g++ libboost-all-dev \
        flex bison ghostscript iputils-ping

## Devtools (including Ccache)
RUN apt-get update && \
        apt-get -y install ranger vim graphviz sudo ccache

# Ccache config
# create link dir for ccache
ARG ORKA_HPC_CCACHE_SYMLINK_DIR="/usr/ccache-symlinks"
RUN mkdir -p $ORKA_HPC_CCACHE_SYMLINK_DIR
RUN cd $ORKA_HPC_CCACHE_SYMLINK_DIR && \
        ln -s $(which ccache) gcc &&  \
        ln -s $(which ccache) g++
ENV ORKA_HPC_CCACHE_SYMLINK_DIR=$ORKA_HPC_CCACHE_SYMLINK_DIR
ENV CCACHE_DIR=/home/build/roserebuild/.ccache
ENV CCACHE_MAXSIZE=20G
ENV CCACHE_LIMIT_MULTIPLE=1.0

# Copy config files
COPY cfg_files/profile_d_ccache.sh /etc/profile.d/ccache.sh
COPY cfg_files/profile_d_xilinx_docker_path.sh /etc/profile.d/xilinx_docker_path.sh
COPY cfg_files/profile_d_fpgainfrastructure_paths.sh /etc/profile.d/fpgainfrastructure.sh

# Add build user
RUN echo "Set disable_coredump false" > /etc/sudo.conf
RUN sed -i '/NOPASSWD/s/\#//' /etc/sudoers
RUN ( echo && echo "build ALL=(ALL) NOPASSWD: ALL" ) >> /etc/sudoers
RUN useradd --shell /bin/bash -u $USER_ID -o -c "" build
WORKDIR /home/build
RUN chown -R build /home/build

# Add and apply configuration of ld
ADD cfg_files/ld.so.conf /etc/
RUN ldconfig

## setup PATH
ENV PATH="/usr/rose/bin:/usr/jre/bin:$PATH"

USER root
# tapasco runtime...
RUN apt-get update && \
        apt-get install -y \
        build-essential linux-headers-generic python3 \
        cmake libelf-dev git rpm cargo libncurses-dev
# ... and toolflow
RUN apt-get update && \
        apt-get install -y unzip git zip findutils curl default-jdk

# Install ORKA-HPC dependencies
USER root
RUN apt-get update -y && \
        apt-get install -y libtinyxml2-6 libtinyxml2-dev mlocate clang-format \
        tcl-dev uuid-runtime gdb libffi-dev cmake \
        libffi-dev freeglut3-dev libx11-dev
RUN updatedb

# Create mountpoint for Xilinx and binaries files to path
WORKDIR /usr/Xilinx

# Copy in config files
USER build
COPY cfg_files/rc.conf /home/build/.config/ranger/rc.conf

USER root
RUN chown -R build:build /home/build/

# Change user and set entry PWD
USER build
WORKDIR /home/build

COPY cfg_files/dockerbashrc /home/build/.profile
