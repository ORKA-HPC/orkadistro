#!/usr/bin/env bash

function print_help(){
    echo "flags:"
    echo "--stop or -q"
    echo "--stop-and-remove"
    echo "--exec-shell or -e"
    echo "--exec-non-interactive"
    echo "--start or -r"
    echo "--help or -h"
}

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
IMAGE_NAME="${IMAGE_NAME:-"orkadistro-img-$(git rev-parse HEAD)"}"
CONTAINER_NAME="${CONTAINER_NAME:-"orkadistro-cont-$(sha256sum <(realpath $PWD) | cut -c 1-8)"}"

XILINX_HOST_PATH="${XILINX_HOST_PATH:-"/opt/Xilinx"}"
XILINXD_LICENSE_FILE="${XILINXD_LICENSE_FILE:-"2100@scotty.e-technik.uni-erlangen.de"}"
# be careful changing this. Some Vivado files generated for the host include absolute paths
XILINX_DOCKER_PATH="${XILINX_DOCKER_PATH:-"/opt/Xilinx"}"
XILINX_VIVADO_VERSION="${XILINX_VIVADO_VERSION:-"2018.2"}"

[ ! -d $XILINX_HOST_PATH ] && {
    echo $XILINX_HOST_PATH does not exist in host file system
    echo You need to install Xilinx there
    exit 1
}

work_dir="./__vivado_boardfiles_overlay_work_dir"
mnt_point="./__vivado_boardfiles_overlay_mnt_point"
docker_mnt_point="${XILINX_DOCKER_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"


## cli "parsing"
stop_container="false"
stop_and_remove_container="false"
exec_into_container="false"
exec_non_interactive="false"
start_container="false"

echo [run_docker.sh "$@"]
while [ "${1:-}" != "" ]; do
    case "$1" in
        "--stop" | "-q")
            stop_container="true"
            ;;
        "--stop-and-remove")
            stop_and_remove_container="true"
            ;;
        "--exec-shell" | "-e")
            exec_into_container="true"
            ;;
        "--exec-non-interactive")
            exec_non_interactive="true"
            shift
            break;
            ;;
        "--info")
            echo "IMAGE_TAG: $IMAGE_TAG"
            echo "IMAGE_NAME: $IMAGE_NAME"
            echo "CONTAINER_NAME: $CONTAINER_NAME"
            echo Note that you can override these variables

            exit 0
            break
            ;;
        "--start" | "-r")
            start_container="true"
            ;;
        "--get-image-name")
            echo $IMAGE_NAME
            exit 0
            ;;
        "--get-container-name")
            echo $CONTAINER_NAME
            exit 0
            ;;
        "--help" | "-h")
            print_help
            exit
            ;;
        *)
            echo [unknown cli flag]
            shift
            ;;
    esac
    shift
done

function setup_board_files_overlay_mount() {
    echo [setup arty board files overlay mount]
    mkdir -p "$work_dir" "$mnt_point"

    local vivado_board_files_dir="vivado-boards/new/board_files/"
    local upper_dir="./$vivado_board_files_dir"
    local lower_dir="${XILINX_HOST_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"

    sudo umount "$mnt_point" 2> /dev/null
    sudo mount -t overlay overlay \
         -o lowerdir="$lower_dir",upperdir="$upper_dir",workdir="$work_dir" \
         "$mnt_point"
}

function unmount_boardfiles_overlay() {
    echo [unmount boardfiles overlay]
    sudo umount "$mnt_point" 2> /dev/null
    # we delete this so that ./rebuild_docker.sh can work again.
    sudo rm -rf "$work_dir"
    return 0
}

function launch_container_background() {
    echo exec cmd [docker run --name $CONTAINER_NAME ...]
    docker run \
           --env XILINX_DOCKER_PATH="$XILINX_DOCKER_PATH" \
           --env XILINX_VIVADO_VERSION="$XILINX_VIVADO_VERSION" \
           --env XILINXD_LICENSE_FILE="$XILINXD_LICENSE_FILE" \
           --name $CONTAINER_NAME -t -d \
           -v $PWD:/mnt \
           -v $PWD/orkaevolution:/home/build/orkaevolution \
           -v $XILINX_HOST_PATH:/$XILINX_DOCKER_PATH \
           -v $PWD/fpgainfrastructure:/home/build/fpgainfrastructure \
           -v $PWD/roserebuild:/home/build/roserebuild \
           -v $PWD/tapasco:/home/build/tapasco \
           -v $PWD/tests:/home/build/tests \
           -v $PWD/synthBin:/home/build/synthBin \
           -v $PWD/"$mnt_point":"$docker_mnt_point" \
           $IMAGE_NAME:$IMAGE_TAG
}

function start_container() {
    echo [start container]
    setup_board_files_overlay_mount
    launch_container_background 2>/dev/null || {
        echo [run_docker.sh] Creating and running the docker container failed.
        echo "               - Either because is is was already created and is now suspended"
        echo "               - or because you just pulled this repo."
        echo "               In the case you have recently __pulled__ orkadistro,"
        echo "               the image of this suspended container might have changed:"
        echo "               - Save all your changes from the container's filesystem,"
        echo "               - ./run_docker.sh --stop-and-remove the container"
	echo "               - and ./rebuild_docker.sh it."
        echo [run_docker.sh] Trying to start the suspended container...
        docker container start $CONTAINER_NAME || {
		echo Could not start suspended container
		exit 1
	}
    }
}

function stop_container() {
    echo [stop container]
    docker stop $CONTAINER_NAME
    unmount_boardfiles_overlay
}

[ "${start_container}" == "true" ] && {
    start_container
}

[ "${exec_into_container}" == "true" ] && {
    docker exec -u build -it $CONTAINER_NAME bash -l || \
        echo [could not open shell in container, \
                    probably you have not started it yet]
}

[ "${exec_non_interactive}" == "true" ] && {
    echo run [ "$@" ]
    docker exec -u build -it $CONTAINER_NAME bash -l -c "$@" || {
        echo Could not run command in container.
        echo Probably you have not started it yet or command executed with errorcode
        exit 1
    }
}

[ "${stop_container}" == "true" ] && {
    stop_container
}

[ "${stop_and_remove_container}" == "true" ] && {
    stop_container
    docker rm $CONTAINER_NAME
}

exit 0
