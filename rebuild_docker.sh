#!/usr/bin/env bash

HARD_RESET=""

# rm -rf orkaevolution
while [ "${1:-}" != "" ]; do
    case "${1}" in
        "--reset-hard" | "--hard-reset")
            shift
            HARD_RESET=true
            ;;
        *)
            shift
            ;;
    esac
    shift
done


[ "$HARD_RESET" == "true" ] && {
    echo rm -rf orkaevolution

    git clone git@i2git.cs.fau.de:orka/s2scompiler/orkaevolution.git
    pushd orkaevolution
    git submodule sync
    git submodule update --init --recursive
    popd
}


VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"

docker build \
       --build-arg USER_ID="$(id -u)" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t rose .
