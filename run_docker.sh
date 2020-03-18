#!/usr/bin/env bash

dockerTag=rose
dockerName=rose

XILINX_HOST_PATH="${XILINX_HOST_PATH:-"/opt/Xilinx"}"
XILINX_DOCKER_PATH="${XILINX_DOCKER_PATH:-"/usr/Xilinx"}"

[ ! -d $XILINX_HOST_PATH ] && { 
	echo $XILINX_HOST_PATH does not exist in host file system
	exit 1
}

sudo docker stop $dockerName
sudo docker rm $dockerName

sudo docker run \
	--name $dockerName -t -d \
	-v $PWD:/mnt \
	-v $XILINX_HOST_PATH:/$XILINX_DOCKER_PATH \
	$dockerTag


# remarks:
# --------
