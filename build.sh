#!/bin/sh
set -e

build_version="${1}"
build_solr_version="${2}"
if [ -z "${build_version}" ]; then
  echo 'Build version is required' >&2
  exit 1
fi

registry_image='aerzas/solr'

solr_version() {
  solr_version="${1}"
  if [ -z "${solr_version}" ]; then
    echo 'Solr version is required' >&2
    return 1
  fi

  case ${solr_version} in
  7.7)
    SOLR_VERSION="7.7.3"
    SOLR_SHA512="ca9200c18cc19ab723fd4d10f257e27eb81dc8bc33401ebc4eb99178faf4033a2684f0f8b12ae7b659cfeb0f4c9d9e24aaac518a4e00fd28b69854a359a666ed"
    SOLR_KEYS="CFCE5FBB920C3C745CEEE084C38FF5EC3FCFDB3E"
    ;;
  8.5)
    SOLR_VERSION="8.5.2"
    SOLR_SHA512="02b9b90468f399701dba26695c9af6cd205f47916a06e26838613fe238594e9902de6ef3b42ec8257d195e37589adf8427d9b7962557731e91949fbef06bb544"
    SOLR_KEYS="86EDB9C33B8517228E88A8F93E48C0C6EF362B9E"
    ;;
  *)
    return 1
    ;;
  esac
}

build_solr() {
  solr_version="${1}"
  if [ -z "${solr_version}" ]; then
    echo 'Build Solr version is required' >&2
    return 1
  fi
  solr_version "${solr_version}"
  if [ -z "${SOLR_VERSION}" ]; then
    echo 'Build Solr version is invalid' >&2
    return 1
  fi

  echo "$(printf '\033[32m')Build Solr images ${solr_version}$(printf '\033[m')"

  # Build image
  docker build \
    --build-arg SOLR_VERSION="${SOLR_VERSION}" \
    --build-arg SOLR_SHA512="${SOLR_SHA512}" \
    --build-arg SOLR_KEYS="${SOLR_KEYS}" \
    -t "${registry_image}:${solr_version}-${build_version}" \
    -f Dockerfile \
    . \
    --no-cache

  # Push image
  docker push "${registry_image}:${solr_version}-${build_version}"

  # Remove local image
  docker image rm "${registry_image}:${solr_version}-${build_version}"
}

# Build single SOLR version
if [ -n "${build_solr_version}" ]; then
  build_solr "${build_solr_version}"
# Build all SOLR versions
else
  build_solr 7.7
  build_solr 8.5
fi
