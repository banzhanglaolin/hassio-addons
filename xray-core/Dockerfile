# Dockerfile for xray based alpine
# Copyright (C) 2019 - 2021 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/XTLS/Xray-core
# https://github.com/v2fly/v2ray-core
# https://github.com/v2fly/geoip
# https://github.com/v2fly/domain-list-community

FROM --platform=${TARGETPLATFORM} alpine:latest
LABEL maintainer="banzhanglaolin <banzhanglaolin@outlook.com>"

WORKDIR /root
ARG TARGETPLATFORM
ARG TAG
COPY xray.sh /root/xray.sh


RUN set -ex \
	&& apk add --no-cache tzdata openssl ca-certificates \
	&& mkdir -p /var/log/xray /usr/local/share/xray/ \
	&& chmod +x /root/xray.sh \
	&& /root/xray.sh "${TARGETPLATFORM}" "${TAG}"

ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/xray", "-config", "/data/config.json" ]
