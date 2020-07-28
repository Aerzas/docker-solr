#!/bin/sh
set -e

# No Solr core name specified
if [ -z "${CORE_NAME}" ]; then
  echo "No core name specified."
  exec "$@"
fi

# Solr core already exists
CORE_DIR="${SOLR_HOME:-/opt/solr/server/solr}/${CORE_NAME}"
if [ ! -d "${CORE_DIR}" ] && [ -d "${CORE_DIR}/conf" ] && [ -f "${CORE_DIR}/core.properties" ]; then
  echo "Solr core '${CORE_NAME}' already exists."
fi

# Ensure existing config set
if [ ! -d "${SOLR}/server/solr/configsets/${CORE_CONFIGSET}/" ]; then
  echo "Configset '${CORE_CONFIGSET}' does not exist"
  exit 1
fi

# Create Solr core
if [ ! -d "${CORE_DIR}/conf" ]; then
  mkdir -p "${CORE_DIR}"
  cp -r "${SOLR}/server/solr/configsets/${CORE_CONFIGSET}/"* "${CORE_DIR}/"
fi
touch "${CORE_DIR}/core.properties"
echo "Core '${CORE_NAME}' created."

exec "$@"
