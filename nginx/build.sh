#!/bin/sh

# Build an nginx .deb with a custom set of modules from a given version

set -eu

export BASE_VERSION="1.11.13-1~stretch"
export BASE_PACKAGE="nginx"

DEBFULLNAME='Tarjei Husøy (automated)'
DEBEMAIL='apt@thusoy.com'

# Modules to fetch
PCRE_VERSION='8.42'
PCRE_SHA256='2cd04b7c887808be030254e8d77de11d3fe9d4505c39d4b15d2664ffe8bf9301'
PCRE_SOURCE="http://downloads.sourceforge.net/sourceforge/pcre/pcre-$PCRE_VERSION.tar.bz2"

PAM_AUTH_VERSION='1.4'
PAM_AUTH_SHA256='095742c5bcb86f2431e215db785bdeb238d594f085a0ac00d16125876a157409'
PAM_AUTH_SOURCE="https://github.com/stogh/ngx_http_auth_pam_module/archive/v$PAM_AUTH_VERSION.tar.gz"

DOWNLOAD_CACHE="nginx/modules"
PARALLEL_BUILDS=$(nproc)

download_and_check_hash () {
    local url destination checksum
    url=$1
    destination=$2
    checksum=$3
    CHECK="echo '$checksum $destination' | sha256sum --check --status - 2>/dev/null"
    set +e
    eval $CHECK
    local ret=$?
    set -e
    if [ $ret -ne 0 ]; then
        wget --quiet "$url" -O "$destination"
        eval $CHECK
    fi
}

mkdir -p "$DOWNLOAD_CACHE"
download_and_check_hash "$PAM_AUTH_SOURCE" "$DOWNLOAD_CACHE/ngx_http_auth_pam_module.tar.gz" "$PAM_AUTH_SHA256"
download_and_check_hash "$PCRE_SOURCE" "$DOWNLOAD_CACHE/pcre.tar.bz2" "$PCRE_SHA256"

# tar xf "$DOWNLOAD_CACHE/pcre.tar.bz2" -C "$CHROOT_TEMP/modules/"
# mv "$CHROOT_TEMP/modules/pcre-$PCRE_VERSION" "$CHROOT_TEMP/modules/pcre"

# tar xf "$DOWNLOAD_CACHE/ngx_http_auth_pam_module.tar.gz" -C "$CHROOT_TEMP/modules/"
# mv "$CHROOT_TEMP/modules/ngx_http_auth_pam_module-$PAM_AUTH_VERSION" "$CHROOT_TEMP/modules/ngx_http_auth_pam_module"

for dist in stretch; do
    sudo docker build \
        --build-arg BASE_PACKAGE="$BASE_PACKAGE" \
        --build-arg BASE_VERSION="$BASE_VERSION" \
        --build-arg DEBFULLNAME="$DEBFULLNAME" \
        --build-arg DEBEMAIL="$DEBEMAIL" \
        --build-arg DEB_VERSION="$(echo $BASE_VERSION | cut -d- -f1)" \
        -f Dockerfile-$dist \
        -t repo-nginx-$dist \
        .
    sudo docker run "repo-nginx-$dist"
    container_id=$(sudo docker ps -qla)
    sudo docker cp "$container_id:/build/dist" .
    mkdir -p "../dist/$dist"
    cp dist/*.deb ../dist/"$dist/"
    sudo rm -rf dist
done
