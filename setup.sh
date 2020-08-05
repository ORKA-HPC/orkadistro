#!/usr/bin/env bash

echo [submodule setup]
git submodule sync --recursive
git submodule update --init --recursive

echo [build docker image]
./rebuild_docker.sh

echo [prepare rose]
(cd roserebuild && ./rebuild.sh --prepare --with-edg-repo)

echo [build rose]
./run_docker.sh -r -q --exec-non-interactive \
	bash -c "cd roserebuild; ./rebuild.sh -b -i"

echo [build orkaevolution
./run_docker.sh -r -q --exec-non-interactive \
	bash -c "cd orkaevolution; cmake . ; make -j"
