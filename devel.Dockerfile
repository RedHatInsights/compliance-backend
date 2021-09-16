FROM ruby:2.7-buster AS compliance-backend

WORKDIR /app

RUN apt-get update && apt-get install -y qt5-default libqt5webkit5-dev \
      gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x libopenscap-dev \
      postgresql-client shared-mime-info less

COPY vendor/ ./vendor
COPY Gemfile* ./
COPY devel.entrypoint.sh ./

RUN bundle -j4 --without=tableau

ENTRYPOINT ["/app/devel.entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]

FROM compliance-backend AS compliance-tableau

RUN wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
    apt-get install -y ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
    apt-get update && \
    apt-get install -y libparquet-dev

RUN bundle -j4 --with=tableau

ENTRYPOINT ["/app/devel.entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
