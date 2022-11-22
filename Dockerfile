ARG deps="findutils hostname jq libpq openssl procps-ng ruby shared-mime-info tzdata"
ARG devDeps="gcc gcc-c++ gzip libffi-devel make openssl-devel postgresql postgresql-devel redhat-rpm-config ruby-devel tar util-linux"
ARG extras=""
ARG without="development:test"
ARG prod="true"

FROM registry.access.redhat.com/ubi9/ubi-minimal AS build

ARG deps
ARG devDeps
ARG extras
ARG prod

USER 0

WORKDIR /opt/app-root/src

COPY ./Gemfile.lock ./Gemfile ./.gemrc.prod /opt/app-root/src/

RUN ( [[ $prod == "true" ]] || rpm -e --nodeps tzdata )                         && \
    microdnf install --nodocs -y $deps $devDeps $extras                         && \
    chmod +t /tmp                                                               && \
    gem install bundler -v 2.3.22                                               && \
    mv /opt/app-root/src/.gemrc.prod /etc/gemrc                                 && \
    ( [[ $prod != "true" ]] || bundle config set --without 'development:test' ) && \
    ( [[ $prod != "true" ]] || bundle config set --local deployment 'true' )    && \
    ( [[ $prod != "true" ]] || bundle config set --local path './.bundle' )     && \
    bundle config set --local retry '2'                                         && \
    bundle install                                                              && \
    ( [[ $prod != "true" ]] || bundle clean -V )

ENV prometheus_multiproc_dir=/opt/app-root/tmp

#############################################################

FROM registry.access.redhat.com/ubi9/ubi-minimal

ARG deps
ARG devDeps

WORKDIR /opt/app-root/src

USER 0

RUN rpm -e --nodeps tzdata             && \
    microdnf install --nodocs -y $deps && \
    gem install bundler -v 2.3.22      && \
    microdnf clean all -y              && \
    chown 1001:root ./                 && \
    chmod +t /tmp                      && \
    install -v -d -m 1777 -o 1001 ./tmp ./log

USER 1001

COPY --chown=1001:0 . /opt/app-root/src
COPY --chown=1001:0 --from=build /opt/app-root/src/.bundle /opt/app-root/src/.bundle

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true HOME=/opt/app-root/src DEV_DEPS=$devDeps

CMD ["/opt/app-root/src/entrypoint.sh"]
