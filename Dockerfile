ARG deps="findutils hostname jq libpq openssl ruby shared-mime-info tzdata"
ARG devDeps="gcc gcc-c++ gzip libffi-devel make openssl-devel postgresql-devel ruby-devel tar util-linux"
ARG without="development:test"

FROM registry.access.redhat.com/ubi8/ubi-minimal AS build

ARG deps
ARG devDeps
ARG without

WORKDIR /opt/app-root/src

USER 0

COPY ./Gemfile.lock ./Gemfile ./.gemrc.prod /opt/app-root/src/

RUN microdnf module enable ruby:3.0             && \
    microdnf install --nodocs -y $devDeps       && \
    gem update bundler                          && \
    mv ./.gemrc.prod /etc/gemrc                 && \
    bundle config set --local without $without  && \
    bundle config set --local deployment 'true' && \
    bundle config set --local path './.bundle'  && \
    bundle config set --local retry '2'         && \
    bundle install                              && \
    bundle clean -V

#############################################################

FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG deps
ARG devDeps

WORKDIR /opt/app-root/src

USER 0

RUN rpm -e --nodeps tzdata             && \
    microdnf module enable ruby:3.0    && \
    microdnf install --nodocs -y $deps && \
    gem update bundler                 && \
    microdnf clean all -y              && \
    chown 1001:root ./                 && \
    install -d -m 0775 -o 1001 ./tmp ./log


USER 1001

COPY --chown=1001:0 . /opt/app-root/src
COPY --chown=1001:0 --from=build /opt/app-root/src/.bundle /opt/app-root/src/.bundle

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true HOME=/opt/app-root/src DEV_DEPS=$devDeps

CMD ["/opt/app-root/src/entrypoint.sh"]
