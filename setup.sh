#!/usr/bin/env bash

git submodule sync --recursive
git submodule update --init --recursive

./rebuild_docker.sh
./run_docker.sh -r

(cd roserebuild && ./rebuild.sh --prepare --with-edg-repo)

./run_docker.sh --exec-non-interactive \
	bash -c "cd roserebuild; ./rebuild.sh -b -i"
./run_docker.sh --exec-non-interactive \
	bash -c "cd orkaevolution; cmake . ; make -j"
