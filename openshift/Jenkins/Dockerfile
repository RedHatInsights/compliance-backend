FROM openshift/jenkins-slave-base-centos7

ENV RUBY_MAJOR_VERSION=2 \
    RUBY_MINOR_VERSION=5

ENV RUBY_VERSION="${RUBY_MAJOR_VERSION}.${RUBY_MINOR_VERSION}" \
    RUBY_SCL_NAME_VERSION="${RUBY_MAJOR_VERSION}${RUBY_MINOR_VERSION}"

ENV RUBY_SCL="rh-ruby${RUBY_SCL_NAME_VERSION}"

RUN yum install -y centos-release-scl-rh && \
    yum-config-manager --add-repo https://cbs.centos.org/repos/sclo7-rh-ruby25-rh-candidate/x86_64/os/ && \
    echo gpgcheck=0 >> /etc/yum.repos.d/cbs.centos.org_repos_sclo7-rh-ruby25-rh-candidate_x86_64_os_.repo && \
    INSTALL_PKGS=" \
${RUBY_SCL} \
${RUBY_SCL}-ruby-devel \
${RUBY_SCL}-rubygem-rake \
${RUBY_SCL}-rubygem-bundler \
openscap \
autoconf \
automake \
bzip2 \
gcc-c++ \
gd-devel \
gdb \
git \
libcurl-devel \
libxml2-devel \
libxslt-devel \
lsof \
make \
openssl-devel \
patch \
postgresql-devel \
procps-ng \
sqlite-devel \
unzip \
wget \
which \
zlib-devel" && \
    yum install -y --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
    yum clean all -y && \
    rpm -V ${INSTALL_PKGS}

RUN chown -R 1001:0 $HOME && \
    chmod -R g+rw $HOME

ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    DATABASE_SERVICE_NAME="compliance-db" \
    COMPLIANCE_DB_SERVICE_HOST="compliance-db.compliance-ci.svc" \
    POSTGRESQL_USER="compliance_user" \
    POSTGRESQL_PASSWORD="compliance_password" \
    POSTGRESQL_ADMIN_PASSWORD="db_admin_password" \
    POSTGRESQL_DATABASE="compliance" \
    POSTGRESQL_MAX_CONNECTIONS="100" \
    POSTGRESQL_SHARED_BUFFERS="12MB" \
    RAILS_ENV="test" \
    PATH="$PATH:/opt/rh/$RUBY_SCL/root/usr/bin" \
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rh/$RUBY_SCL/root/usr/lib64" \
    MANPATH="$MANPATH:/opt/rh/$RUBY_SCL/root/usr/share/man" \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/rh/$RUBY_SCL/root/usr/lib64/pkgconfig" \
    XDG_DATA_DIRS="$XDG_DATA_DIRS:/opt/rh/$RUBY_SCL/root/usr/share" \
    X_SCLS="$RUBY_SCL"

RUN source scl_source enable rh-ruby25

USER 1001