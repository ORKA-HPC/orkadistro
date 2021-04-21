FROM ubuntu:bionic

# ARGS
# You can’t change ENV directly during the build
ARG ARG_MAX_CORES=""
ARG USER_ID=1000
# PLEASE APT SHUT uuuuuUP!!
ARG DEBIAN_FRONTEND=noninteractive

ENV MAX_CORES=$ARG_MAX_CORES

SHELL [ "/bin/bash", "-c" ]

# ROSE dependencies
RUN apt-get update
RUN apt-get install -y make vim cmake git wget gcc g++ gfortran gcc-7 g++-7 \
                       gfortran-7 libxml2-dev texlive git automake autoconf libtool \
                       flex bison openjdk-8-jdk debhelper devscripts \
                       ghostscript lsb-core python python-dev perl-doc graphviz
## Devtools
RUN apt-get -y install ranger vim
## HostBinary runtime and build dependency
RUN apt-get -y install libffi-dev freeglut3-dev libx11-dev

## use gcc 7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100
RUN update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-7 100

RUN apt-get -y update
RUN apt-get -y install git ccache

# create link dir for ccache
ARG ORKA_HPC_CCACHE_SYMLINK_DIR="/usr/ccache-symlinks"
RUN mkdir -p $ORKA_HPC_CCACHE_SYMLINK_DIR
RUN cd $ORKA_HPC_CCACHE_SYMLINK_DIR && \
        ln -s $(which ccache) gcc-7 &&  \
        ln -s $(which ccache) g++-7

ENV ORKA_HPC_CCACHE_SYMLINK_DIR=$ORKA_HPC_CCACHE_SYMLINK_DIR

# ccache config
ENV CCACHE_DIR=/home/build/roserebuild/.ccache
ENV CCACHE_MAXSIZE=20G
ENV CCACHE_LIMIT_MULTIPLE=1.0

COPY cfg_files/profile_d_ccache.sh /etc/profile.d/ccache.sh
COPY cfg_files/profile_d_xilinx_docker_path.sh /etc/profile.d/xilinx_docker_path.sh
COPY cfg_files/profile_d_fpgainfrastructure_paths.sh /etc/profile.d/fpgainfrastructure.sh

# Add build user
RUN apt-get install -y sudo
RUN echo "Set disable_coredump false" > /etc/sudo.conf
RUN sed -i '/NOPASSWD/s/\#//' /etc/sudoers
RUN ( echo && echo "build ALL=(ALL) NOPASSWD: ALL" ) >> /etc/sudoers
RUN useradd --shell /bin/bash -u $USER_ID -o -c "" build
WORKDIR /home/build
RUN chown -R build /home/build

# Fetch and build boost
WORKDIR /usr/src
COPY boost-1.67.0.tar.bz2 boost-1.67.0.tar.bz2
RUN tar xf boost-1.67.0.tar.bz2 \
    && rm -f boost-1.67.0.tar.bz2

WORKDIR /usr/src/boost_1_67_0
RUN ./bootstrap.sh --prefix=/usr/lib/boost \
    --with-libraries=chrono,date_time,filesystem,iostreams,program_options,random,regex,serialization,signals,system,thread,wave || cat ./bootstrap.log
RUN ./b2 -j8 -sNO_BZIP2=1 install

# Add configuration of ld
ADD cfg_files/ld.so.conf /etc/
## apply ld configuration
RUN ldconfig
## setup PATH
ENV PATH="/usr/rose/bin:/usr/jre/bin:$PATH"

RUN apt-get update
RUN apt-get install libicu60

USER root

# tapasco runtime...
RUN apt-get install -y \
        build-essential linux-headers-generic python3 \
        cmake libelf-dev git rpm cargo libncurses-dev

# ... and toolflow
RUN apt-get install -y \
    unzip git zip findutils curl default-jdk

# Install ORKA-HPC dependencies
USER root
RUN apt-get update -y
RUN apt-get install -y libtinyxml2-6 libtinyxml2-dev mlocate clang-format
RUN apt-get install -y tcl-dev uuid-runtime gdb libffi-dev
RUN updatedb

ENV LD_LIBRARY_PATH="/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/:$LD_LIBRARY_PATH"

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
