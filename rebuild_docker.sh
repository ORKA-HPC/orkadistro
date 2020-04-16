#!/usr/bin/env bash

IMAGE_NAME="${IMAGE_NAME:-"orkadistro"}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

EDG_ACCESS_TOKEN="${EDG_ACCESS_TOKEN:-$(pass fau/orka/edgAccessToken)}"
ROSE_ACCESS_TOKEN="${ROSE_ACCESS_TOKEN:-$(pass fau/orka/roseAccessToken)}"

VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"
DOCKER_PUSH_PATH="i2git.cs.fau.de:5005/orka/dockerfiles"

IMAGE_TYPE="" # can be {dev,dev-edg,prod}
PUSH_IMAGE="false"
MAX_CORES="${MAX_CORES:-}"
USER_ID="${USER_ID:-"$(id -u)"}"

# rm -rf orkaevolution
while [ "${1:-}" != "" ]; do
    case "${1}" in
        "--max-cores" | "-m")
            shift
            MAX_CORES="$1"
            ;;
        "--image-type" | "-i")
            shift
            IMAGE_TYPE="${1}"
            ;;
        "--push-image" | "-p")
            PUSH_IMAGE=true
            ;;
        "--rose-access-token" | "-r")
            shift
            ROSE_ACCESS_TOKEN="$1"
            ;;
        "--edg-access-token" | "-e")
            shift
            EDG_ACCESS_TOKEN="$1"
            ;;
        *)
            echo [ WARNING: unknown flag ]
            shift
            ;;
    esac
    shift
done

[ "$IMAGE_TYPE" = "dev" -o "$IMAGE_TYPE" = "dev-edg" -o "$IMAGE_TYPE" = "prod" ]  || {
    echo [ $IMAGE_TYPE is wrong ]
    exit 1
}

DOCKER_COMPOUND_TAG="$IMAGE_NAME:$IMAGE_TYPE-$IMAGE_TAG"

echo building docker with USER_ID="$USER_ID" \
       IMAGE_TYPE="$IMAGE_TYPE" ARG_EDG_ACCESS_TOKEN="$EDG_ACCESS_TOKEN" \
       ARG_ROSE_ACCESS_TOKEN="$ROSE_ACCESS_TOKEN" VIVADO_VERSION="${VIVADO_VERSION}" \

docker build \
       --build-arg USER_ID="$USER_ID" \
       --build-arg IMAGE_TYPE="$IMAGE_TYPE" \
       --build-arg ARG_MAX_CORES="$MAX_CORES" \
       --build-arg ARG_EDG_ACCESS_TOKEN="$EDG_ACCESS_TOKEN" \
       --build-arg ARG_ROSE_ACCESS_TOKEN="$ROSE_ACCESS_TOKEN" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t "${DOCKER_COMPOUND_TAG}" . || exit 1


if [ "$PUSH_IMAGE" == "true" ]; then
    echo [ Push image "${DOCKER_COMPOUND_TAG}" to "${DOCKER_PUSH_PATH}" ]
    docker tag "$IMAGE_NAME" "$DOCKER_PUSH_PATH"/"${DOCKER_COMPOUND_TAG}"
    docker push "$DOCKER_PUSH_PATH"/"${DOCKER_COMPOUND_TAG}"
fi
