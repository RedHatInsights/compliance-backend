#!/bin/bash

set -exv

local_build() {
  [ "$LOCAL_BUILD" = true ]
}

backwards_compatibility_enabled() {
  [ "$BACKWARDS_COMPATIBILITY" = true ]
}

get_7_chars_commit_hash() {
    echo "$(git rev-parse --short=7 HEAD)-new"
}

_check_command_is_present() {
    command -v "$1"
}

login_container_registry() {

    local USER="$1"
    local PASSWORD="$2"
    local REGISTRY="$3"

    container_engine_cmd login "-u=${USER}" "-p=${PASSWORD}" "$REGISTRY"
}

check_required_registry_credentials() {


    if [[ -z "$RH_REGISTRY_USER" || -z "$RH_REGISTRY_TOKEN" ]]; then
        echo "RH_REGISTRY_USER and RH_REGISTRY_TOKEN must be set"
        exit 1
    fi

    if ! local_build; then
        if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
            echo "QUAY_USER, QUAY_TOKEN must be set"
            exit 1
        fi
    fi
}

container_engine_cmd() {

    if [ "$CONTAINER_ENGINE_CMD" = "podman" ]; then
        podman "$@"
    else
        docker "--config=${DOCKER_CONF}" "$@"
    fi
}

initialize_container_engine_cmd() {

    if _check_command_is_present podman; then
        CONTAINER_ENGINE_CMD='podman'
    else
        mkdir -p "$DOCKER_CONF"
        CONTAINER_ENGINE_CMD='docker'
    fi
}

initialize_image_config() {

    login_container_registry "$RH_REGISTRY_USER" "$RH_REGISTRY_TOKEN" "$REDHAT_REGISTRY"

    if local_build; then
        IMAGE_NAME="$IMAGE_REPOSITORY"
    else
        IMAGE_NAME="$IMAGE_REGISTRY/$IMAGE_REPOSITORY"
        login_container_registry "$QUAY_USER" "$QUAY_TOKEN" "$IMAGE_REGISTRY"
    fi
}

build_image() {

    container_engine_cmd build -f "$DOCKERFILE" -t "${IMAGE_NAME}:${IMAGE_TAG}" .
}

push_image() {

    local IMAGE_TAG="$1"

    container_engine_cmd push "${IMAGE_NAME}:${IMAGE_TAG}"
}

tag_image() {

    local TARGET_TAG="$1"

    container_engine_cmd tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:$TARGET_TAG"
}

tag_and_push_for_backwards_compatibility() {

    for TARGET_TAG in "latest-new" "qa-new"; do
        tag_image "$TARGET_TAG"
        if ! local_build; then
            push_image "$TARGET_TAG"
        fi
    done
}

LOCAL_BUILD="${LOCAL_BUILD:-false}"
WORKDIR="$PWD"
BACKWARDS_COMPATIBILITY="${BACKWARDS_COMPATIBILITY:-true}"
CONTAINER_ENGINE_CMD=''
DOCKER_CONF="${WORKDIR}/.docker"
DOCKERFILE="${WORKDIR}/Dockerfile"
REDHAT_REGISTRY="${REDHAT_REGISTRY:-registry.redhat.io}"
IMAGE_REGISTRY="${IMAGE_REGISTRY:-quay.io}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-cloudservices/compliance-backend}"
IMAGE_TAG=$(get_7_chars_commit_hash)
# Requires to be in a cloned git repo. directory

check_required_registry_credentials && initialize_container_engine_cmd && initialize_image_config
build_image
if ! local_build; then
    push_image "$IMAGE_TAG"
fi

# To enable backwards compatibility with ci, qa, and smoke, always push latest and qa tags
if backwards_compatibility_enabled; then
    tag_and_push_for_backwards_compatibility
fi
