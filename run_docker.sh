#!/usr/bin/env bash


function print_help(){
    echo "flags:"
    echo "--stop-and-unmount or -q"
    echo "--stop-remove-and-unmount or -q"
    echo "--exec-shell or -e"
    echo "--run-background -r"
    echo "--help or -h"
}


DOCKER_TAG="${DOCKER_TAG:-"dev-latest"}"
DOCKER_NAME="${DOCKER_NAME:-orkadistro}"

XILINX_HOST_PATH="${XILINX_HOST_PATH:-"/opt/Xilinx"}"
XILINX_DOCKER_PATH="${XILINX_DOCKER_PATH:-"/usr/Xilinx"}"
XILINX_VIVADO_VERSION="${XILINX_VIVADO_VERSION:-"2018.2"}"

[ ! -d $XILINX_HOST_PATH ] && {
    echo $XILINX_HOST_PATH does not exist in host file system
    # exit 1
}

vivado_board_files_dir="vivado-boards/new/board_files/"

upper_dir="./$vivado_board_files_dir"
work_dir="./__vivado_boardfiles_overlay_work_dir"
mnt_point="./__vivado_boardfiles_overlay_mnt_point"
lower_dir="${XILINX_HOST_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"

docker_mnt_point="${XILINX_DOCKER_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"

## cli "parsing"
exec_into_container="false"
stop_and_unmount="false"
run_in_background="false"
stop_remove_and_unmount="false"
exec_non_interactive="false"
unmount="false"

while [ "${1:-}" != "" ]; do
    case "$1" in
        "--stop-and-unmount" | "-q")
            stop_and_unmount="true"
            ;;
        "--unmount" | "-q")
            unmount="true"
            ;;
        "--stop-remove-and-unmount" | "-q")
            stop_remove_and_unmount="true"
            ;;
        "--exec-shell" | "-e")
            exec_into_container="true"
            ;;
        "--exec-non-interactive")
            exec_non_interactive="true"
            shift
            break;
            ;;
        "--run-background" | "-r")
            run_in_background="true"
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
    mkdir -p \
          __vivado_boardfiles_overlay_work_dir \
          __vivado_boardfiles_overlay_mnt_point

    sudo umount -q "$mnt_point"
    sudo mount -t overlay overlay \
         -o lowerdir="$lower_dir",upperdir="$upper_dir",workdir="$work_dir" \
         "$mnt_point"
}

function unmount_boardfiles_overlay() {
    sudo umount -q "$mnt_point"
    # we delete this so that ./rebuild_docker.sh can work again.
    rm -rf "$work_dir"
}

function launch_container_background() {
    docker run \
         --name $DOCKER_NAME-$DOCKER_TAG -t -d \
         -v $PWD:/mnt \
         -v $PWD/orkaevolution:/home/build/orkaevolution \
         -v $XILINX_HOST_PATH:/$XILINX_DOCKER_PATH \
         -v $PWD/fpgainfrastructure:/home/build/fpgainfrastructure \
         -v $PWD/roserebuild:/home/build/roserebuild \
         -v $PWD/"$mnt_point":"$docker_mnt_point" \
         $DOCKER_NAME:$DOCKER_TAG
}

[ "${stop_and_unmount}" == "true" ] && {
    docker stop $DOCKER_NAME-$DOCKER_TAG
    unmount_boardfiles_overlay
}

[ "${stop_remove_and_unmount}" == "true" ] && {
    docker stop $DOCKER_NAME-$DOCKER_TAG
    docker rm $DOCKER_NAME-$DOCKER_TAG
    unmount_boardfiles_overlay
}

[ "${run_in_background}" == "true" ] && {
    setup_board_files_overlay_mount
    launch_container_background
}

[ "${exec_into_container}" == "true" ] && {
    docker exec -u build -it $DOCKER_NAME-$DOCKER_TAG bash -l || \
        echo [could not open shell in container, probably you need to start it first. exit]
}

[ "${exec_non_interactive}" == "true" ] && {
    docker exec -u build -it $DOCKER_NAME-$DOCKER_TAG "$@"
}

[ "${unmount}" == "true" ] && {
    unmount_boardfiles_overlay
}
