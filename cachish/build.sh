#!/bin/bash

set -eu

REPO=thusoy/cachish
COMMITISH=v1.7.0

main () {
    get_source
    build_deb
}

get_source () {
    local source_tarball=$(mktemp)
    curl "https://api.github.com/repos/$REPO/tarball/$COMMITISH" \
        --location \
        --silent \
        -H 'Accept: application/vnd.github.v3.raw' \
        -o "$source_tarball"
    tempdir=$(mktemp -d)
    trap 'rm -rf "$tempdir"' INT TERM EXIT
    tar xf "$source_tarball" -C "$tempdir"
    cp dockerignore "$tempdir/.dockerignore"
    cp Dockerfile-* "$tempdir"/thusoy-cachish-*
}

build_deb () {
    rm -rf debian
    local container_id
    mkdir -p ../dist
    for dist in bookworm; do
        cd "$tempdir"/thusoy-cachish-*
        rm -f dev-requirements.txt configure # prevents dev requirements from being installed in the package
        docker build . -f "Dockerfile-$dist" -t "repo-cachish-$dist"
        docker run "repo-cachish-$dist"
        cd -
        container_id=$(docker ps -qla)
        docker cp "$container_id:/build/dist" .
        mkdir -p "../dist/$dist"
        cp dist/*.deb ../dist/"$dist/"
        rm -rf dist
    done
    rm -rf debian
}

# To check that the package works, run the following and ensure you see the
# "Booting worker with pid" message from gunicorn
# for dist in jessie stretch; do
#     docker run -i -v $(pwd)/debian:/packages debian:$dist /bin/sh -s <<EOF
# set -eux
# apt-get update
# dpkg -i /packages/$dist/cachish_*.deb || :
# apt-get install -fy
# CACHISH_CONFIG_FILE=/etc/cachish.yml /opt/venvs/cachish/bin/gunicorn --worker-class gevent 'cachish:create_app_from_file()' &
# gunicorn_pid=\$!
# sleep 3
# kill \$!
# EOF
# done

main
