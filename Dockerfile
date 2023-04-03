ARG deps="findutils hostname jq libpq openssl procps-ng ruby shared-mime-info tzdata"
ARG devDeps="gcc gcc-c++ gzip libffi-devel make openssl-devel patch postgresql postgresql-devel redhat-rpm-config ruby-devel tar util-linux xz"
ARG extras=""
ARG prod="true"
ARG pgRepo="http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-stream-repos-8-4.el8.noarch.rpm"
ARG pgRepoKey="http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-gpg-keys-8-4.el8.noarch.rpm"

FROM registry.access.redhat.com/ubi8/ubi-minimal AS build

ARG deps
ARG devDeps
ARG extras
ARG prod
ARG pgRepo
ARG pgRepoKey

USER 0

WORKDIR /opt/app-root/src

COPY ./.gemrc.prod /etc/gemrc
COPY ./Gemfile.lock ./Gemfile /opt/app-root/src/

RUN FULL_RHEL=$(microdnf repolist --enabled | grep rhel-8);                        \
    if [ -z "$FULL_RHEL" ] ; then                                                  \
      rpm -Uvh $pgRepo $pgRepoKey                                               && \
      sed -i 's/^\(enabled.*\)/\1\npriority=200/;' /etc/yum.repos.d/CentOS*.repo;  \
    fi;                                                                            \
    rpm -e --nodeps tzdata &>/dev/null                                          && \
    microdnf module enable ruby:3.0                                             && \
    microdnf module enable postgresql:13                                        && \
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

FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG deps
ARG devDeps

WORKDIR /opt/app-root/src

USER 0

RUN rpm -e --nodeps tzdata &>/dev/null                                  && \
    microdnf module enable ruby:3.0                                     && \
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
