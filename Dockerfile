FROM alpine:3.16.0

ARG SOLR_VERSION
ARG SOLR_SHA512
ARG SOLR_KEYS
ARG SOLR_DOWNLOAD_SERVER
ARG SOLR_DOWNLOAD_URL

ENV PATH="/opt/solr/bin:$PATH" \
    SOLR="/opt/solr" \
    SOLR_DATA_HOME="/var/solr" \
    SOLR_HOME="/opt/solr/server/solr" \
    SOLR_CLOSER_URL="http://www.apache.org/dyn/closer.lua?filename=lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz&action=download" \
    SOLR_DIST_URL="https://www.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz" \
    SOLR_ARCHIVE_URL="https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"

RUN set -ex; \
    # Build dependencies
    apk add --no-cache --virtual .build ca-certificates gnupg wget; \
    # Runtime dependencies
    apk add --no-cache bash openjdk17-jre-headless; \
    # Setup home folder
    GNUPGHOME="/tmp/gnupg_home"; \
    mkdir -p "${GNUPGHOME}"; \
    # Fetch source
    for key in "${SOLR_KEYS}"; do \
        found=''; \
        for server in \
          ha.pool.sks-keyservers.net \
          hkp://keyserver.ubuntu.com:80 \
          hkp://p80.pool.sks-keyservers.net:80 \
          pgp.mit.edu \
        ; do \
          echo "trying ${server} for ${key}"; \
          gpg --batch --keyserver "${server}" --keyserver-options timeout=10 --recv-keys "${key}" && found=yes && break; \
          gpg --batch --keyserver "${server}" --keyserver-options timeout=10 --recv-keys "${key}" && found=yes && break; \
        done; \
        test -z "${found}" && echo >&2 "error: failed to fetch ${key} from several disparate servers -- network issues?" && exit 1; \
    done; \
    # Download Solr
    MAX_REDIRECTS=1; \
    if [ -n "${SOLR_DOWNLOAD_URL}" ]; then \
        MAX_REDIRECTS=4; \
        SKIP_GPG_CHECK=true; \
    elif [ -n "${SOLR_DOWNLOAD_SERVER}" ]; then \
        SOLR_DOWNLOAD_URL="${SOLR_DOWNLOAD_SERVER}/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"; \
    fi; \
    for url in ${SOLR_DOWNLOAD_URL} ${SOLR_CLOSER_URL} ${SOLR_DIST_URL} ${SOLR_ARCHIVE_URL}; do \
        if [ -f "${SOLR}-${SOLR_VERSION}.tgz" ]; then break; fi; \
        echo "downloading ${url}"; \
        if wget -t 10 --max-redirect ${MAX_REDIRECTS} --retry-connrefused -nv "${url}" -O "${SOLR}-${SOLR_VERSION}.tgz"; then break; else rm -f "${SOLR}-${SOLR_VERSION}.tgz"; fi; \
    done; \
    if [ ! -f "${SOLR}-${SOLR_VERSION}.tgz" ]; then echo "failed all download attempts for solr-$SOLR_VERSION.tgz"; exit 1; fi; \
    if [ -z "${SKIP_GPG_CHECK}" ]; then \
        echo "downloading ${SOLR_ARCHIVE_URL}.asc"; \
        wget -nv "${SOLR_ARCHIVE_URL}.asc" -O "${SOLR}-${SOLR_VERSION}.tgz.asc"; \
        echo "${SOLR_SHA512} *${SOLR}-${SOLR_VERSION}.tgz" | sha512sum -c -; \
        (>&2 ls -l "${SOLR}-${SOLR_VERSION}.tgz" "${SOLR}-${SOLR_VERSION}.tgz.asc"); \
        gpg --batch --verify "${SOLR}-${SOLR_VERSION}.tgz.asc" "${SOLR}-${SOLR_VERSION}.tgz"; \
    else \
        echo "Skipping GPG validation due to non-Apache build"; \
    fi; \
    tar -C /opt --extract --file "${SOLR}-${SOLR_VERSION}.tgz"; \
    mv "${SOLR}-${SOLR_VERSION}" "${SOLR}"; \
    rm "${SOLR}-${SOLR_VERSION}.tgz"*; \
    rm -Rf "${SOLR}/docs/" \
        "${SOLR}/dist/{solr-core-${SOLR_VERSION}.jar,solr-solrj-${SOLR_VERSION}.jar,solrj-lib,solr-test-framework-${SOLR_VERSION}.jar,test-framework}"; \
    mkdir -p \
        "${SOLR_DATA_HOME}" \
        "${SOLR_HOME}" \
        "${SOLR}/server/solr/lib" \
        "${SOLR}/server/logs"; \
    # Alpine compatibility
    sed -i -e "s/\"\$(whoami)\" == \"root\"/\$(id -u) == 0/" ${SOLR}/bin/solr; \
    sed -i -e 's/lsof -PniTCP:/lsof -t -PniTCP:/' ${SOLR}/bin/solr; \
    # Execute solr as any user
    chgrp -R 0 \
        "${SOLR}" \
        "${SOLR_DATA_HOME}" \
        "${SOLR_HOME}"; \
    chmod -R g+rwX \
        "${SOLR}" \
        "${SOLR_DATA_HOME}" \
        "${SOLR_HOME}"; \
    # Cleanup
    gpgconf --kill all; \
    apk del .build; \
    rm -r tmp/*

ENV CORE_NAME=solr \
    CORE_CONFIGSET=_default \
    ENABLE_REMOTE_JMX_OPTS=false \
    SOLR_HOST=localhost \
    SOLR_JAVA_MEM="-Xms512m -Xmx512m" \
    SOLR_PORT=8983 \
    SOLR_STOP_WAIT=60

USER 1001

COPY scripts/*.sh /scripts/

WORKDIR "${SOLR_HOME}"
VOLUME "${SOLR_DATA_HOME}"

EXPOSE 8983

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["solr", "-f", "-a", "-XX:+ExitOnOutOfMemoryError"]
