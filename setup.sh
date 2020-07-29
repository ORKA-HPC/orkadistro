#!/usr/bin/env bash

export IMAGE_NAME="$1" 
export DOCKER_NAME="$1" 

./rebuild_docker.sh
./run_docker.sh -r

(cd roserebuild && ./rebuild.sh --prepare)

./run_docker.sh --exec-non-interactive \
	bash -c "cd roserebuild; ./rebuild.sh -b"
./run_docker.sh --exec-non-interactive \
	bash -c "cd orkadistro; cmake . ; make -j"
