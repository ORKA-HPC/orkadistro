#!/usr/bin/env bash

DOCKER_TAG="${DOCKER_TAG:-"i2git.cs.fau.de:5005/orka/dockerfiles/orkadistro"}"
VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"
BUILD_ORKA_ROSE="${BUILD_ORKA_ROSE:-false}"

HARD_RESET=""
PUSH_IMAGE=""

# rm -rf orkaevolution
while [ "${1:-}" != "" ]; do
    case "${1}" in
        "--reset-hard" | "--hard-reset")
            shift
            HARD_RESET=true
            ;;
        "--push-image" | "-p")
            shift
            PUSH_IMAGE=true
            ;;
        "--build-orka-rose" | "-o")
            shift
            BUILD_ORKA_ROSE=true
            ;;
        *)
            shift
            ;;
    esac
    shift
done


[ "$HARD_RESET" == "true" ] && {
    echo rm -rf orkaevolution
    echo rm -rf roserebuild
    echo rm -rf fpgainfrastructure
    echo rm -rf vivado-boards
}

function init_subs() {
    git submodule sync
    git submodule update --init --recursive
}

[ ! -d roserebuild ] && {
    git submodule add git@i2git.cs.fau.de:personalorka/utilities/roserebuild.git
}

[ ! -d orkaevolution ] && {
    git submodule add git@i2git.cs.fau.de:orka/s2scompiler/orkaevolution.git
    (
        cd orkaevolution
        init_subs
    )
}

[ ! -d fpgainfrastructure ] && {
    git submodule add git@i2git.cs.fau.de:orka/vivado/fpgainfrastructure.git
    (
        cd fpgainfrastructure
        init_subs
    )
}

[ ! -d vivado-boards ] && {
    git submodule add https://github.com/Digilent/vivado-boards
}

docker build --build-arg USER_ID="$(id -u)" \
       --build-arg BUILD_ORKA_ROSE="$BUILD_ORKA_ROSE" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t "$DOCKER_TAG" .


if [ "$PUSH_IMAGE" == "true" ]; then
    docker push i2git.cs.fau.de:5005/orka/dockerfiles/orkadistro
fi
