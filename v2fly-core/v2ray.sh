#!/bin/sh

# Set ARG
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

# Download files
V2RAY_FILE="v2ray-linux-${ARCH}.zip"
DGST_FILE="v2ray-linux-${ARCH}.zip.dgst"
echo "Downloading binary file: ${V2RAY_FILE}"
echo "Downloading binary file: ${DGST_FILE}"

wget -O ${PWD}/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${V2RAY_FILE} > /dev/null 2>&1
wget -O ${PWD}/v2ray.zip.dgst https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${DGST_FILE} > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${V2RAY_FILE} ${DGST_FILE}" && exit 1
fi
echo "Download binary file: ${V2RAY_FILE} ${DGST_FILE} completed"

# Check SHA512
LOCAL=$(openssl dgst -sha512 v2ray.zip | sed 's/([^)]*)//g')
STR=$(cat v2ray.zip.dgst | grep 'SHA512' | head -n1)

if [ "${LOCAL}" = "${STR}" ]; then
    echo " Check passed" && rm -fv v2ray.zip.dgst
else
    echo " Check have not passed yet " && exit 1
fi



# Prepare
echo "Prepare to use"
unzip v2ray.zip && chmod +x v2ray v2ctl
mv v2ray v2ctl /usr/bin/
mv geosite.dat geoip.dat /usr/local/share/v2ray/

LOGLEVEL=$(bashio::config 'loglevel')
PROTOCOL=$(bashio::config 'protocol')
ADDRESS=$(bashio::config 'address')
PORT=$(bashio::config 'port')
ID=$(bashio::config 'id')
ALTERID=$(bashio::config 'alterId')
SECURITY=$(bashio::config 'security')
NETWORK=$(bashio::config 'network')
TYPE=$(bashio::config 'type')

echo -e "{
  \"policy\": {
    \"system\": {
      \"statsOutboundUplink\": true,
      \"statsOutboundDownlink\": true
    }
  },
  \"log\": {
    \"access\": \"\",
    \"error\": \"\",
    \"loglevel\": \"${LOGLEVEL}\"
  },
  \"inbounds\": [
    {
      \"tag\": \"socks\",
      \"port\": 10808,
      \"listen\": \"0.0.0.0\",
      \"protocol\": \"socks\",
      \"sniffing\": {
        \"enabled\": true,
        \"destOverride\": [
          \"http\",
          \"tls\"
        ]
      },
      \"settings\": {
        \"auth\": \"noauth\",
        \"udp\": true,
        \"allowTransparent\": false
      }
    },
    {
      \"tag\": \"http\",
      \"port\": 10809,
      \"listen\": \"0.0.0.0\",
      \"protocol\": \"http\",
      \"sniffing\": {
        \"enabled\": true,
        \"destOverride\": [
          \"http\",
          \"tls\"
        ]
      },
      \"settings\": {
        \"udp\": true,
        \"allowTransparent\": false
      }
    }
  ],
  \"outbounds\": [
    {
      \"tag\": \"proxy\",
      \"protocol\": \"${PROTOCOL}\",
      \"settings\": {
        \"vnext\": [
          {
            \"address\": \"${ADDRESS}\",
            \"port\": ${PORT},
            \"users\": [
              {
                \"id\": \"${ID}\",
                \"alterId\": ${ALTERID},
                \"email\": \"t@t.tt\",
                \"security\": \"${SECURITY}\"
              }
            ]
          }
        ]
      },
      \"streamSettings\": {
        \"network\": \"${NETWORK}\"
      },
      \"mux\": {
        \"enabled\": true,
        \"concurrency\": 8
      }
    },
    {
      \"tag\": \"direct\",
      \"protocol\": \"freedom\",
      \"settings\": {}
    },
    {
      \"tag\": \"block\",
      \"protocol\": \"blackhole\",
      \"settings\": {
        \"response\": {
          \"type\": \"${TYPE}\"
        }
      }
    }
  ],
  \"stats\": {},
  \"routing\": {
    \"domainStrategy\": \"AsIs\",
    \"domainMatcher\": \"linear\",
    \"rules\": [
      {
        \"type\": \"field\",
        \"outboundTag\": \"proxy\",
        \"domain\": [
          \"geosite:google\"
        ]
      },
      {
        \"type\": \"field\",
        \"outboundTag\": \"direct\",
        \"domain\": [
          \"geosite:cn\"
        ]
      },
      {
        \"type\": \"field\",
        \"outboundTag\": \"direct\",
        \"ip\": [
          \"geoip:private\",
          \"geoip:cn\"
        ]
      },
      {
        \"type\": \"field\",
        \"outboundTag\": \"block\",
        \"domain\": [
          \"geosite:category-ads-all\"
        ]
      }
    ]
  }
}" > /etc/v2ray/config.json

# Clean
rm -rf ${PWD}/*
echo "Done"
