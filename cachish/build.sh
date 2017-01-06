#!/bin/bash

set -eu

REPO=thusoy/cachish
COMMITISH=9fc2597

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
    cd "$tempdir/"*
    local build_dir=$(pwd)
    ./tools/build_deb.sh
    cd -
    mkdir -p dist
    mv "$build_dir/dist/"*.deb dist/
}

main
