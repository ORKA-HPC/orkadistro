#!/usr/bin/env bash

PREPARE=0
BUILD=0
INSTALL=0
RESET=0

PREFIX="${PREFIX:-/opt}"
INSTALL_LOC="$PREFIX/llp_rrzk"

while [ "${1:-}" != "" ]; do
    case "$1" in
        "--build" | "-b")
            BUILD=1
            ;;
        "--reset")
            RESET=1
            ;;
        "--install" | "-i")
            INSTALL=1
            ;;
        *)
            echo [ WARNING: unknown cli flag ]
            shift
            ;;
    esac
    shift
done

RRZK_LLP_DIRS=(
    rrzk_llp_repo
    rrzk_llp_artifacts
    rrzk_llp_build
)

function reset() {
    rm -rf "${RRZK_LLP_DIRS[@]}"
}

function build() (
    cd rrzk_llp_repo
    make clean
    make all
)

function prepare() {
    mkdir -p "${RRZK_LLP_DIRS[@]}"
}

function install() (
    echo [ Remove previous installation ]
    sudo rm -rf "$INSTALL_LOC"
    cd rrzk_llp_repo
    sudo mkdir -p "$INSTALL_LOC"
    for i in $(ls); do
        sudo cp -r "$i" "$INSTALL_LOC"/"$i"
    done
    sudo chmod -R 655 "$INSTALL_LOC"
)

prepare

[ "$RESET" = "1" ] && { reset || exit 1; }
[ "$BUILD" = "1" ] && { build || exit 1; }
[ "$INSTALL" = "1" ] && { install || exit 1; }

exit 0
