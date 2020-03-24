#!/usr/bin/env bash

dockerTag=rose
dockerName=rose

XILINX_HOST_PATH="${XILINX_HOST_PATH:-"/opt/Xilinx"}"
XILINX_VIVADO_VERSION="${XILINX_VIVADO_VERSION:-"2018.2"}"
XILINX_DOCKER_PATH="${XILINX_DOCKER_PATH:-"/usr/Xilinx"}"

[ ! -d $XILINX_HOST_PATH ] && {
	echo $XILINX_HOST_PATH does not exist in host file system
	exit 1
}

sudo docker stop $dockerName
sudo docker rm $dockerName

upper_dir="./__vivado_boardfiles_overlay_upper_dir"
work_dir="./__vivado_boardfiles_overlay_work_dir"
mnt_point="./__vivado_boardfiles_overlay_mnt_point"
lower_dir="${XILINX_HOST_PATH}/Vivado/${XILINX_VIVADO_VERSION}/data/boards/board_files/"

sudo mount -t overlay overlay \
     -o lowerdir="$lower_dir",upperdir="$upper_dir",workdir="$work_dir" \
     "$mnt_point"

sudo docker run \
	--name $dockerName -t -d \
	-v $PWD:/mnt \
	-v $PWD/orkaevolution:/home/build/orkaevolution \
	-v $XILINX_HOST_PATH:/$XILINX_DOCKER_PATH \
	-v $PWD/fpgainfrastructure:/home/build/fpgainfrastructure \
	$dockerTag
