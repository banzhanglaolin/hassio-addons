#!/bin/sh
#
# This is a Shell script for xray based alpine with Docker image
# 
# Copyright (C) 2019 - 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/XTLS/Xray-core

PLATFORM=$1
TAG=$2
if [ -z "$PLATFORM" ]; then
    ARCH="64"
else
    case "$PLATFORM" in
        linux/386)
            ARCH="32"
            ;;
        linux/amd64)
            ARCH="64"
            ;;
        linux/arm/v6)
            ARCH="arm32-v6"
            ;;
        linux/arm/v7)
            ARCH="arm32-v7a"
            ;;
        linux/arm64|linux/arm64/v8)
            ARCH="arm64-v8a"
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1

# Download binary file
XRAY_FILE="Xray-linux-${ARCH}.zip"
DGST_FILE="Xray-linux-${ARCH}.zip.dgst"
echo "Downloading binary file: ${XRAY_FILE}"
echo "Downloading binary file: ${DGST_FILE}"

wget -O ${PWD}/xray.zip https://github.com/XTLS/Xray-core/releases/download/${TAG}/${XRAY_FILE} > /dev/null 2>&1
wget -O ${PWD}/xray.zip.dgst https://github.com/XTLS/Xray-core/releases/download/${TAG}/${DGST_FILE} > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${XRAY_FILE} ${DGST_FILE}" && exit 1
fi
echo "Download binary file: ${XRAY_FILE} ${DGST_FILE} completed"

LOCAL=$(openssl dgst -sha512 xray.zip | sed 's/([^)]*)//g')
STR=$(cat xray.zip.dgst | grep 'SHA512' | head -n1)

if [ "${LOCAL}" = "${STR}" ]; then
    echo " Check passed" && rm -fv xray.zip.dgst
else
    echo " Check have not passed yet " && exit 1
fi

# Prepare
echo "Prepare to use"
unzip xray.zip && chmod +x xray
mv xray /usr/bin/
mv geosite.dat geoip.dat /usr/local/share/xray/


# Clean
rm -rf ${PWD}/*
echo "Done"
