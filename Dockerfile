from ruby:2.5

workdir /app

add . .

run apt-get update && apt-get install -y qt5-default libqt5webkit5-dev \
      gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x libopenscap-dev \
      postgresql-client

run bundle
