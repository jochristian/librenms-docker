FROM alpine:3.10

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="librenms" \
  org.label-schema.description="LibreNMS" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/librenms/docker" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/librenms/docker" \
  org.label-schema.vendor="LibreNMS" \
  org.label-schema.schema-version="1.0"

RUN apk --update --no-cache add \
    busybox-extras \
    acl \
    bash \
    bind-tools \
    binutils \
    ca-certificates \
    coreutils \
    curl \
    fping \
    git \
    graphviz \
    imagemagick \
    ipmitool \
    monitoring-plugins \
    mtr \
    mysql-client \
    net-snmp \
    net-snmp-tools \
    nginx \
    nmap \
    openssl \
    perl \
    php7 \
    php7-cli \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
    php7-json \
    php7-ldap \
    php7-mbstring \
    php7-mcrypt \
    php7-memcached \
    php7-mysqlnd \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-phar \
    php7-posix \
    php7-session \
    php7-simplexml \
    php7-snmp \
    php7-sockets \
    php7-tokenizer \
    php7-xml \
    php7-zip \
    py-mysqldb \
    python \
    py2-pip \
    python3 \
    rrdtool \
    runit \
    shadow \
    su-exec \
    syslog-ng \
    ttf-dejavu \
    tzdata  \
    util-linux \
    whois \
  && pip2 install --upgrade pip \
  && pip2 install python-memcached \
  && pip3 install --upgrade pip \
  && pip3 install python-memcached \
  && wget -q "https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz" -qO "/tmp/s6-overlay-amd64.tar.gz" \
  && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
  && rm -rf /var/cache/apk/* /var/www/* /tmp/* \
  && setcap cap_net_raw+ep /usr/bin/nmap \
  && setcap cap_net_raw+ep /usr/sbin/fping

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  LIBRENMS_VERSION="1.62" \
  LIBRENMS_PATH="/opt/librenms" \
  LIBRENMS_DOCKER="1" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN mkdir -p /opt \
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && git clone --branch ${LIBRENMS_VERSION} https://github.com/librenms/librenms.git ${LIBRENMS_PATH} \
  && COMPOSER_CACHE_DIR="/tmp" composer install --no-dev --no-interaction --no-ansi --working-dir=${LIBRENMS_PATH} \
  && curl -sSLk -q https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro -o /usr/bin/distro \
  && chmod +x /usr/bin/distro \
  && mkdir -p ${LIBRENMS_PATH}/config.d \
  && cp ${LIBRENMS_PATH}/config.php.default ${LIBRENMS_PATH}/config.php \
  && cp ${LIBRENMS_PATH}/snmpd.conf.example /etc/snmp/snmpd.conf \
  && sed -i "1s|.*|#!/usr/bin/env python3|" ${LIBRENMS_PATH}/snmp-scan.py \
  && echo "foreach (glob(\"/data/config/*.php\") as \$filename) include \$filename;" >> ${LIBRENMS_PATH}/config.php \
  && echo "foreach (glob(\"${LIBRENMS_PATH}/config.d/*.php\") as \$filename) include \$filename;" >> ${LIBRENMS_PATH}/config.php \
  && pip3 install -r ${LIBRENMS_PATH}/requirements.txt \
  && chown -R nobody.nogroup ${LIBRENMS_PATH} \
  && rm -rf ${LIBRENMS_PATH}/.git /tmp/*

COPY rootfs /

RUN addgroup -g ${PGID} librenms \
  && adduser -D -h ${LIBRENMS_PATH} -u ${PUID} -G librenms -s /bin/sh -D librenms

EXPOSE 8000 514 514/udp
WORKDIR ${LIBRENMS_PATH}
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
