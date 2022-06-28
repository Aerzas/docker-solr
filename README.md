# Solr

Solr docker container image that requires no specific user or root permission to function.

Docker Hub image: [https://hub.docker.com/r/aerzas/solr](https://hub.docker.com/r/aerzas/solr)

## Docker compose example

```yaml
version: '3.5'
services:
    php:
        image: aerzas/solr:9-latest
        environment:
            CORE_NAME: example
            CORE_CONFIGSET: custom
        volumes:
            - ./config:/opt/solr/server/solr/configsets/custom/conf
            - solr:/var/solr
        ports:
            - '8983:8983'
        healthcheck:
            test: ["CMD", "/scripts/docker-healthcheck.sh"]
            interval: 30s
            timeout: 1s
            retries: 3
            start_period: 5s
volumes:
    solr:
```

## Environment Variables

| Variable                 | Default Value       |
|--------------------------|---------------------|
| **Server**               |                     |
| `ENABLE_REMOTE_JMX_OPTS` | `"false"`           |
| `SOLR_HOST`              | `localhost`         |
| `SOLR_JAVA_MEM`          | `-Xms512m -Xmx512m` |
| `SOLR_PORT`              | `8983`              |
| `SOLR_STOP_WAIT`         | `60`                |
| **Core**                 |                     |
| `CORE_NAME`              | `solr`              |
| `CORE_CONFIGSET`         | `_default`          |

Any Solr variable declared in [solr.in.sh](https://github.com/apache/lucene-solr/blob/master/solr/bin/solr.in.sh) can be
declared as an environment variable.
