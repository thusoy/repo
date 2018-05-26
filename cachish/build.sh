#!/bin/bash

set -eu

REPO=thusoy/cachish
COMMITISH=v1.4.0

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
    for dist in jessie stretch; do
        cd "$tempdir"/thusoy-cachish-*
        sudo docker build . -f "Dockerfile-$dist" -t "repo-cachish-$dist"
        sudo docker run "repo-cachish-$dist"
        cd -
        container_id=$(sudo docker ps -qla)
        sudo docker cp "$container_id:/build/dist" .
        user_id=$(id -u)
        sudo chown -R "$user_id:$user_id" dist
        mkdir -p debian/"$dist"
        mv dist/* debian/"$dist"
        rm -rf dist
    done
    mkdir -p ../dist
    find debian -type f -name '*.deb' -exec mv {} ../dist \;
    rm -rf debian
}

# To check that the package works, run the following and ensure you see the
# "Booting worker with pid" message from gunicorn
# for dist in jessie stretch; do
#     sudo docker run -i -v $(pwd)/debian:/packages debian:$dist /bin/sh -s <<EOF
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
