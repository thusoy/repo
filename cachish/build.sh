#!/bin/bash

set -eu

REPO=thusoy/cachish
COMMITISH=v1.3.1

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
    cp Dockerfile-* "$tempdir"/thusoy-cachish-*
}

build_deb () {
    rm -rf debian
    for dist in jessie stretch; do
        cd "$tempdir"/thusoy-cachish-*
        sudo docker build . -f "Dockerfile-$dist"
        cd -
        local container_id
        container_id=$(sudo docker ps -qla)
        sudo docker cp "$container_id:/build/dist" .
        user_id=$(id -u)
        sudo chown -R "$user_id:$user_id" dist
        mkdir -p debian/"$dist"
        mv dist/* debian/"$dist"
        rm -rf dist
    done
}

main
