FROM ubuntu:bionic AS development

ARG ARG_MAX_CORES=""
ARG USER_ID=1000
ARG DEBIAN_FRONTEND=noninteractive
ENV MAX_CORES=$ARG_MAX_CORES

SHELL [ "/bin/bash", "-c" ]

## Packages
# ROSE dependencies
USER root
RUN apt-get update && apt-get install -y \
        git wget make automake libtool gcc g++ libboost-all-dev \
        flex bison ghostscript iputils-ping
## Devtools (including Ccache)
RUN apt-get update && \
        apt-get -y install ranger vim graphviz sudo ccache
# tapasco runtime...
RUN apt-get update && \
        apt-get install -y \
        build-essential linux-headers-generic python3 \
        cmake libelf-dev git rpm cargo libncurses-dev
# ... and toolflow
RUN apt-get update && \
        apt-get install -y unzip git zip findutils curl default-jdk
# Install ORKA-HPC dependencies
RUN apt-get update -y && \
        apt-get install -y libtinyxml2-6 libtinyxml2-dev mlocate clang-format \
        tcl-dev uuid-runtime gdb libffi-dev cmake \
        libffi-dev freeglut3-dev libx11-dev
RUN updatedb

## Ccache config
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

# Add build user by using the current user's ID
# This enables seamless data sharing via the volume mounts
RUN echo "Set disable_coredump false" > /etc/sudo.conf
RUN sed -i '/NOPASSWD/s/\#//' /etc/sudoers
RUN ( echo && echo "build ALL=(ALL) NOPASSWD: ALL" ) >> /etc/sudoers
RUN useradd --shell /bin/bash -u $USER_ID -o -c "" build
# WORKDIR /home/build
# RUN chown -R build /home/build

## System files
# Copy system config files
COPY cfg_files/profile_d_ccache.sh /etc/profile.d/ccache.sh
COPY cfg_files/profile_d_xilinx_docker_path.sh /etc/profile.d/xilinx_docker_path.sh
COPY cfg_files/profile_d_fpgainfrastructure_paths.sh /etc/profile.d/fpgainfrastructure.sh
# Add and apply configuration of ld
COPY cfg_files/ld.so.conf /etc/
RUN ldconfig
# Copy user config files
USER build
COPY --chown=build:build cfg_files/rc.conf /home/build/.config/ranger/rc.conf
COPY --chown=build:build cfg_files/dockerbashrc /home/build/.profile

## Setup PATH
ENV PATH="/usr/rose/bin:/usr/jre/bin:$PATH"

# USER root
# RUN chown -R build:build /home/build/

# Change user and set entry PWD
USER build
WORKDIR /home/build

## Stage 2
FROM development AS development_closure

USER root
COPY --chown=build:build fpgainfrastructure /home/build/fpgainfrastructure
COPY --chown=build:build orkaevolution /home/build/orkaevolution
COPY --chown=build:build roserebuild /home/build/roserebuild
COPY --chown=build:build tapasco /home/build/tapasco

# install rose
USER build
WORKDIR /home/build/roserebuild
RUN ./rebuild.sh -i
WORKDIR /home/build
RUN rm -rf roserebuild

# install tapasco
WORKDIR /home/build
RUN mkdir tapasco-artifacts
RUN mkdir tapasco-workspace
RUN cd tapasco-workspace && ../tapasco/tapasco-init.sh
RUN cd tapasco-workspace && . tapasco-setup.sh \
        && cd ${TAPASCO_HOME_TOOLFLOW}/scala \
        && ./gradlew buildDEB \
        && cp build/distributions/*.deb ~/tapasco-artifacts/toolflow.deb \
        && sudo dpkg -i build/distributions/*.deb
RUN cd tapasco-workspace && . tapasco-setup.sh \
        && tapasco-build-libs --skip_driver
RUN cd tapasco-workspace && cd build* \
        && cpack -G DEB \
        && cp *.deb ~/tapasco-artifacts/runtime.deb \
        && sudo dpkg -i *.deb
RUN cd && cd tapasco-workspace \
        && sudo cp tapasco-setup.sh /etc/profile.d/tapasco.sh

## Stage 3
FROM development AS production

USER root
COPY --from=development_closure /usr/rose-git/ /usr/rose-git/

COPY --from=development_closure /etc/profile.d/tapasco.sh /etc/profile.d/tapasco.sh
COPY --from=development_closure /home/build/tapasco-artifacts /home/build/tapasco-artifacts
RUN sudo dpkg -i /home/build/tapasco-artifacts/toolflow.deb
RUN sudo dpkg -i /home/build/tapasco-artifacts/runtime.deb
RUN rm -rf /home/build/tapasco-artifacts/
