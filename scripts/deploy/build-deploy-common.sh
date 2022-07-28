#!/usr/bin/env bash

BUILD_DEPLOY_WORKDIR=$(pwd)
BACKWARDS_COMPATIBILITY="${BACKWARDS_COMPATIBILITY:-true}"
BACKWARDS_COMPATIBILITY_TAGS="latest qa"
REQUIRED_REGISTRIES="quay redhat"
REQUIRED_REGISTRIES_LOCAL="redhat"
LOCAL_BUILD="${LOCAL_BUILD:-false}"
DOCKER_CONF="$BUILD_DEPLOY_WORKDIR/.docker"
DOCKERFILE=${DOCKERFILE:="${BUILD_DEPLOY_WORKDIR}/Dockerfile"}
REDHAT_REGISTRY="${REDHAT_REGISTRY:-registry.redhat.io}"
QUAY_REGISTRY="${QUAY_REGISTRY:-quay.io}"
CONTAINER_ENGINE_CMD=''
BUILD_ARGS=''

local_build() {
  [ "$LOCAL_BUILD" = true ]
}

backwards_compatibility_enabled() {
  [ "$BACKWARDS_COMPATIBILITY" = true ]
}

is_ci_runner() {
    [[ "$CI" == true ]]
}

get_7_chars_commit_hash() {
    git rev-parse --short=7 HEAD
}

_check_command_is_present() {
    command -v "$1"
}

login_container_registry() {

    local USER="$1"
    local PASSWORD="$2"
    local REGISTRY="$3"

    container_engine_cmd login "-u=${USER}" "--password-stdin" "$REGISTRY" <<< "$PASSWORD"
}

login_quay_registry() {
    login_container_registry "$QUAY_USER" "$QUAY_TOKEN" "$QUAY_REGISTRY"
}

login_redhat_registry() {
    login_container_registry "$RH_REGISTRY_USER" "$RH_REGISTRY_TOKEN" "$REDHAT_REGISTRY"
}

login_container_registry_type() {

    local REGISTRY="$1"

    if [ "$REGISTRY" = 'quay' ]; then
        login_quay_registry || return 1
    elif [ "$REGISTRY" = 'redhat' ]; then
        login_redhat_registry || return 1
    else
        echo "unsupported registry '$REGISTRY'"
        return 1
    fi
}

login_to_required_registries() {

    for REGISTRY in $REQUIRED_REGISTRIES_LOCAL; do
        if ! login_container_registry_type "$REGISTRY"; then
            echo "Error while attempting to log into '${REGISTRY}' registry"
            return 1
        fi
    done

    if ! local_build; then
        for REGISTRY in $REQUIRED_REGISTRIES; do
            if ! login_container_registry_type "$REGISTRY"; then
                echo "Error while attempting to log into '${REGISTRY}' registry"
                return 1
            fi
        done
    fi
}

check_quay_registry_credentials() {
    [ -n "$QUAY_USER" ] && [ -n "$QUAY_TOKEN" ]
}

check_rh_registry_credentials() {
    [ -n "$RH_REGISTRY_USER" ] && [ -n "$RH_REGISTRY_TOKEN" ]
}

check_registry_credentials() {

    local REGISTRY="$1"

    if [ "$REGISTRY" = 'quay' ]; then
        check_quay_registry_credentials || return 1
    elif [ "$REGISTRY" = 'redhat' ]; then
        check_rh_registry_credentials || return 1
    else
        echo "unsupported registry '$REGISTRY'"
        return 1
    fi
}

check_required_registry_credentials() {

    for REGISTRY in $REQUIRED_REGISTRIES_LOCAL; do
        if ! check_registry_credentials "$REGISTRY"; then
            echo "Error checking environment for ${REGISTRY} registry credentials"
            return 1
        fi
    done

    if ! local_build; then
        for REGISTRY in $REQUIRED_REGISTRIES; do
            if ! check_registry_credentials "$REGISTRY"; then
                echo "Error checking environment for ${REGISTRY} registry credentials"
            return 1
        fi
        done
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

    if _check_command_is_present podman && ! is_ci_runner; then
        CONTAINER_ENGINE_CMD='podman'
    else
        mkdir -p "$DOCKER_CONF"
        CONTAINER_ENGINE_CMD='docker'
    fi
}

_get_build_args() {

    local tmp=''

    for BUILD_ARG in $BUILD_ARGS; do
        tmp="${tmp} --build-arg $BUILD_ARG"
    done

    echo "$tmp"
}

build_image() {

    local BUILD_ARGS_CMD=''

    if [ -n "$BUILD_ARGS" ]; then
        BUILD_ARGS_CMD=$(_get_build_args)
        container_engine_cmd build --pull -f "$DOCKERFILE" "$BUILD_ARGS_CMD" -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    else
        container_engine_cmd build --pull -f "$DOCKERFILE" -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    fi

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

    for TARGET_TAG in $BACKWARDS_COMPATIBILITY_TAGS; do
        tag_image "$TARGET_TAG"
        if ! local_build; then
            push_image "$TARGET_TAG"
        fi
    done
}

build_deploy_init() {
    check_required_registry_credentials || return 1
    initialize_container_engine_cmd || return 1
    login_to_required_registries || return 1

    # TODO - validate some image related variables ?  wrap this into function
    if [ -z "$IMAGE_NAME" ]; then
        echo "you must define IMAGE_NAME"
        return 1
    fi

    if [ ! -r "$DOCKERFILE" ]; then
        echo "ERROR: No ${DOCKERFILE} found or not readable"
        return 1
    fi
}

build_deploy_main() {

    if ! build_deploy_init; then
        echo "build_deploy init phase failed!"
        return 1
    fi
    build_image
    if ! local_build; then
        push_image "$IMAGE_TAG"
    fi

    # To enable backwards compatibility with ci, qa, and smoke, always push latest and qa tags
    if backwards_compatibility_enabled; then
        tag_and_push_for_backwards_compatibility
    fi
}

IMAGE_TAG=$(get_7_chars_commit_hash)
