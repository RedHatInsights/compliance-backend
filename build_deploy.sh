#!/bin/bash

set -exv

_check_command_is_present() {
    command -v $1
}

login_container_registry() {

    local USER="$1"
    local PASSWORD="$2"
    local REGISTRY="$3"

    $CONTAINER_ENGINE_CMD login "-u=${USER}" "-p=${PASSWORD}" "$REGISTRY"
}

check_required_registry_credentials() {

    if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" || -z "$RH_REGISTRY_USER" || -z "$RH_REGISTRY_TOKEN" ]]; then
        echo "QUAY_USER, QUAY_TOKEN, RH_REGISTRY_USER and RH_REGISTRY_TOKEN must be set"
        exit 1
    fi
}

initialize_container_engine_cmd() {

    if _check_command_is_present podman; then
        CONTAINER_ENGINE_CMD='podman'
    else
        mkdir -p "$DOCKER_CONF"
        CONTAINER_ENGINE_CMD="docker --config=${DOCKER_CONF}"
    fi
}

build_image() {

    "$CONTAINER_ENGINE_CMD" build -f "$DOCKERFILE" -t "${IMAGE_NAME}:${IMAGE_TAG}" .
}

push_image() {

    local IMAGE_TAG="$1"

    "$CONTAINER_ENGINE_CMD" push "${IMAGE_NAME}:${IMAGE_TAG}"
}

tag_image() {

    local TARGET_TAG="$1"

    "$CONTAINER_ENGINE_CMD" tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:$TARGET_TAG"
}

tag_and_push_for_backwards_compatibility() {

    for TARGET_TAG in "latest-new" "qa-new"; do
        tag_image "$TARGET_TAG"
        push_image "$TARGET_TAG"
    done
}

IMAGE_NAME="quay.io/cloudservices/compliance-backend"
IMAGE_TAG="$(git rev-parse --short=7 HEAD)-new"
WORKDIR="$PWD"
DOCKER_CONF="${WORKDIR}/.docker"
DOCKERFILE="${WORKDIR}/Dockerfile"
CONTAINER_ENGINE_CMD=''

check_required_registry_credentials && initialize_container_engine_cmd
login_container_registry "$QUAY_USER" "$QUAY_TOKEN" 'quay.io'
login_container_registry "$RH_REGISTRY_USER" "$RH_REGISTRY_TOKEN" 'registry.redhat.io'
build_image
push_image "$IMAGE_TAG"

# To enable backwards compatibility with ci, qa, and smoke, always push latest and qa tags
tag_and_push_for_backwards_compatibility
