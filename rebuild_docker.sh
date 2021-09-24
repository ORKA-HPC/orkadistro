#!/usr/bin/env bash

source common_docker.sh

PUSH_IMAGE="false"
MAX_CORES="${MAX_CORES:-}"
CLEAN_BUILD="${CLEAN_BUILD:-0}"
USER_ID="${USER_ID:-"$(id -u)"}"

# rm -rf compiler
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
        "--target")
            shift
            TARGET="$1"
            IMAGE_TAG="$1"
            ;;
        "--list-targets")
            echo Available targets are development, development_closure, and production
            exit
            ;;
        *)
            echo [ WARNING: unknown flag ]
            shift
            ;;
    esac
    shift
done


function linkDockerIgnoreBasedOnTarget() {
    local dign_file=".dockerignore"
    case "$TARGET" in
        "development")
            ln -sf docker_ignore/dockerignore_development \
               "${dign_file}"
        ;;
        "development_closure")
            ln -sf docker_ignore/dockerignore_development_closure \
               "${dign_file}"
        ;;
        "production")
            ln -sf docker_ignore/dockerignore_production \
               "${dign_file}"
        ;;
    esac
}

function logIfCleanBuild() {
    [ "$CLEAN_BUILD" = 1 ] && echo Running in clean build mode.
}

function expandCleanBuildParams() {
    [ "$CLEAN_BUILD" = 1 ] && echo --pull --no-cache
}

logIfCleanBuild
linkDockerIgnoreBasedOnTarget

docker build \
       --target "$TARGET" \
       $(expandCleanBuildParams) \
       --build-arg USER_ID="$USER_ID" \
       --build-arg ARG_MAX_CORES="$MAX_CORES" \
       --build-arg VIVADO_VERSION="${VIVADO_VERSION}" \
       -t "$IMAGE_FULL_BUILD_NAME" . || {
    echo "[rebuild_docker.sh] Docker build failed."
    echo "[rebuild_docker.sh] Note that you MUST stop the docker container ($ ./run_docker -q)"
    echo "[rebuild_docker.sh] before running this script using "
}


if [ "$PUSH_IMAGE" == "true" ]; then
    echo [ Push image "${IMAGE_FULL_NAME}" to "${DOCKER_PUSH_PATH}" ]
    docker push "$IMAGE_FULL_BUILD_NAME"
fi
