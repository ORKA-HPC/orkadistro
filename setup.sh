#!/usr/bin/env bash

CLEAN_BUILD_ROSE=0
CLEAN_BUILD_ORKA=0
CLEAN_BUILD_TAPASCO=0
INSTALL_ROSE=0

while [ "${1:-}" != "" ]; do
    case "$1" in
        "--clean-build-rose" | "-c")
            CLEAN_BUILD_ROSE=1
            ;;
        "--install-rose" | "-i")
            INSTALL_ROSE=1
            ;;
        "--clean-build-tapasco")
            CLEAN_BUILD_TAPASCO=1
            ;;
        "--clean-build-orka")
            CLEAN_BUILD_ORKA=1
            ;;
        "--after-pull")
            INSTALL_ROSE=1
            CLEAN_BUILD_TAPASCO=1
            CLEAN_BUILD_ORKA=1
            ;;
        "--init")
            CLEAN_BUILD_ROSE=1
            CLEAN_BUILD_TAPASCO=1
            CLEAN_BUILD_ORKA=1
            INSTALL_ROSE=1
            ;;
        "--help" | "-h")
            echo "--clean-build-rose"
            echo "--clean-build-orka"
            echo "--clean-build-tapasco"
            echo "--install-rose"
            exit 0
            ;;
        *)
            ;;
    esac
    shift
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
                    bash -l -c "cd roserebuild; MAX_CORES=4 ./rebuild.sh --clean -b"
fi

if [ "$INSTALL_ROSE" = 1 ]; then
    echo [install rose]
    ./run_docker.sh -r -q --exec-non-interactive \
                    bash -l -c "cd roserebuild; MAX_CORES=4 ./rebuild.sh -i"
fi

if [ "$CLEAN_BUILD_ORKA" = 1 ]; then
    echo [build orkaevolution]
    ./run_docker.sh -r -q --exec-non-interactive \
                    bash -l -c "cd orkaevolution; cmake . ; make clean ; make -j"
fi


if [ "$CLEAN_BUILD_TAPASCO" = 1 ]; then
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
                    { cmake -DCMAKE_C_FLAGS="-fPIC" . && make -j$MAX_CORES; }'

    ./run_docker.sh -r -q --exec-non-interactive \
                    bash -l -c 'cd && cd tapasco-workspace &&
                    sudo bash -c ". tapasco-setup.sh &&
                    cd ../tapasco/runtime && make install"'

    ./run_docker.sh -r -q --exec-non-interactive \
                    bash -l -c 'cd && cd tapasco-workspace &&
                    sudo cp tapasco-setup.sh /etc/profile.d/tapasco.sh'
fi
