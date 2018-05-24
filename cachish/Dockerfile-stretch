FROM debian:stretch

WORKDIR /build

RUN apt-get update && apt-get install -y \
    debhelper \
    python3 \
    dh-virtualenv \
    dh-systemd \
    git

ADD cachish /build/cachish
ADD debian /build/debian
ADD tools /build/tools
ADD requirements.txt /build
ADD CHANGELOG.md /build
ADD setup.py /build


RUN git config --global user.name "Tarjei Husøy" && git config --global user.email "git@thusoy.com"

RUN ./tools/build_deb.sh
