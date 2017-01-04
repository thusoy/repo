#!/bin/sh

set -eu

main () {
    upload_dists
}

upload_dists () {
    deb-s3 upload \
        --sign "$SIGNING_KEY" \
        --bucket "$TARGET_BUCKET" \
        --gpg-options='--digest-algo SHA256' \
        dist/*
}

main
