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
# mv config.json /etc/v2ray/config.json

CONFIG="/etc/v2ray/config.json"

bashio::log.info "Creating v2fly-core configuration..."

# Create main config

LOGLEVEL=$(bashio::config 'loglevel')
PROTOCOL=$(bashio::config 'protocol')
ADDRESS=$(bashio::config 'address')
PORT=$(bashio::config 'port')
USERS_ID=$(bashio::config 'users_id')
ALTERID=$(bashio::config 'alterid')
SECURITY=$(bashio::config 'security')
NETWORK=$(bashio::config 'network')

{
    echo"{"
    echo"  "policy": {"
    echo"      "statsOutboundUplink": true,"
    echo"      "statsOutboundDownlink": true"
    echo"    }"
    echo"  },"
    echo"  "log": {"
    echo"    "access": "","
    echo"    "error": "","
    echo"    "loglevel": "${LOGLEVEL}""
    echo"  },"
    echo"  "inbounds": ["
    echo"    {"
    echo"      "tag": "socks","
    echo"      "port": 10808,"
    echo"      "listen": "0.0.0.0","
    echo"      "protocol": "socks","
    echo"      "sniffing": {"
    echo"        "enabled": true,"
    echo"        "destOverride": ["
    echo"          "http","
    echo"          "tls""
    echo"        ]"
    echo"      },"
    echo"      "settings": {"
    echo"        "auth": "noauth","
    echo"        "udp": true,"
    echo"        "allowTransparent": false"
    echo"      }"
    echo"    },"
    echo"    {"
    echo"      "tag": "http","
    echo"      "port": 10809,"
    echo"      "listen": "0.0.0.0","
    echo"      "protocol": "http","
    echo"      "sniffing": {"
    echo"        "enabled": true,"
    echo"        "destOverride": ["
    echo"          "http","
    echo"          "tls""
    echo"        ]"
    echo"      },"
    echo"      "settings": {"
    echo"        "udp": false,"
    echo"        "allowTransparent": false"
    echo"      }"
    echo"    }"
    echo"  ],"
    echo"  "outbounds": ["
    echo"    {"
    echo"      "tag": "proxy","
    echo"      "protocol": "${PROTOCOL}","
    echo"      "settings": {"
    echo"        "vnext": ["
    echo"          {"
    echo"            "address": "${ADDRESS}","
    echo"            "PORT": ${PORT},"
    echo"            "users": ["
    echo"              {"
    echo"                "id": "${USERS_ID}","
    echo"                "alterId": ${ALTERID},"
    echo"                "email": "t@t.tt","
    echo"                "security": "none${SECURITY}""
    echo"              }"
    echo"            ]"
    echo"          }"
    echo"        ]"
    echo"      },"
    echo"      "streamSettings": {"
    echo"        "network": "${NETWORK}""
    echo"      },"
    echo"      "mux": {"
    echo"        "enabled": true,"
    echo"        "concurrency": 8"
    echo"      }"
    echo"    },"
    echo"    {"
    echo"      "tag": "direct","
    echo"      "protocol": "freedom","
    echo"      "settings": {}"
    echo"    },"
    echo"    {"
    echo"      "tag": "block","
    echo"      "protocol": "blackhole","
    echo"      "settings": {"
    echo"        "response": {"
    echo"          "type": "http""
    echo"        }"
    echo"      }"
    echo"    }"
    echo"  ],"
    echo"  "stats": {},"
    echo"  "routing": {"
    echo"    "domainStrategy": "AsIs","
    echo"    "domainMatcher": "linear","
    echo"    "rules": ["
    echo"      {"
    echo"        "type": "field","
    echo"        "outboundTag": "proxy","
    echo"        "domain": ["
    echo"          "geosite:google""
    echo"        ]"
    echo"      },"
    echo"      {"
    echo"        "type": "field","
    echo"        "outboundTag": "direct","
    echo"        "domain": ["
    echo"          "geosite:cn""
    echo"        ]"
    echo"      },"
    echo"      {"
    echo"        "type": "field","
    echo"        "outboundTag": "direct","
    echo"        "ip": ["
    echo"          "geoip:private","
    echo"          "geoip:cn""
    echo"        ]"
    echo"      },"
    echo"      {"
    echo"        "type": "field","
    echo"        "outboundTag": "block","
    echo"        "domain": ["
    echo"          "geosite:category-ads-all""
    echo"        ]"
    echo"      }"
    echo"    ]"
    echo"  }"
    echo"}"  
} > "${CONFIG}"

# Clean
rm -rf ${PWD}/*
echo "Done"
