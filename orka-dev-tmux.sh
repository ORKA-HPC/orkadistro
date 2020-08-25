#!/usr/bin/env bash

tmux \
	new-session \; \
	send-keys 'cd && cd A_orkadistro && ./run_docker.sh -e' C-m \; \
	send-keys 'cd && cd orkaevolution' C-m \; \
	split-window -h \; \
	send-keys 'cd && cd A_orkadistro/orkaevolution && sl-oe orka_evolution.cpp' C-m \; \
	neww \; \
	send-keys 'cd && cd A_orkadistro && ./run_docker.sh -e' C-m \; \
	send-keys 'cd && cd roserebuild' C-m \; \
	split-window -h \; \
	send-keys 'cd && cd A_orkadistro/roserebuild/rose_repo/src' C-m \;
