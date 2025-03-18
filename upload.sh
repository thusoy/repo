#!/bin/sh

set -eu

main () {
    upload_dists
}

upload_dists () {
    for dist in bullseye bookworm; do
        deb-s3 upload \
            --sign "$SIGNING_KEY" \
            --bucket "$TARGET_BUCKET" \
            --origin thusoy \
            --codename "$dist" \
            --prefix "apt/debian" \
            --gpg-options='--digest-algo SHA256' \
            "dist/$dist/"*
    done
}

main
