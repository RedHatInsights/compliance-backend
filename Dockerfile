FROM registry.access.redhat.com/ubi8/ruby-27 AS compliance-backend

USER 0

# Install dependencies and clean cache to make the image cleaner
# also remove unused packages added by ubi8/s2i-base.
RUN yum install -y hostname shared-mime-info jq && \
    yum remove -y mariadb-connector-c-devel npm && \
    yum clean all -y

COPY --chown=1001:0 . /tmp/src

USER 1001

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true QMAKE=/usr/lib64/qt5/bin/qmake DISABLE_ASSET_COMPILATION=true BUNDLE_WITHOUT=development:test:tableau

# Install the dependencies
RUN /usr/libexec/s2i/assemble

CMD ["/opt/app-root/src/entrypoint.sh"]

FROM compliance-backend as compliance-tableau

USER 0

RUN yum config-manager --enable "codeready-builder-for-rhel-8-$(arch)-rpms" && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(cut -d: -f5 /etc/system-release-cpe | cut -d. -f1).noarch.rpm && \
    yum install -y https://apache.jfrog.io/artifactory/arrow/centos/$(cut -d: -f5 /etc/system-release-cpe | cut -d. -f1)/apache-arrow-release-latest.rpm && \
    yum install -y parquet-glib-devel

USER 1001

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true QMAKE=/usr/lib64/qt5/bin/qmake DISABLE_ASSET_COMPILATION=true BUNDLE_WITHOUT=development:test

# Install the additional tableau dependencies
RUN bundle install --deployment --retry 2 --path ./bundle --with tableau --without development:test && \
    bundle clean -V

CMD ["/opt/app-root/src/entrypoint.sh"]
