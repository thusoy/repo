FROM debian:stretch

WORKDIR /build

ADD cachish /build/cachish

ADD debian /build/debian

ADD tools /build/tools

ADD requirements.txt /build

RUN apt-get install -y debhelper python3 dh-virtualenv dh-systemd

RUN ./tools/build_deb.sh

RUN find -type f dist
