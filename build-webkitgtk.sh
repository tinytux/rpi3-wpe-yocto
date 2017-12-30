#!/bin/bash
#
# Build webkitgtk for Raspberry Pi 3
#

set -o errexit

# git submodule add -b morty http://git.yoctoproject.org/git/poky poky
# git submodule add -b morty http://git.yoctoproject.org/git/meta-raspberrypi meta-raspberrypi
# git submodule add -b morty http://git.openembedded.org/meta-openembedded meta-openembedded
# git submodule add -b morty https://github.com/WebPlatformForEmbedded/meta-wpe meta-wpe
# git submodule add https://github.com/Igalia/meta-webkit meta-webkit

LOCAL_BUILD_DIR="build-webkitgtk"

if [[ -e "${LOCAL_BUILD_DIR}" ]]; then
    echo "${LOCAL_BUILD_DIR} folder already exists. This script works only after a clean checkout."
    exit 1
fi


source poky/oe-init-build-env ${LOCAL_BUILD_DIR}


LOCAL_SOURCE_MIRROR="/opt/yocto/mirror/"
if [[ -e "${LOCAL_SOURCE_MIRROR}" ]]; then
    echo "Using local download mirror: ${LOCAL_SOURCE_MIRROR}"
cat <<EOF >> conf/local.conf

# https://wiki.yoctoproject.org/wiki/How_do_I#Q:_How_do_I_create_my_own_source_download_mirror_.3F
SOURCE_MIRROR_URL ?= "file://${LOCAL_SOURCE_MIRROR}"
INHERIT += "own-mirrors" 
BB_GENERATE_MIRROR_TARBALLS = "1" 
# BB_NO_NETWORK = "1"
EOF
else
    echo "${LOCAL_SOURCE_MIRROR} not found. Local mirror not used."
fi


LOCAL_SSTATE_CACHE="/opt/yocto/sstate/"
if [[ -e "${LOCAL_SSTATE_CACHE}" ]]; then
    echo "Using local sstate cache: ${LOCAL_SSTATE_CACHE}"
cat <<EOF >> conf/local.conf

# https://wiki.yoctoproject.org/wiki/Enable_sstate_cache
SSTATE_DIR ?= "${LOCAL_SSTATE_CACHE}"
EOF
else
    echo "${LOCAL_SSTATE_CACHE} not found. sstate cache not used."
fi


LOCAL_DOWNLOADS="/opt/yocto/downloads/"
if [[ -e "${LOCAL_DOWNLOADS}" ]]; then
    echo "Using local downloads: ${LOCAL_DOWNLOADS}"
cat <<EOF >> conf/local.conf

# http://www.yoctoproject.org/docs/1.6.1/ref-manual/ref-manual.html#var-DL_DIR
DL_DIR ?= "${LOCAL_DOWNLOADS}"
EOF
else
    echo "${LOCAL_SSTATE_CACHE} not found. Local downloads not used."
fi


echo "Adding MACHINE configuration..."
cat <<EOF >> conf/local.conf

# https://github.com/WebPlatformForEmbedded/meta-wpe/wiki/Raspberry-PI
MACHINE = "raspberrypi3"

DISTRO_FEATURES_append = " opengl x11 gles2"
IMAGE_INSTALL_append = " webkitgtk-bin"
PACKAGECONFIG_pn-webkitgtk = "x11 webgl"
PREFERRED_VERSION_webkitgtk = "2.18.0"
#PREFERRED_VERSION_webkitgtk = "2.12.5"
IMAGE_INSTALL_append = " libgl1"

# https://lists.yoctoproject.org/pipermail/yocto/2016-April/029641.html
ENABLE_UART = "1"
EOF

echo "Adding WLAN configuration..."
cat <<EOF >> conf/local.conf
# https://github.com/agherzan/meta-raspberrypi/issues/31#issuecomment-352251597
DISTRO_FEATURES_append = " wifi"
IMAGE_INSTALL_append = " linux-firmware-bcm43430 i2c-tools python-smbus bridge-utils iptables wpa-supplicant"
IMAGE_INSTALL_append = " linux-firmware iw"

EOF

echo "Adding some useful tools..."
cat <<EOF >> conf/local.conf
# epiphany browser
#IMAGE_INSTALL_append = " libsecret-dev libsecret epiphany"

# More tools
IMAGE_INSTALL_append = " vim mc htop wget xeyes xdotool"

# http://www.yoctoproject.org/docs/current/ref-manual/ref-manual.html#var-PACKAGE_EXCLUDE
#PACKAGE_EXCLUDE = " pulseaudio gvim gtk-play"

EOF

echo "Adding bitbake-layers..."
bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-multimedia
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-webkit

echo "Building..."
bitbake core-image-sato

echo "Build done. Write to SD card using the following command:"
echo
echo "    sudo dd if=${LOCAL_BUILD_DIR}/tmp/deploy/images/raspberrypi3/core-image-sato-raspberrypi3.rpi-sdimg of=/dev/mmcblk0 bs=1M"
echo

