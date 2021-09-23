#!/usr/bin/env bash

# You need to run this script on a pumpkin-enabled
# computer in order to be able to connect and use
# our automated FPGA test computer inside the docker container.

source common_docker.sh

docker cp ~/.ssh/id_rsa "$(fullContName)":/home/build/.ssh/id_rsa
docker cp ~/.ssh/id_rsa.pub "$(fullContName)":/home/build/.ssh/id_rsa.pub
