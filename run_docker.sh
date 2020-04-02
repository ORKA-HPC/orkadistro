#!/usr/bin/env bash

dockerTag=rose
dockerName=rose

XILINX_HOST_PATH="${XILINX_HOST_PATH:-"/opt/Xilinx"}"
XILINX_DOCKER_PATH="${XILINX_DOCKER_PATH:-"/usr/Xilinx"}"
XILINX_VIVADO_VERSION="${XILINX_VIVADO_VERSION:-"2018.2"}"

[ ! -d $XILINX_HOST_PATH ] && {
    echo $XILINX_HOST_PATH does not exist in host file system
    exit 1
}

## cli "parsing"
exec_into_container="false"
stop_and_unmount="false"

while [ "${1:-}" != "" ]; do
    case "$1" in
        "--stop-and-unmount" | "-q")
            stop_and_unmount="true"
            ;;
        "--exec-shell" | "-e")
            exec_into_container="true"
            ;;
        *)
            shift
            ;;
    esac
    shift
done

if [ "${exec_into_container}" == "true" ]; then
    docker exec -it $dockerName bash -l
    exit 0
fi

## docker foo wohoo
sudo docker stop $dockerName
sudo docker rm $dockerName

mkdir -p \
      __vivado_boardfiles_overlay_work_dir \
      __vivado_boardfiles_overlay_mnt_point

vivado_board_files_dir="vivado-boards/new/board_files/"

upper_dir="./$vivado_board_files_dir"
work_dir="./__vivado_boardfiles_overlay_work_dir"
mnt_point="./__vivado_boardfiles_overlay_mnt_point"
lower_dir="${XILINX_HOST_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"

if [ "${stop_and_unmount}" == "true" ]; then
    sudo umount -q "$mnt_point"
    # we delete this so that ./rebuild_docker.sh can
    # work again.
    rm -rf "$work_dir"
    exit 0
fi

sudo umount -q "$mnt_point"
sudo mount -t overlay overlay \
     -o lowerdir="$lower_dir",upperdir="$upper_dir",workdir="$work_dir" \
     "$mnt_point"

docker_mnt_point="${XILINX_DOCKER_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"
sudo docker run \
     --name $dockerName -t -d \
     -v $PWD:/mnt \
     -v $PWD/orkaevolution:/home/build/orkaevolution \
     -v $XILINX_HOST_PATH:/$XILINX_DOCKER_PATH \
     -v $PWD/fpgainfrastructure:/home/build/fpgainfrastructure \
     -v $PWD/roserebuild:/home/build/roserebuild \
     -v $PWD/"$mnt_point":"$docker_mnt_point" \
     $dockerTag
