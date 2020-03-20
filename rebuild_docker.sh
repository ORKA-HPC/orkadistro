#!/usr/bin/env bash

rm -rf orkaevolution

git clone git@i2git.cs.fau.de:orka/s2scompiler/orkaevolution.git
pushd orkaevolution
git submodule sync
git submodule update --init --recursive
popd

VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"

docker build \
       --build-arg USER_ID="$(id -u)" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t rose .
