#!/usr/bin/env bash

mounts="roserebuild:/home/build/roserebuild,/opt/Xilinx:/usr/Xilinx,orkaevolution:/home/build/orkaevolution,tapasco:/home/build/tapasco,fpgainfrastructure:/home/build/fpgainfrastructure"


singularity shell -B $mounts --overlay overlay.img orkadistro-img-9815c442ce2bdbe82e158d8aac5cf24c3dbc9336-2020-09-09-6140fc66e014.simg
