#!/usr/bin/env bash

BUILD=0
RESET=0
INSTALL=0

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

TAPASCO_DIRS=(
    tapasco_llp_artifacts
    tapasco_llp_build
    tapasco_llp_repo
)

function prepare() {
    mkdir -p "${TAPASCO_DIRS[@]}"
}

function buildToolflow() (
    cd tapasco_llp_build
    ../tapasco_llp_repo/tapasco-init.sh
    . tapasco-setup.sh
    pushd ${TAPASCO_HOME_TOOLFLOW}/scala
    ./gradlew installDist || return 1
    ./gradlew buildDEB || return 1
    popd
    cp ${TAPASCO_HOME_TOOLFLOW}/scala/build/distributions/*.deb \
       ../tapasco_llp_artifacts/toolflow.deb || return 1
)

function buildRuntime() (
    cd tapasco_llp_build
    ../tapasco_llp_repo/tapasco-init.sh
    . tapasco-setup.sh
    tapasco-build-libs --mode=release --skip_driver || return 1
    pushd build*
    cpack -P tapasco-runtime -G DEB || return 1
    popd
    cp build*/*.deb ../tapasco_llp_artifacts/runtime.deb || return 1
)

function cleanup() (
    rm -rf tapasco_llp_build/
)

function buildConfigFile() (
    pushd tapasco_llp_build
    ../tapasco_llp_repo/tapasco-init.sh
    . tapasco-setup.sh
    popd
    cd tapasco_llp_artifacts
    ${TAPASCO_HOME_TOOLFLOW}/os-package/tapasco-init-toolflow.sh
)

function build() {
    buildToolflow || return 1
    buildRuntime || return 1
    buildConfigFile || return 1
    return 0;
}

function reset() {
    rm -rf "${TAPASCO_DIRS[@]}"
}

function install() (
    cd tapasco_llp_artifacts
    sudo dpkg -i runtime.deb || return 1
    sudo dpkg -i toolflow.deb || return 1
    sudo install tapasco-setup-toolflow.sh /etc/profile.d/tapasco.sh
)

cleanup
prepare

[ "$BUILD" = "1" ] && { build || exit 1; }
[ "$RESET" = "1" ] && { reset || exit 1; }
[ "$INSTALL" = "1" ] && { install || exit 1; }

exit 0
