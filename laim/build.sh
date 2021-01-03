#!/bin/bash

set -eu

REPO=thusoy/laim
COMMITISH=v1.0.1

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
}

build_deb () {
    mkdir -p ../dist
    cd "$tempdir"/thusoy-laim-*
    artifacts_dir="$(pwd)/artifacts"
    ./tools/build_deb.sh
    cd -
    cp -r "$artifacts_dir"/* ../dist/
}

main
