#!/usr/bin/env bash

export IMAGE_NAME="$1"
export DOCKER_NAME="$1"

./rebuild_docker.sh
./run_docker.sh -r

(cd roserebuild && ./rebuild.sh --prepare --with-edg-repo)

./run_docker.sh --exec-non-interactive \
	bash -c "cd roserebuild; ./rebuild.sh -b -i"
./run_docker.sh --exec-non-interactive \
	bash -c "cd orkaevolution; cmake . ; make -j"
