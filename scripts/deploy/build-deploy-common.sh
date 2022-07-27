#!/usr/bin/env bash

BUILD_DEPLOY_WORKDIR=$(pwd)
ADDITIONAL_TAGS="${ADDITIONAL_TAGS:-}"
REQUIRED_REGISTRIES="${REQUIRED_REGISTRIES:-quay redhat}"
REQUIRED_REGISTRIES_LOCAL="${REQUIRED_REGISTRIES_LOCAL:-redhat}"
LOCAL_BUILD="${LOCAL_BUILD:-false}"
DOCKER_CONF="$BUILD_DEPLOY_WORKDIR/.docker"
DOCKERFILE=${DOCKERFILE:="${BUILD_DEPLOY_WORKDIR}/Dockerfile"}
REDHAT_REGISTRY="${REDHAT_REGISTRY:-registry.redhat.io}"
QUAY_REGISTRY="${QUAY_REGISTRY:-quay.io}"
BUILD_ARGS="${BUILD_ARGS:-}"
IMAGE_NAME="${IMAGE_NAME:-}"
QUAY_EXPIRE_TIME="${QUAY_EXPIRE_TIME:-3d}"
CONTAINER_ENGINE_CMD=''
IMAGE_TAG=''
PREFER_CONTAINER_ENGINE="${PREFER_CONTAINER_ENGINE:-}"

local_build() {
  [ "$LOCAL_BUILD" = true ]
}

additional_tags() {
  [ -n "$ADDITIONAL_TAGS" ]
}

is_pr_or_mr_build() {
    [ -n "$ghprbPullId" ] || [ -n "$gitlabMergeRequestId" ]
}

get_pr_build_id() {

    local BUILD_ID

    if [ -n "$ghprbPullId" ]; then
        BUILD_ID="$ghprbPullId"
    elif [ -n "$gitlabMergeRequestId" ]; then
        BUILD_ID="$gitlabMergeRequestId"
    else
        BUILD_ID=''
    fi

    echo -n "$BUILD_ID"
}

get_7_chars_commit_hash() {
    git rev-parse --short=7 HEAD
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

    if [ -z "$CONTAINER_ENGINE_CMD" ]; then
        if ! set_container_engine_cmd; then
            return 1
        fi
    fi

    if [ "$CONTAINER_ENGINE_CMD" = "podman" ]; then
        podman "$@"
    else
        docker "--config=${DOCKER_CONF}" "$@"
    fi
}

set_container_engine_cmd() {

    if _configured_container_engine_available; then
        CONTAINER_ENGINE_CMD="$PREFER_CONTAINER_ENGINE"
    else
        if container_engine_available 'podman'; then
            CONTAINER_ENGINE_CMD='podman'
        elif container_engine_available 'docker'; then
            CONTAINER_ENGINE_CMD='docker'
        else
            echo "ERROR, no container engine found, please install either podman or docker first"
            return 1
        fi
    fi

    echo "Container engine selected: $CONTAINER_ENGINE_CMD"
}

_configured_container_engine_available() {

    local CONTAINER_ENGINE_AVAILABLE=1

    if [ -n "$PREFER_CONTAINER_ENGINE" ]; then
        if container_engine_available "$PREFER_CONTAINER_ENGINE"; then
            CONTAINER_ENGINE_AVAILABLE=0
        else
            echo "WARNING!: specified container engine '${PREFER_CONTAINER_ENGINE}' not present, finding alternative..."
        fi
    fi

    return "$CONTAINER_ENGINE_AVAILABLE"
}

container_engine_available() {

    local CONTAINER_ENGINE_CMD="$1"
    local CONTAINER_ENGINE_AVAILABLE=1

    if [ "$CONTAINER_ENGINE_CMD" = "podman" ]; then
        if _command_is_present 'podman'; then
            CONTAINER_ENGINE_AVAILABLE=0
        fi
    elif [ "$CONTAINER_ENGINE_CMD" = "docker" ]; then
        if _command_is_present 'docker' && ! _docker_seems_emulated; then
            CONTAINER_ENGINE_AVAILABLE=0
        fi
    fi

    return "$CONTAINER_ENGINE_AVAILABLE"
}

_command_is_present() {
    command -v "$1" > /dev/null 2>&1
}

_docker_seems_emulated() {

    local DOCKER_COMMAND_PATH
    DOCKER_COMMAND_PATH=$(command -v docker)

    if [[ $(file "$DOCKER_COMMAND_PATH") == *"ASCII text"* ]]; then
        return 0
    fi
    return 1
}

build_image() {

    local BUILD_ARGS_CMD=''
    local LABEL_PARAMETER=''


    if is_pr_or_mr_build; then
        LABEL_PARAMETER=$(get_expiry_label_parameter)
    fi

    if [ -n "$BUILD_ARGS" ]; then
        BUILD_ARGS_CMD=$(_get_build_args)
    fi

    #shellcheck disable=SC2086
    container_engine_cmd build --pull -f "$DOCKERFILE" $BUILD_ARGS_CMD $LABEL_PARAMETER \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" .

    #shellcheck disable=SC2181
    if [ $? != 0 ]; then
        echo "Error building image"
        return 1
    fi
}

get_expiry_label_parameter() {
    echo "--label quay.expires-after=${QUAY_EXPIRE_TIME}"
}

_get_build_args() {

    local tmp=''

    for BUILD_ARG in $BUILD_ARGS; do
        tmp="${tmp} --build-arg $BUILD_ARG"
    done

    echo "$tmp"
}

push_image() {

    local IMAGE_TAG="$1"

    container_engine_cmd push "${IMAGE_NAME}:${IMAGE_TAG}"
}

tag_image() {

    local TARGET_TAG="$1"

    container_engine_cmd tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:$TARGET_TAG"
}

add_additional_tags() {

    for TARGET_TAG in $ADDITIONAL_TAGS; do

        if ! tag_image "$TARGET_TAG"; then
            echo "Error creating image tag ${TARGET_TAG}"
            return 1
        fi

        if ! local_build; then
            if ! push_image "$TARGET_TAG"; then
                echo "Error pushing image tag '${TARGET_TAG}' to registry!"
                return 1
            fi
        fi
    done
}

build_deploy_init() {
    check_required_registry_credentials || return 1
    set_container_engine_cmd || return 1
    login_to_required_registries || return 1
    set_image_tag

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

set_image_tag() {

    local BUILD_ID

    BUILD_ID=$(get_pr_build_id)

    if [ -n "$BUILD_ID" ]; then
        IMAGE_TAG="pr-${BUILD_ID}-$(get_7_chars_commit_hash)"
    else
        IMAGE_TAG="$(get_7_chars_commit_hash)"
    fi
}

build_deploy_main() {

    if ! build_deploy_init; then
        echo "build_deploy init phase failed!"
        return 1
    fi
    build_image || return 1
    if ! local_build; then
        push_image "$IMAGE_TAG"
    fi

    if ! is_pr_or_mr_build && additional_tags; then
        add_additional_tags || return 1
    fi
}
