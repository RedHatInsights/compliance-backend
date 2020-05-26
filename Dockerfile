FROM registry.access.redhat.com/ubi8/ruby-26

USER root

COPY . /tmp/src

RUN rm -rf /tmp/src/.git* && \
    chown -R 1001 /tmp/src && \
    chgrp -R 0 /tmp/src && \
    chmod -R g+w /tmp/src

USER 1001

ENV RAILS_ENV development
ENV DISABLE_ASSET_COMPILATION true
RUN /usr/libexec/s2i/assemble
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
