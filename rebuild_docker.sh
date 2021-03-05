#!/usr/bin/env bash

IMAGE_NAME="${IMAGE_NAME:-"orkadistro-img-$(git rev-parse HEAD)"}"
IMAGE_TAG="latest"

VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"
DOCKER_PUSH_PATH="i2git.cs.fau.de:5005/orka/dockerfiles"
XILINXD_LICENSE_FILE="${XILINXD_LICENSE_FILE:-"2100@scotty.e-technik.uni-erlangen.de"}"

PUSH_IMAGE="false"
MAX_CORES="${MAX_CORES:-}"
CLEAN_BUILD="${CLEAN_BUILD:-0}"
USER_ID="${USER_ID:-"$(id -u)"}"

# rm -rf orkaevolution
while [ "${1:-}" != "" ]; do
    case "${1}" in
        "--max-cores" | "-m")
            shift
            MAX_CORES="$1"
            ;;
        "--clean-build" | "-c")
            CLEAN_BUILD=1
            ;;
        "--push-image" | "-p")
            PUSH_IMAGE=true
            ;;
        "--name")
            echo [ IMAGE_NAME: $IMAGE_NAME ]
            exit
            ;;
        *)
            echo [ WARNING: unknown flag ]
            shift
            ;;
    esac
    shift
done

DOCKER_COMPOUND_TAG="$IMAGE_NAME:$IMAGE_TAG"

function expandCleanBuildParams() {
    [ "$CLEAN_BUILD" = 1 ] && echo --pull --no-cache
}

docker build \
       $(expandCleanBuildParams) \
       --build-arg ARG_XILINXD_LICENSE_FILE="$XILINXD_LICENSE_FILE" \
       --build-arg USER_ID="$USER_ID" \
       --build-arg ARG_MAX_CORES="$MAX_CORES" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t "${DOCKER_COMPOUND_TAG}" . || {
    echo "[rebuild_docker.sh] Docker build failed."
    echo "[rebuild_docker.sh] Note that you MUST stop the docker container ($ ./run_docker -q)"
    echo "[rebuild_docker.sh] before running this script using "
}


if [ "$PUSH_IMAGE" == "true" ]; then
    echo [ Push image "${DOCKER_COMPOUND_TAG}" to "${DOCKER_PUSH_PATH}" ]
    # docker tag "$DOCKER_COMPOUND_TAG" "$DOCKER_PUSH_PATH"/"${DOCKER_COMPOUND_TAG}"
    docker push "$DOCKER_PUSH_PATH"/"${DOCKER_COMPOUND_TAG}"
fi
