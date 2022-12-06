ARG deps="findutils hostname jq libpq openssl procps-ng ruby shared-mime-info tzdata"
ARG devDeps="gcc gcc-c++ gzip libffi-devel make openssl-devel patch postgresql postgresql-devel redhat-rpm-config ruby-devel tar util-linux xz"
ARG extras=""
ARG prod="true"

FROM registry.access.redhat.com/ubi9/ubi-minimal AS build

ARG deps
ARG devDeps
ARG extras
ARG prod

USER 0

WORKDIR /opt/app-root/src

COPY ./.gemrc.prod /etc/gemrc
COPY ./Gemfile.lock ./Gemfile /opt/app-root/src/

RUN rpm -e --nodeps tzdata &>/dev/null                                          && \
    microdnf install --nodocs -y $deps $devDeps $extras                         && \
    chmod +t /tmp                                                               && \
    gem update --system --install-dir=/usr/share/gems --bindir /usr/bin         && \
    gem install bundler                                                         && \
    ( [[ $prod != "true" ]] || bundle config set --without 'development:test' ) && \
    ( [[ $prod != "true" ]] || bundle config set --local deployment 'true' )    && \
    ( [[ $prod != "true" ]] || bundle config set --local path './.bundle' )     && \
    bundle config set --local retry '2'                                         && \
    bundle install                                                              && \
    microdnf clean all -y                                                       && \
    ( [[ $prod != "true" ]] || bundle clean -V )

ENV prometheus_multiproc_dir=/opt/app-root/src/tmp

#############################################################

FROM registry.access.redhat.com/ubi9/ubi-minimal

ARG deps
ARG devDeps

WORKDIR /opt/app-root/src

USER 0

RUN rpm -e --nodeps tzdata &>/dev/null                                  && \
    microdnf install --nodocs -y $deps                                  && \
    chmod +t /tmp                                                       && \
    gem update --system --install-dir=/usr/share/gems --bindir /usr/bin && \
    microdnf clean all -y                                               && \
    chown 1001:root ./                                                  && \
    install -v -d -m 1777 -o 1001 ./tmp ./log

USER 1001

COPY --chown=1001:0 . /opt/app-root/src
COPY --chown=1001:0 --from=build /opt/app-root/src/.bundle /opt/app-root/src/.bundle

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true HOME=/opt/app-root/src DEV_DEPS=$devDeps

CMD ["/opt/app-root/src/entrypoint.sh"]
