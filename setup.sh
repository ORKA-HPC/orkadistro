#!/usr/bin/env bash

PREPARE_ORKA_DISTRO=0
BUILD_DOCKER=0

CLEAN_BUILD_ROSE=0
CLEAN_BUILD_TAPASCO=0
CLEAN_BUILD_RRZK=0
CLEAN_BUILD_ORKA=0

INSTALL_ROSE=0
INSTALL_TAPASCO=0
INSTALL_RRZK=0
INSTALL_ORKA=0

NO_EDG_REPO="${NO_EDG_REPO:-0}"
MAX_CORES="${MAX_CORES:-4}"
echo Running with $MAX_CORES cores

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
    if [ "$major_git_version" -lt 1 ]; then
        echo $err_string
        exit 1
    fi

    if [ "$minor_git_version" -lt 9 ]; then
        echo $err_string
        exit 1
    fi
}

function checkPrerequisites() {
    failIfWrongGitVersion
    failIfWrongDockerVersion
}

checkPrerequisites

function tryToShutdownContainer() {
  echo You must stop and remove the docker container
  echo before you can update orkadistro.
  echo Hit Enter if this is OK!
  read i
  ./run_docker.sh --stop-and-remove
}

while [ "${1:-}" != "" ]; do
    case "$1" in
        "--clean-build-rose" | "-c")
            CLEAN_BUILD_ROSE=1
            ;;
        "--clean-build-tapasco")
            CLEAN_BUILD_TAPASCO=1
            ;;
        "--clean-build-rrzk")
            CLEAN_BUILD_RRZK=1
            ;;
        "--clean-build-orka")
            CLEAN_BUILD_ORKA=1
            ;;
        "--install-rose" | "-i")
            INSTALL_ROSE=1
            ;;
        "--install-tapasco")
            INSTALL_TAPASCO=1
            ;;
        "--install-rrzk")
            INSTALL_RRZK=1
            ;;
        "--install-orka")
            INSTALL_ORKA=1
            ;;
        "--after-pull")
            tryToShutdownContainer
            BUILD_DOCKER=1
            INSTALL_ROSE=1
            INSTALL_TAPASCO=1
            INSTALL_RRZK=1
            INSTALL_ORKA=1
            ;;
        "--clean-after-pull")
            tryToShutdownContainer
            PREPARE_ORKA_DISTRO=1
            BUILD_DOCKER=1
            CLEAN_BUILD_ROSE=1
            CLEAN_BUILD_TAPASCO=1
            CLEAN_BUILD_RRZK=1
            CLEAN_BUILD_ORKA=1
            INSTALL_ROSE=1
            INSTALL_TAPASCO=1
            INSTALL_RRZK=1
            INSTALL_ORKA=1
            ;;
        "--init")
            PREPARE_ORKA_DISTRO=1
            BUILD_DOCKER=1
            CLEAN_BUILD_ROSE=1
            CLEAN_BUILD_TAPASCO=1
            CLEAN_BUILD_ORKA=1
            CLEAN_BUILD_RRZK=1
            INSTALL_ROSE=1
            INSTALL_TAPASCO=1
            INSTALL_RRZK=1
            INSTALL_ORKA=1
            ;;
        "--prepare-orkadistro")
            PREPARE_ORKA_DISTRO=1
            ;;
        "--build-docker")
            BUILD_DOCKER=1
            ;;
        "--help" | "-h")
            echo "--prepare-orkadistro"
            echo "--build-docker"
            echo "--clean-build-rose"
            echo "--clean-build-tapasco"
            echo "--clean-build-rrzk"
            echo "--clean-build-orka"
            echo "--install-rose"
            echo "--install-tapasco"
            echo "--install-rrzk"
            echo "--install-orka"
            exit 0
            ;;
        *)
            ;;
    esac
    shift
done

function prepareOrkaDistro() {
    echo [submodule setup]
    local additionalGitFlags=()
    [ "$NO_RRZK_LLP" = 1 ] && additionalGitFlags+=( -c submodule."llp_rrzk/rrzk_llp_repo".update=none )
    [ "$NO_EDG_REPO" = 1 ] && additionalGitFlags+=( -c submodule."src/frontend/CxxFrontend/EDG".update=none )
    git "${additionalGitFlags[@]}" submodule sync --recursive || return 1
    git "${additionalGitFlags[@]}" submodule update --init --recursive || return 1
}

function buildDocker() {
    echo [build docker image]
    ./rebuild_docker.sh
}

function installRose() {
    echo [install rose]
    ./run_docker.sh -r --exec-non-interactive \
                    "cd roserebuild; MAX_CORES=${MAX_CORES} ./rebuild.sh -i"
}

function cleanBuildRrzk() {
    echo [clean build RRZK LLP]
    ./run_docker.sh -r --exec-non-interactive \
                 "cd && cd llp_rrzk && ./rebuild.sh -b"
}

function installRrzk() {
    echo [install RRZK LLP]
    ./run_docker.sh -r --exec-non-interactive \
                 "cd && cd llp_rrzk && ./rebuild.sh -i"
}

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
    echo [build ORKA]
    ./run_docker.sh -r --exec-non-interactive \
                    "cd compiler; ./build_clean.sh"
}

function installOrka() {
    echo [install ORKA]
    ./run_docker.sh -r --exec-non-interactive \
                    "cd compiler; ./install.sh"
}

function cleanBuildTapasco() {
    echo [clean build tapasco]
    ./run_docker.sh -r --exec-non-interactive \
                    'cd && cd llp_tapasco && ./rebuild.sh -b'
}

function installTapasco() {
    echo [install tapasco]
    ./run_docker.sh -r --exec-non-interactive \
                    'cd && cd llp_tapasco && ./rebuild.sh -i'
}

[ "$PREPARE_ORKA_DISTRO" = "1" ] && { prepareOrkaDistro || exit 1; }

[ "$BUILD_DOCKER" = "1" ] && { buildDocker || exit 1; }

[ "$CLEAN_BUILD_ROSE" = 1 ] && { cleanBuildRose || exit 1; }
[ "$INSTALL_ROSE" = 1 ] && { installRose || exit 1; }

[ "$CLEAN_BUILD_TAPASCO" = 1 ] && { cleanBuildTapasco || exit 1; }
[ "$INSTALL_TAPASCO" = 1 ] && { installTapasco || exit 1; }

[ "$CLEAN_BUILD_RRZK" = 1 ] && { cleanBuildRrzk || exit 1; }
[ "$INSTALL_RRZK" = 1 ] && { installRrzk || exit 1; }

[ "$CLEAN_BUILD_ORKA" = 1 ] && { cleanBuildOrka || exit 1; }
[ "$INSTALL_ORKA" = 1 ] && { installOrka || exit 1; }

exit 0
