
DOCKER_PUSH_PATH="${DOCKER_PUSH_PATH:-i2git.cs.fau.de:5005/orka/dockerfiles/orkadistro}"
IMAGE_TAG="${IMAGE_TAG:-"development"}"
IMAGE_NAME="${IMAGE_NAME:-"orkadistro-img-$(git rev-parse HEAD)"}"
IMAGE_FULL_NAME="$IMAGE_NAME:$IMAGE_TAG"
IMAGE_FULL_BUILD_NAME="$DOCKER_PUSH_PATH/$IMAGE_FULL_NAME"
TARGET="${TARGET:-development}"
