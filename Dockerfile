FROM ubuntu:bionic

# ARGS
# You can’t change ENV directly during the build
ARG VIVADO_VERSION=2018.2
ARG ARG_EDG_ACCESS_TOKEN=fail
ARG ARG_ROSE_ACCESS_TOKEN=fail
ARG USER_ID=1000
ARG IMAGE_TYPE=fail
# PLEASE APT SHUT uuuuuUP!!
ARG DEBIAN_FRONTEND=noninteractive

ENV EDG_ACCESS_TOKEN=$ARG_EDG_ACCESS_TOKEN
ENV ROSE_ACCESS_TOKEN=$ARG_ROSE_ACCESS_TOKEN


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




# Build ROSE source code
WORKDIR /usr/src
COPY roserebuild/rebuild.sh /usr/src/rebuild.sh
RUN [ "$IMAGE_TYPE" == "dev-edg" ] \
        && { \
        ( mkdir -p rose && cd rose \
        && PREFIX="/usr/rose" ./rebuild.sh --prepare --build --install ; ) ;\
        ( mkdir -p rose-git && cd rose-git && \
        PREFIX="/usr/rose-git" ./rebuild.sh --prepare \
        --build --install --with-edg-repo --reset; ) \
        } \
        || PREFIX="/usr/rose" ./rebuild.sh --prepare --build --install

RUN apt-get update
RUN apt-get install libicu60
RUN sed -i '1s/^/#define __builtin_bswap16 __bswap_constant_16\n/' /usr/rose/include/edg/g++-7_HEADERS/hdrs7/bits/byteswap.h

# build ROSE
# WORKDIR /usr/src/rose-build
# RUN CC=gcc-7 CXX=g++-7 CXXFLAGS= ../rose/configure --prefix=/usr/rose \
#     --oldincludedir=/usr/include --with-C_OPTIMIZE=-O0 --with-CXX_OPTIMIZE=-O0 \
#     --with-C_DEBUG='-g' --with-CXX_DEBUG='-g' --with-boost=/usr/lib/boost/ \
#     --with-boost-libdir=/usr/lib/boost/lib/ --with-gfortran=/usr/bin/gfortran-7 \
#     --enable-languages=c,c++,fortran --enable-projects-directory \
#     --enable-edg_version=5.0


# Add build user
RUN apt-get install -y sudo
RUN echo "Set disable_coredump false" > /etc/sudo.conf
RUN sed -i '/NOPASSWD/s/\#//' /etc/sudoers
RUN echo "\nbuild ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers
RUN useradd --shell /bin/bash -u $USER_ID -o -c "" build
WORKDIR /home/build
RUN chown -R build /home/build
RUN chmod -R 755 /home/build

# Build and Install tapasco
RUN apt-get install -y \
    build-essential linux-headers-generic python \
    cmake libelf-dev libncurses-dev git rpm \
    unzip git zip findutils curl
USER build
WORKDIR /home/build
ARG TAPASCO_TAG=2019.10
RUN git clone --branch $TAPASCO_TAG https://github.com/esa-tu-darmstadt/tapasco.git

## build tapasco toolflow
USER build
RUN mkdir -p tapasco-workspace
WORKDIR /home/build/tapasco-workspace
RUN bash -c '../tapasco/tapasco-init.sh'
RUN bash -c '. tapasco-setup.sh && tapasco-build-toolflow'

## build tapasco libs
RUN source tapasco-setup.sh && cd ../tapasco/runtime && { cmake . && make ; }
USER root
RUN source tapasco-setup.sh && cd ../tapasco/runtime && make install

## Make sure tapasco is in PATH (requires a login shell)!
WORKDIR /home/build/tapasco-workspace
RUN cp tapasco-setup.sh /etc/profile.d/tapasco.sh



# Install ORKA-HPC dependencies
RUN apt-get update -y
RUN apt-get install -y libtinyxml2-6 libtinyxml2-dev mlocate clang-format
RUN apt-get install -y tcl-dev uuid-runtime
RUN updatedb

ENV LD_LIBRARY_PATH="/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/:$LD_LIBRARY_PATH"

# TAPASCO_PREFIX=/usr/local/ ORKA=../../orkaEvolution make -f driver.mk hostBinary

# Create mountpoint for Xilinx and binaries files to path
WORKDIR /usr/Xilinx

# Add Xilinx Tools to the path
ENV PATH="/usr/Xilinx/Vivado/$VIVADO_VERSION/bin:$PATH"

# Install XILINX license server
ENV XILINXD_LICENSE_FILE=2100@scotty.e-technik.uni-erlangen.de

# Copy in config files
COPY cfg_files/rc.conf /home/build/.config/ranger/rc.conf

# Change user and set entry PWD
USER build
WORKDIR /home/build
