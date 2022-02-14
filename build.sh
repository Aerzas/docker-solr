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
  7)
    SOLR_VERSION="7.7.3"
    SOLR_SHA512="ca9200c18cc19ab723fd4d10f257e27eb81dc8bc33401ebc4eb99178faf4033a2684f0f8b12ae7b659cfeb0f4c9d9e24aaac518a4e00fd28b69854a359a666ed"
    SOLR_KEYS="CFCE5FBB920C3C745CEEE084C38FF5EC3FCFDB3E"
    ;;
  8)
    SOLR_VERSION="8.11.1"
    SOLR_SHA512="4893f836aec84b03d7bfe574e59e305c03b5ede4a48020034fbe81440b8feee79e55fd9ead230e5b89b3f25124e9b56c1ddc4bb5c7f631cf4e846b9cab5f9a45"
    SOLR_KEYS="2CECBFBA181601547B654B9FFA81AC8A490F538E"
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
  build_solr 7
  build_solr 8
fi
