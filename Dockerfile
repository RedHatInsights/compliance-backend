FROM registry.access.redhat.com/ubi8/ruby-27

# Install dependencies and clean cache to make the image cleaner

USER 0
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    yum install -y hostname shared-mime-info && \
    yum clean all -y

COPY --chown=1001:0 . /tmp/src

USER 1001

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true QMAKE=/usr/lib64/qt5/bin/qmake DISABLE_ASSET_COMPILATION=true

# Install the dependencies
RUN /usr/libexec/s2i/assemble

CMD ["/opt/app-root/src/entrypoint.sh"]
