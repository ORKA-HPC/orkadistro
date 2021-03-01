#!/usr/bin/env bash

distro="A_orkadistro"

( cd && cd $distro && ./run_docker.sh -r )

tmux \
	new-session \; \
	send-keys "cd && cd $distro && ./run_docker.sh -e" C-m \; \
	send-keys 'cd && cd orkaevolution' C-m \; \
	split-window -h \; \
	send-keys "cd && cd $distro/orkaevolution && sl-oe orka.cpp" C-m \; \
	neww \; \
	send-keys "cd && cd $distro && ./run_docker.sh -e" C-m \; \
	send-keys 'cd && cd roserebuild' C-m \; \
	split-window -h \; \
	send-keys "cd && cd $distro/roserebuild/rose_repo/src" C-m \;
