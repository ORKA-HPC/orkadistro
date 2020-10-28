#!/usr/bin/env bash

CLEAN_BUILD_ROSE=0

while [ "${1:-}" != "" ]; do
	case "$1" in
		"--clean-build-rose" | "-c")
			CLEAN_BUILD_ROSE=1
			shift
			;;

		*)
			;;
	esac
done

echo [submodule setup]
git submodule sync --recursive
git submodule update --init --recursive

echo [build docker image]
./rebuild_docker.sh

if [ "$CLEAN_BUILD_ROSE" = 1 ]; then
    echo [prepare rose]
    ( cd roserebuild && ./rebuild.sh --prepare --with-edg-repo )


    echo [build rose]
    ./run_docker.sh -r -q --exec-non-interactive \
	            bash -l -c "cd roserebuild; MAX_CORES=4 ./rebuild.sh --clean -b -i"
fi

echo [build rose]
./run_docker.sh -r -q --exec-non-interactive \
	bash -l -c "cd roserebuild; MAX_CORES=4 ./rebuild.sh -i"

echo [build orkaevolution]
./run_docker.sh -r -q --exec-non-interactive \
	bash -l -c "cd orkaevolution; cmake . ; make clean ; make -j"

echo [build tapasco]
./run_docker.sh -r -q --exec-non-interactive \
	bash -l -c 'cd && mkdir -p tapasco-workspace &&
		    cd tapasco-workspace &&
		    ../tapasco/tapasco-init.sh'

./run_docker.sh -r -q --exec-non-interactive \
        bash -l -c 'cd && cd tapasco-workspace &&
                    . tapasco-setup.sh && tapasco-build-toolflow'

./run_docker.sh -r -q --exec-non-interactive \
        bash -l -c 'cd && cd tapasco-workspace &&
	            . tapasco-setup.sh && cd ../tapasco/runtime &&
		    { cmake . && make -j$MAX_CORES; }'

./run_docker.sh -r -q --exec-non-interactive \
        bash -l -c 'cd && cd tapasco-workspace &&
                    sudo bash -c ". tapasco-setup.sh &&
                    cd ../tapasco/runtime && make install"'

./run_docker.sh -r -q --exec-non-interactive \
        bash -l -c 'cd && cd tapasco-workspace &&
	            sudo cp tapasco-setup.sh /etc/profile.d/tapasco.sh'
