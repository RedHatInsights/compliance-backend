ARG BASE_IMAGE="registry.access.redhat.com/ubi10/ubi-minimal@sha256:ab67cd02caf8706e34a695a1432ebe965934f6128ec352a6c3f4048b43a4fb5e"
ARG deps="findutils hostname jq libpq openssl procps-ng ruby shared-mime-info tzdata"
ARG devDeps="clang llvm-devel cargo gcc gcc-c++ libstdc++-static gzip libffi-devel libyaml-devel make openssl-devel patch postgresql postgresql-devel redhat-rpm-config ruby-devel rust tar which util-linux xz git"
ARG extras=""
ARG prod="true"
ARG BUNDLE_JOBS="4"
ARG HERMETIC="false"

#############################################################

FROM ${BASE_IMAGE} AS build

# Diverge stage 1 immediately to prevent cache tag collisions with final stage
ENV IS_BUILD_STAGE=true

ARG deps
ARG devDeps
ARG extras
ARG prod
ARG BUNDLE_JOBS
ARG HERMETIC

USER 0

WORKDIR /opt/app-root/src

# reduce amount of threads for gRPC compilation to prevent CI hangs
ENV GRPC_RUBY_BUILD_PROCS=4
ENV MAKEFLAGS="-j4"
# gRPC's bundled Abseil does not build with RHEL 10's x86-64-v3 BMI2 defaults.
ENV CFLAGS="-march=x86-64-v2" CXXFLAGS="-march=x86-64-v2"

COPY ./.gemrc.prod /etc/gemrc
COPY ./Gemfile.lock ./Gemfile /opt/app-root/src/
COPY ./.hermetic_builds/cargo/config.toml .hermetic_builds/cargo/config.toml

RUN microdnf install --nodocs -y $deps $devDeps $extras                                                   && \
    chmod +t /tmp                                                                                         && \
    ( [[ $HERMETIC == "true" ]] || gem update --system -N --install-dir=/usr/share/gems --bindir /usr/bin ) && \
    ( [[ $HERMETIC == "true" ]] || gem install bundler )                                                    && \
    ( [[ $HERMETIC != "true" ]] || (mkdir -p .cargo && cp .hermetic_builds/cargo/config.toml .cargo/config.toml) ) && \
    ( [[ $prod != "true" ]] || bundle config set --local without 'development test' )                     && \
    ( [[ $prod != "true" ]] || bundle config set --local deployment 'true' )                              && \
    ( [[ $prod != "true" ]] || bundle config set --local path './.bundle' )                               && \
    bundle config set --local retry '2'                                                                   && \
    bundle config set --local force_ruby_platform true                                                    && \
    bundle config set --local build.ffi --enable-system-libffi                                            && \
    bundle install --jobs 6                                                                               && \
    ( [[ $HERMETIC != "true" ]] || cp "${BUNDLE_APP_CONFIG}/config" .bundle/config )                         && \
    microdnf clean all -y                                                                                 && \
    ( [[ $prod != "true" ]] || bundle clean -V )

ARG IMAGE_TAG
LABEL BUILD_STAGE_OF=$IMAGE_TAG

ENV prometheus_multiproc_dir=/opt/app-root/src/tmp prometheus_rust_mmaped_file=false

#############################################################

FROM ${BASE_IMAGE}

ARG deps
ARG devDeps
ARG HERMETIC

WORKDIR /opt/app-root/src

USER 0

RUN microdnf install --nodocs -y $deps                                                 && \
    chmod +t /tmp                                                                      && \
    ( [[ $HERMETIC == "true" ]] || gem update --system -N --install-dir=/usr/share/gems --bindir /usr/bin ) && \
    microdnf clean all -y                                                              && \
    chown 1001:root ./                                                                 && \
    install -v -d -m 1777 -o 1001 ./tmp ./log

USER 1001

COPY --chown=1001:0 . /opt/app-root/src
COPY --chown=1001:0 --from=build /opt/app-root/src/.bundle /opt/app-root/src/.bundle

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true HOME=/opt/app-root/src DEV_DEPS=$devDeps prometheus_multiproc_dir=/opt/app-root/src/tmp prometheus_rust_mmaped_file=false

CMD ["/opt/app-root/src/entrypoint.sh"]
