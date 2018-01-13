#!/bin/bash
#
# Build WPE westeros for Raspberry Pi 3
#
# git submodule add -b morty http://git.yoctoproject.org/git/poky poky
# git submodule add -b morty http://git.yoctoproject.org/git/meta-raspberrypi meta-raspberrypi
# git submodule add -b morty http://git.openembedded.org/meta-openembedded meta-openembedded
# git submodule add -b morty https://github.com/WebPlatformForEmbedded/meta-wpe meta-wpe

set -o errexit

function config_append_source_mirror() {
cat <<EOF >> conf/local.conf

# https://wiki.yoctoproject.org/wiki/How_do_I#Q:_How_do_I_create_my_own_source_download_mirror_.3F
SOURCE_MIRROR_URL ?= "file://${1}"
INHERIT += "own-mirrors" 
BB_GENERATE_MIRROR_TARBALLS = "1" 
# BB_NO_NETWORK = "1"
EOF
}

function config_append_sstate_cache() {
cat <<EOF >> conf/local.conf

# https://wiki.yoctoproject.org/wiki/Enable_sstate_cache
SSTATE_DIR ?= "${1}"
EOF
}

function config_append_dl_dir() {
cat <<EOF >> conf/local.conf

# http://www.yoctoproject.org/docs/1.6.1/ref-manual/ref-manual.html#var-DL_DIR
DL_DIR ?= "${1}"
EOF
}

function config_append_machine() {
cat <<EOF >> conf/local.conf

# https://github.com/WebPlatformForEmbedded/meta-wpe/wiki/Raspberry-PI
MACHINE = "raspberrypi3"
DISTRO_FEATURES_remove = "x11"
DISTRO_FEATURES_append = " opengl"

# https://lists.yoctoproject.org/pipermail/yocto/2016-April/029641.html
ENABLE_UART = "1"
EOF
}

function config_append_wlan() {
cat <<EOF >> conf/local.conf
# https://github.com/agherzan/meta-raspberrypi/issues/31#issuecomment-352251597
DISTRO_FEATURES_append = " wifi"
IMAGE_INSTALL_append = " linux-firmware-bcm43430 i2c-tools python-smbus bridge-utils hostapd dhcp-server iptables wpa-supplicant"
IMAGE_INSTALL_append = " linux-firmware iw"

EOF
}

function config_append_tools() {
cat <<EOF >> conf/local.conf
#
IMAGE_INSTALL_append = " vim mc wget htop"
EOF
}

function config_bitbake_layers() {
    bitbake-layers add-layer ../meta-raspberrypi
    bitbake-layers add-layer ../meta-openembedded/meta-oe
    bitbake-layers add-layer ../meta-openembedded/meta-multimedia
    bitbake-layers add-layer ../meta-openembedded/meta-python
    bitbake-layers add-layer ../meta-openembedded/meta-networking
    bitbake-layers add-layer ../meta-wpe
}

function create_config() {
    LOCAL_SOURCE_MIRROR="/opt/yocto/mirror/"
    if [[ -e "${LOCAL_SOURCE_MIRROR}" ]]; then
        echo "Using local download mirror: ${LOCAL_SOURCE_MIRROR}"
        config_append_source_mirror "${LOCAL_SOURCE_MIRROR}"
    else
        echo "${LOCAL_SOURCE_MIRROR} not found. Local mirror not used."
    fi

    LOCAL_SSTATE_CACHE="/opt/yocto/sstate/"
    if [[ -e "${LOCAL_SSTATE_CACHE}" ]]; then
        echo "Using local sstate cache: ${LOCAL_SSTATE_CACHE}"
        config_append_sstate_cache "${LOCAL_SSTATE_CACHE}"
    else
        echo "${LOCAL_SSTATE_CACHE} not found. sstate cache not used."
    fi

    LOCAL_DOWNLOADS="/opt/yocto/downloads/"
    if [[ -e "${LOCAL_DOWNLOADS}" ]]; then
        echo "Using local downloads: ${LOCAL_DOWNLOADS}"
        config_append_dl_dir "${LOCAL_DOWNLOADS}"
    else
        echo "${LOCAL_SSTATE_CACHE} not found. Local downloads not used."
    fi

    echo "Adding MACHINE configuration..."
    config_append_machine
    echo "Adding WLAN configuration..."
    config_append_wlan
    echo "Adding some useful tools..."
    config_append_tools
    echo "Adding bitbake-layers..."
    config_bitbake_layers
}

# ############
# ### MAIN ###
# ############
echo "WPE westeros for Raspberry Pi 3 build script"
echo "~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~"

LOCAL_BUILD_DIR="build-wpe-westeros"
SOURCE_CMD="source poky/oe-init-build-env ${LOCAL_BUILD_DIR}"
echo "${SOURCE_CMD}"
${SOURCE_CMD}

LOCAL_CONF_FILE="${LOCAL_BUILD_DIR}/conf/local.conf"
if [[ -e ${LOCAL_CONF_FILE} ]]; then
    echo "Using existing configuration: ${LOCAL_CONF_FILE}"
else
    echo "Creating new configuration: ${LOCAL_CONF_FILE}"
    create_config
fi

BUILD_CMD="bitbake wpe-westeros-image"
echo "Building..."
echo "${BUILD_CMD}"
${BUILD_CMD}

echo "Build done. Write to SD card using the following command:"
echo
echo "    sudo dd if=${LOCAL_BUILD_DIR}/tmp/deploy/images/raspberrypi3/wpe-westeros-image-raspberrypi3.rpi-sdimg of=/dev/mmcblk0 bs=1M"
echo

