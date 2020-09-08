FROM ubuntu:bionic

# ARGS
# You can’t change ENV directly during the build
ARG VIVADO_VERSION=2018.2
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
                       ghostscript lsb-core python perl-doc graphviz
## Devtools
RUN apt-get -y install ranger vim

## use gcc 7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100
RUN update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-7 100

# This stupid workaround has to be included because
# we need git submodule _set-url_ in script rebuild.sh ...
#        Sadly git from mainline 18.04 is too old for this
# If one day this PPA fails, you'll have to sed -i the
# .gitmodules in /home/build/src/rose-git/.
# ([submodule "src/frontend/CxxFrontend/EDG"] to be specific.)
RUN apt-get -y install software-properties-common
RUN apt-add-repository ppa:git-core/ppa -y
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

# Add build user
RUN apt-get install -y sudo
RUN echo "Set disable_coredump false" > /etc/sudo.conf
RUN sed -i '/NOPASSWD/s/\#//' /etc/sudoers
RUN ( echo && echo "build ALL=(ALL) NOPASSWD: ALL" ) >> /etc/sudoers
RUN useradd --shell /bin/bash -u $USER_ID -o -c "" build
WORKDIR /home/build
RUN chown -R build /home/build
# RUN chmod -R 755 /home/build

# Fetch and build boost
WORKDIR /usr/src
RUN wget -O boost-1.67.0.tar.bz2 \
    http://sourceforge.net/projects/boost/files/boost/1.67.0/boost_1_67_0.tar.bz2/download \
    && tar xf boost-1.67.0.tar.bz2 \
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

# Build and Install tapasco requirements
RUN apt-get install -y \
    build-essential linux-headers-generic python \
    cmake libelf-dev libncurses-dev git rpm \
    unzip git zip findutils curl

USER build
WORKDIR /home/build
# ARG TAPASCO_TAG=2019.10
# RUN git clone --branch \
#         $TAPASCO_TAG https://github.com/esa-tu-darmstadt/tapasco.git

## build tapasco toolflow
# USER build
# RUN mkdir -p tapasco-workspace
# WORKDIR /home/build/tapasco-workspace
# RUN bash -c '../tapasco/tapasco-init.sh'
# RUN bash -c '. tapasco-setup.sh && tapasco-build-toolflow'

## build tapasco libs
# RUN source tapasco-setup.sh && cd ../tapasco/runtime && { cmake . && make -j$MAX_CORES; }
# USER root
# RUN source tapasco-setup.sh && cd ../tapasco/runtime && make install

## Make sure tapasco is in PATH (requires a login shell)!
# WORKDIR /home/build/tapasco-workspace
# RUN cp tapasco-setup.sh /etc/profile.d/tapasco.sh

# Install ORKA-HPC dependencies
USER root
RUN apt-get update -y
RUN apt-get install -y libtinyxml2-6 libtinyxml2-dev mlocate clang-format
RUN apt-get install -y tcl-dev uuid-runtime
RUN updatedb

ENV LD_LIBRARY_PATH="/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/:$LD_LIBRARY_PATH"

# Create mountpoint for Xilinx and binaries files to path
WORKDIR /usr/Xilinx

# Add Xilinx Tools to the path
ENV PATH="/usr/Xilinx/Vivado/$VIVADO_VERSION/bin:$PATH"

# Install XILINX license server
ENV XILINXD_LICENSE_FILE=2100@scotty.e-technik.uni-erlangen.de

# Copy in config files
USER build
COPY cfg_files/rc.conf /home/build/.config/ranger/rc.conf


USER root
RUN chown -R build:build /home/build/

# Change user and set entry PWD
USER build
WORKDIR /home/build

COPY cfg_files/dockerbashrc /home/build/.profile
