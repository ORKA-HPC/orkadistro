#!/usr/bin/env bash

./rebuild_docker.sh
./run_docker.sh -r

roserebuild/rebuild.sh --prepare

./run_docker.sh -e
