#!/usr/bin/env bash

./rebuild_docker.sh
./run_docker.sh -r

roserebuild/rebuild.sh --prepare

./run_docker.sh --exec-non-interactive \
	bash -c "cd roserebuild; ./rebuild.sh -b"
./run_docker.sh --exec-non-interactive \
	bash -c "cd orkadistro; cmake . ; make -j"
