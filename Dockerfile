FROM openjdk:8-jdk-alpine
MAINTAINER Eager Minds

# Environment vars
ENV BITBUCKET_HOME      /var/atlassian/application-data/bitbucket
ENV BITBUCKET_INSTALL   /opt/atlassian/bitbucket
ENV BITBUCKET_VERSION   5.9.0
ENV MYSQL_VERSION 5.1.45
ENV POSTGRES_VERSION 42.1.4

ENV RUN_USER             root
ENV RUN_GROUP            root

ARG DOWNLOAD_URL=https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_JAR=mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}-bin.jar
ARG OLD_POSTGRES_CONNECTOR_JAR=postgresql-9.1-903.jdbc4-atlassian-hosted.jar
ARG POSTGRES_CONNECTOR_DOWNLOAD_URL=https://jdbc.postgresql.org/download/postgresql-${POSTGRES_VERSION}.jar
ARG POSTGRES_CONNECTOR_JAR=postgresql-${POSTGRES_VERSION}.jar

# Print executed commands
RUN set -x

# Install requeriments
RUN apk update -qq
RUN update-ca-certificates
RUN apk add --no-cache    ca-certificates wget curl openssh bash procps openssl perl ttf-dejavu tini git git-daemon

# Bitbucket set up
RUN rm -rf                /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/*
RUN mkdir -p               "${BITBUCKET_HOME}"
RUN chmod -R 700           "${BITBUCKET_HOME}"
RUN mkdir -p               "${BITBUCKET_INSTALL}"
RUN curl -Ls              ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "$BITBUCKET_INSTALL"
RUN ls -la                "${BITBUCKET_INSTALL}/bin"

# Database connectors
RUN curl -Ls               "${MYSQL_CONNECTOR_DOWNLOAD_URL}"   \
     | tar -xz --directory "${BITBUCKET_INSTALL}/lib"               \
                           "${MYSQL_CONNECTOR_JAR}"            \
                           --strip-components=1 --no-same-owner
RUN rm -f                  "${BITBUCKET_INSTALL}/lib/${OLD_POSTGRES_CONNECTOR_JAR}"
RUN curl -Ls               "${POSTGRES_CONNECTOR_DOWNLOAD_URL}" -o "${BITBUCKET_INSTALL}/lib/${POSTGRES_CONNECTOR_JAR}"


USER root:root

# Expose HTTP and SSH ports
EXPOSE 7990
EXPOSE 7999

VOLUME ["/var/atlassian/application-data/bitbucket", "/opt/atlassian/bitbucket/logs"]

WORKDIR $BITBUCKET_HOME

COPY . /tmp
COPY "entrypoint.sh" "/"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh", "-fg"]
