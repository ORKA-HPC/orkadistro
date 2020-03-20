FROM ubuntu:bionic

# (1) Build and install ROSE
RUN apt-get update
RUN apt-get install -y make vim cmake git wget gcc g++ gfortran gcc-7 g++-7 \
                       gfortran-7 libxml2-dev texlive git automake autoconf libtool \
                       flex bison openjdk-8-jdk debhelper devscripts \
                       ghostscript lsb-core python perl-doc graphviz

# use gcc 7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100
RUN update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-7 100

# fetch boost source
WORKDIR /usr/src
RUN wget -O boost-1.67.0.tar.bz2 \
    http://sourceforge.net/projects/boost/files/boost/1.67.0/boost_1_67_0.tar.bz2/download \
    && tar xf boost-1.67.0.tar.bz2 \
    && rm -f boost-1.67.0.tar.bz2

# build boost
WORKDIR /usr/src/boost_1_67_0
RUN ./bootstrap.sh --prefix=/usr/lib/boost \
    --with-libraries=chrono,date_time,filesystem,iostreams,program_options,random,regex,serialization,signals,system,thread,wave || cat ./bootstrap.log
RUN ./b2 -j8 -sNO_BZIP2=1 install

# prepare ROSE source code
WORKDIR /usr/src
RUN git clone https://github.com/rose-compiler/rose.git
RUN cd rose && ./build

# add configuration of ld
ADD ld.so.conf /etc/

# apply ld configuration
RUN ldconfig


# build ROSE
WORKDIR /usr/src/rose-build
RUN CC=gcc-7 CXX=g++-7 CXXFLAGS= ../rose/configure --prefix=/usr/rose \
    --oldincludedir=/usr/include --with-C_OPTIMIZE=-O0 --with-CXX_OPTIMIZE=-O0 \
    --with-C_DEBUG='-g' --with-CXX_DEBUG='-g' --with-boost=/usr/lib/boost/ \
    --with-boost-libdir=/usr/lib/boost/lib/ --with-gfortran=/usr/bin/gfortran-7 \
    --enable-languages=c,c++,fortran --enable-projects-directory \
    --enable-edg_version=5.0

# feel free to change the -j value
RUN make core -j
RUN make install-core -j

# setup PATH
ENV PATH="/usr/rose/bin:/usr/jre/bin:$PATH"

RUN apt-get update
RUN apt-get install libicu60

RUN sed -i '1s/^/#define __builtin_bswap16 __bswap_constant_16\n/' /usr/rose/include/edg/g++-7_HEADERS/hdrs7/bits/byteswap.h

# (2) Devtools
RUN apt-get -y install ranger vim

# (4) Add build user
ARG USER_ID=1000
RUN apt-get install -y sudo
RUN echo "Set disable_coredump false" > /etc/sudo.conf
RUN sed -i '/NOPASSWD/s/\#//' /etc/sudoers
RUN echo -e "\nbuild ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN useradd --shell /bin/bash -u $USER_ID -o -c "" build
WORKDIR /home/build
RUN chown -R build /home/build
RUN chmod -R 755 /home/build

# (5) Build and Install tapasco
RUN apt-get install -y \
    build-essential linux-headers-generic python \
    cmake libelf-dev libncurses-dev git rpm \
    unzip git zip findutils curl
USER build
WORKDIR /home/build
ARG TAPASCO_TAG=2019.10
RUN git clone --branch $TAPASCO_TAG https://github.com/esa-tu-darmstadt/tapasco.git

# build tapasco toolflow
USER build
RUN mkdir -p tapasco-workspace
WORKDIR /home/build/tapasco-workspace
RUN bash -c '../tapasco/tapasco-init.sh'
RUN bash -c '. tapasco-setup.sh && tapasco-build-toolflow'

## build tapasco libs
RUN bash -c '. tapasco-setup.sh && cd ../tapasco/runtime && { cmake . && make ; } '
USER root
RUN bash -c '. tapasco-setup.sh && cd ../tapasco/runtime && make install'

## Make sure tapasco is in PATH (requires a login shell)!
WORKDIR /home/build/tapasco-workspace
RUN cp tapasco-setup.sh /etc/profile.d/tapasco.sh

# (6) Install ORKA-HPC dependencies
RUN apt-get install -y libtinyxml2-6 libtinyxml2-dev mlocate clang-format
RUN apt-get install -y tcl-dev # fpgainfrastructure dependencies aka. AP2
RUN updatedb

ENV LD_LIBRARY_PATH="/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/:$LD_LIBRARY_PATH"

# TAPASCO_PREFIX=/usr/local/ ORKA=../../orkaEvolution make -f driver.mk hostBinary

# (3) Create mountpoint for Xilinx and binaries files to path
WORKDIR /usr/Xilinx
ARG VIVADO_VERSION=2018.2
ENV PATH="/usr/Xilinx/Vivado/$VIVADO_VERSION/bin:$PATH"

# (7) Install XILINX license server
ENV XILINXD_LICENSE_FILE=2100@scotty.e-technik.uni-erlangen.de


USER build
WORKDIR /home/build
