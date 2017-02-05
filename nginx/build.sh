#!/bin/sh

# Build an nginx .deb with a custom set of modules from a given version

set -eu

if [ $(id -u) != "0" ]; then
    echo 'This script must be run as root'
    exit 1
fi

BASE_VERSION="1.11.9-1~jessie"
BASE_PACKAGE="nginx"

DEBFULLNAME='Tarjei Husøy (automated)'
DEBEMAIL='apt@thusoy.com'

# Modules to fetch
MORE_HEADERS_VERSION='0.28'
MORE_HEADERS_SHA256='67e5ca6cd9472938333c4530ab8c8b8bc9fe910a8cb237e5e5f1853e14725580'
MORE_HEADERS_SOURCE="https://github.com/openresty/headers-more-nginx-module/archive/v$MORE_HEADERS_VERSION.tar.gz"

PCRE_VERSION='8.37'
PCRE_SHA256='51679ea8006ce31379fb0860e46dd86665d864b5020fc9cd19e71260eef4789d'
PCRE_SOURCE="http://downloads.sourceforge.net/sourceforge/pcre/pcre-$PCRE_VERSION.tar.bz2"

PAM_AUTH_VERSION='1.4'
PAM_AUTH_SHA256='095742c5bcb86f2431e215db785bdeb238d594f085a0ac00d16125876a157409'
PAM_AUTH_SOURCE="https://github.com/stogh/ngx_http_auth_pam_module/archive/v$PAM_AUTH_VERSION.tar.gz"

CHROOT_BASE="/repocache"
DOWNLOAD_CACHE="/var/cache/repo/nginx"
REPO="https://nginx.org/packages/mainline/debian/ jessie nginx"
# key from https://nginx.org/keys/nginx_signing.key
REPO_KEY='-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.22 (GNU/Linux)

mQENBE5OMmIBCAD+FPYKGriGGf7NqwKfWC83cBV01gabgVWQmZbMcFzeW+hMsgxH
W6iimD0RsfZ9oEbfJCPG0CRSZ7ppq5pKamYs2+EJ8Q2ysOFHHwpGrA2C8zyNAs4I
QxnZZIbETgcSwFtDun0XiqPwPZgyuXVm9PAbLZRbfBzm8wR/3SWygqZBBLdQk5TE
fDR+Eny/M1RVR4xClECONF9UBB2ejFdI1LD45APbP2hsN/piFByU1t7yK2gpFyRt
97WzGHn9MV5/TL7AmRPM4pcr3JacmtCnxXeCZ8nLqedoSuHFuhwyDnlAbu8I16O5
XRrfzhrHRJFM1JnIiGmzZi6zBvH0ItfyX6ttABEBAAG0KW5naW54IHNpZ25pbmcg
a2V5IDxzaWduaW5nLWtleUBuZ2lueC5jb20+iQE+BBMBAgAoAhsDBgsJCAcDAgYV
CAIJCgsEFgIDAQIeAQIXgAUCV2K1+AUJGB4fQQAKCRCr9b2Ce9m/YloaB/9XGrol
kocm7l/tsVjaBQCteXKuwsm4XhCuAQ6YAwA1L1UheGOG/aa2xJvrXE8X32tgcTjr
KoYoXWcdxaFjlXGTt6jV85qRguUzvMOxxSEM2Dn115etN9piPl0Zz+4rkx8+2vJG
F+eMlruPXg/zd88NvyLq5gGHEsFRBMVufYmHtNfcp4okC1klWiRIRSdp4QY1wdrN
1O+/oCTl8Bzy6hcHjLIq3aoumcLxMjtBoclc/5OTioLDwSDfVx7rWyfRhcBzVbwD
oe/PD08AoAA6fxXvWjSxy+dGhEaXoTHjkCbz/l6NxrK3JFyauDgU4K4MytsZ1HDi
MgMW8hZXxszoICTTiQEcBBABAgAGBQJOTkelAAoJEKZP1bF62zmo79oH/1XDb29S
YtWp+MTJTPFEwlWRiyRuDXy3wBd/BpwBRIWfWzMs1gnCjNjk0EVBVGa2grvy9Jtx
JKMd6l/PWXVucSt+U/+GO8rBkw14SdhqxaS2l14v6gyMeUrSbY3XfToGfwHC4sa/
Thn8X4jFaQ2XN5dAIzJGU1s5JA0tjEzUwCnmrKmyMlXZaoQVrmORGjCuH0I0aAFk
RS0UtnB9HPpxhGVbs24xXZQnZDNbUQeulFxS4uP3OLDBAeCHl+v4t/uotIad8v6J
SO93vc1evIje6lguE81HHmJn9noxPItvOvSMb2yPsE8mH4cJHRTFNSEhPW6ghmlf
Wa9ZwiVX5igxcvaIRgQQEQIABgUCTk5b0gAKCRDs8OkLLBcgg1G+AKCnacLb/+W6
cflirUIExgZdUJqoogCeNPVwXiHEIVqithAM1pdY/gcaQZmIRgQQEQIABgUCTk5f
YQAKCRCpN2E5pSTFPnNWAJ9gUozyiS+9jf2rJvqmJSeWuCgVRwCcCUFhXRCpQO2Y
Va3l3WuB+rgKjsQ=
=EWWI
-----END PGP PUBLIC KEY BLOCK-----
'

CHROOT_TEMP=$(mktemp -d --tmpdir="$CHROOT_BASE/tmp")
trap 'rm -rf $CHROOT_TEMP' INT TERM EXIT
DEB_VERSION=$(echo $BASE_VERSION | cut -d- -f1)
PARALLEL_BUILDS=$(nproc)


BUILD_SCRIPT="
set -eux
export LC_ALL=C
cd /tmp/$(basename $CHROOT_TEMP)
apt-get install apt-transport-https devscripts libpam0g-dev -y
apt-key add ./nginx-repo-key
apt-get update
apt-get build-dep -y $BASE_PACKAGE=$BASE_VERSION
apt-get source $BASE_PACKAGE=$BASE_VERSION
cp \"nginx-$DEB_VERSION/debian/rules\" /tmp/rules
cp ./rules \"nginx-$DEB_VERSION/debian/rules\"
cd \"nginx-$DEB_VERSION\"
DEBFULLNAME='$DEBFULLNAME' DEBEMAIL='$DEBEMAIL' dch --nmu 'Package new version'
debuild -eDEB_BUILD_OPTIONS=\"parallel=$PARALLEL_BUILDS\" -i -us -uc -b
mv ../*.deb /tmp/
"

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

cp nginx/rules "$CHROOT_TEMP/rules"
echo "$BUILD_SCRIPT" > "$CHROOT_BASE/build.sh"
chmod +x "$CHROOT_BASE/build.sh"
echo "deb $REPO" > "$CHROOT_BASE/etc/apt/sources.list.d/nginx.list"
echo "deb-src $REPO" > "$CHROOT_BASE/etc/apt/sources.list.d/nginx.list"
echo "$REPO_KEY" > "$CHROOT_TEMP/nginx-repo-key"

# Download modules to compile in
mkdir -p "$CHROOT_TEMP/modules" "$DOWNLOAD_CACHE"
download_and_check_hash "$PAM_AUTH_SOURCE" "$DOWNLOAD_CACHE/ngx_http_auth_pam_module.tar.gz" "$PAM_AUTH_SHA256"
download_and_check_hash "$MORE_HEADERS_SOURCE" "$DOWNLOAD_CACHE/ngx_headers_more_module.tar.gz" "$MORE_HEADERS_SHA256"
download_and_check_hash "$PCRE_SOURCE" "$DOWNLOAD_CACHE/pcre.tar.bz2" "$PCRE_SHA256"

tar xf "$DOWNLOAD_CACHE/pcre.tar.bz2" -C "$CHROOT_TEMP/modules/"
mv "$CHROOT_TEMP/modules/pcre-$PCRE_VERSION" "$CHROOT_TEMP/modules/pcre"

tar xf "$DOWNLOAD_CACHE/ngx_http_auth_pam_module.tar.gz" -C "$CHROOT_TEMP/modules/"
mv "$CHROOT_TEMP/modules/ngx_http_auth_pam_module-$PAM_AUTH_VERSION" "$CHROOT_TEMP/modules/ngx_http_auth_pam_module"

tar xf "$DOWNLOAD_CACHE/ngx_headers_more_module.tar.gz" -C "$CHROOT_TEMP/modules/"
mv "$CHROOT_TEMP/modules/headers-more-nginx-module-$MORE_HEADERS_VERSION" "$CHROOT_TEMP/modules/ngx_headers_more_module"

sudo chroot "$CHROOT_BASE" /build.sh
cp "$CHROOT_BASE/tmp/"nginx_*.deb dist/
