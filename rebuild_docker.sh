#!/usr/bin/env bash

IMAGE_NAME="${IMAGE_NAME:-"orkadistro"}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

EDG_ACCESS_TOKEN="${EDG_ACCESS_TOKEN:-$(pass fau/orka/edgAccessToken)}"
ROSE_ACCESS_TOKEN="${ROSE_ACCESS_TOKEN:-$(pass fau/orka/roseAccessToken)}"

VIVADO_VERSION="${VIVADO_VERSION:-2018.2}"
DOCKER_PUSH_PATH="i2git.cs.fau.de:5005/orka/dockerfiles"

IMAGE_TYPE="" # can be {dev,dev-edg,prod}
PUSH_IMAGE="false"

# rm -rf orkaevolution
while [ "${1:-}" != "" ]; do
    case "${1}" in
        "--image-type" | "-i")
            shift
            IMAGE_TYPE="${1}"
            ;;
        "--push-image" | "-p")
            shift
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

[ "$IMAGE_TYPE" == "dev" ] \
    || [ "$IMAGE_TYPE" == "dev-edg" ] \
    || [ "$IMAGE_TYPE" == "prod" ] \
    || {
    echo [ IMAGE_TYPE is wrong ]
    exit 1
}

DOCKER_COMPOUND_TAG="$IMAGE_NAME:$IMAGE_TYPE-$IMAGE_TAG"

echo building docker with USER_ID="$(id -u)" \
       IMAGE_TYPE="$IMAGE_TYPE" ARG_EDG_ACCESS_TOKEN="$EDG_ACCESS_TOKEN" \
       ARG_ROSE_ACCESS_TOKEN="$ROSE_ACCESS_TOKEN" VIVADO_VERSION="${VIVADO_VERSION}" \

docker build \
       --build-arg USER_ID="$(id -u)" \
       --build-arg IMAGE_TYPE="$IMAGE_TYPE" \
       --build-arg ARG_EDG_ACCESS_TOKEN="$EDG_ACCESS_TOKEN" \
       --build-arg ARG_ROSE_ACCESS_TOKEN="$ROSE_ACCESS_TOKEN" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t "${DOCKER_COMPOUND_TAG}" . || exit 1


if [ "$PUSH_IMAGE" == "true" ]; then
    docker push "$DOCKER_PUSH_PATH"/"${DOCKER_COMPOUND_TAG}"
fi
