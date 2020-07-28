#!/bin/sh
set -e

wget --spider --quiet --tries=1 "http://${SOLR_HOST}:${SOLR_PORT}/solr/${CORE_NAME}/admin/ping" && exit 0

exit 1
