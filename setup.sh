#!/usr/bin/env bash

CLEAN_BUILD_ROSE=0
CLEAN_BUILD_ORKA=0
CLEAN_BUILD_TAPASCO=0
PREPARE_ROSE=0
INSTALL_ROSE=0
PREPARE_ORKA_DISTRO=0
BUILD_DOCKER=0

MAX_CORES="${MAX_CORES:-4}"
echo Running with MAX_CORES = $MAX_CORES

function testPrerequisiteChecker() {
    function fnocker() { echo Docker version 13.03.8; }
    function fnick() { echo git version 2.25.8; }
    shopt -s expand_aliases
    alias git=fnick
    alias docker=fnocker
}

# testPrerequisiteChecker

function failIfWrongDockerVersion() {
    local full_docker_version="$(docker --version | cut -d" " -f 3)"
    local major_docker_version="$(echo "$full_docker_version" | cut -d"." -f 1)"

    local err_string_docker="You need at least version 19 of docker or higher"
    if [ "$major_docker_version" -lt 19 ]; then
        echo $err_string_docker
        exit 1
    fi
}

function failIfWrongGitVersion() {
    local full_git_version="$(git --version | cut -d" " -f 3)"
    local major_git_version="$(echo "$full_git_version" | cut -d"." -f 1)"
    local minor_git_version="$(echo "$full_git_version" | cut -d"." -f 2)"

    local err_string="You need at least version 2.25 of git"
    if [ "$major_git_version" -lt 2 ]; then
        echo $err_string
        exit 1
    fi

    if [ "$minor_git_version" -lt 25 ]; then
        echo $err_string
        exit 1
    fi
}

function checkPrerequisites() {
    failIfWrongGitVersion
    failIfWrongDockerVersion
}

checkPrerequisites

while [ "${1:-}" != "" ]; do
    case "$1" in
        "--clean-build-rose" | "-c")
            CLEAN_BUILD_ROSE=1
            ;;
        "--install-rose" | "-i")
            INSTALL_ROSE=1
            ;;
        "--clean-build-tapasco")
            CLEAN_BUILD_TAPASCO=1
            ;;
        "--clean-build-orka")
            CLEAN_BUILD_ORKA=1
            ;;
        "--after-pull")
            INSTALL_ROSE=1
            CLEAN_BUILD_TAPASCO=1
            CLEAN_BUILD_ORKA=1
            ;;
        "--init")
            CLEAN_BUILD_ROSE=1
            CLEAN_BUILD_TAPASCO=1
            CLEAN_BUILD_ORKA=1
            PREPARE_ROSE=1
            PREPARE_ORKA_DISTRO=1
            INSTALL_ROSE=1
            BUILD_DOCKER=1
            ;;
        "--prepare-rose")
            PREPARE_ROSE=1
            ;;
        "--prepare-orkadistro")
            PREPARE_ORKA_DISTRO=1
            ;;
        "--build-docker")
            BUILD_DOCKER=1
            ;;
        "--help" | "-h")
            echo "--prepare-rose"
            echo "--clean-build-rose"
            echo "--clean-build-orka"
            echo "--clean-build-tapasco"
            echo "--install-rose"
            echo "--prepare-orkadistro"
            echo "--build-docker"
            exit 0
            ;;
        *)
            ;;
    esac
    shift
done


function prepareOrkaDistro() {
    echo [submodule setup]
    git submodule sync --recursive || return 1
    git submodule update --init --recursive || return 1
}

function buildDocker() {
    echo [build docker image]
    ./rebuild_docker.sh
}

# function prepareRose() (
#     echo [prepare rose]
#     cd roserebuild && ./rebuild.sh --prepare
# )

function cleanBuildRose() {
    echo [clean build rose]
    ./run_docker.sh -r --exec-non-interactive \
                    "cd roserebuild; MAX_CORES=${MAX_CORES} ./rebuild.sh --clean -b"
}

function installRose() {
    echo [install rose]
    ./run_docker.sh -r --exec-non-interactive \
                    "cd roserebuild; MAX_CORES=${MAX_CORES} ./rebuild.sh -i"
}

function cleanBuildOrka() {
    echo [build orkaevolution]
    ./run_docker.sh -r --exec-non-interactive \
                    "cd orkaevolution; cmake . ; make clean ; make -j"
}

function cleanBuildTapasco() {
    echo [build tapasco]
    ./run_docker.sh -r --exec-non-interactive \
                    'cd && mkdir -p tapasco-workspace &&
                         cd tapasco-workspace &&
                         ../tapasco/tapasco-init.sh' || return 1

    ./run_docker.sh -r --exec-non-interactive \
                    'cd && cd tapasco-workspace &&
                    . tapasco-setup.sh && tapasco-build-toolflow' || return 1

    ./run_docker.sh -r --exec-non-interactive \
                    "cd && cd tapasco-workspace &&
                    . tapasco-setup.sh && cd ../tapasco/runtime &&
                    { cmake -DCMAKE_C_FLAGS='-fPIC' . && make -j$MAX_CORES; }" || return 1

    ./run_docker.sh -r --exec-non-interactive \
                    'cd && cd tapasco-workspace &&
                    sudo bash -c ". tapasco-setup.sh &&
                    cd ../tapasco/runtime && make install"' || return 1

    ./run_docker.sh -r --exec-non-interactive \
                    'cd && cd tapasco-workspace &&
                    sudo cp tapasco-setup.sh /etc/profile.d/tapasco.sh' || return 1
}

[ "$PREPARE_ORKA_DISTRO" = "1" ] && { prepareOrkaDistro || exit 1; }

# [ "$PREPARE_ROSE" = 1 ] && { prepareRose || exit 1; }
[ "$BUILD_DOCKER" = "1" ] && { buildDocker || exit 1; }

[ "$CLEAN_BUILD_ROSE" = 1 ] && { cleanBuildRose || exit 1; }
[ "$INSTALL_ROSE" = 1 ] && { installRose || exit 1; }
[ "$CLEAN_BUILD_TAPASCO" = 1 ] && { cleanBuildTapasco || exit 1; }
[ "$CLEAN_BUILD_ORKA" = 1 ] && { cleanBuildOrka || exit 1; }

exit 0
