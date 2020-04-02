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
    echo rm -rf roserebuild
    echo rm -rf fpgainfrastructure
    echo rm -rf vivado-boards
}

function init_subs() {
    git submodule sync
    git submodule update --init --recursive
}

[ ! -d rebuildrose ] && {
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


VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"

docker build \
       --build-arg USER_ID="$(id -u)" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t rose .
