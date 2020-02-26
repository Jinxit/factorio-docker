FROM alpine:3

ARG FACTORIO_VERSION
LABEL version=$FACTORIO_VERSION
ENV LATEST_HEADLESS_URL=https://factorio.com/get-download/$FACTORIO_VERSION/headless/linux64

# factorio packages
RUN apk add --update --no-cache git curl wget bash jq bind-tools

# supercronic
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.9/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# aws-cli packages
RUN apk add --no-cache --update \
    python \
    python-dev \
    py-pip \
    build-base \
    && pip install awscli --upgrade \
    && apk --purge -v del py-pip

# glibc compatibility layer for alpine
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk && \
    apk add glibc-2.30-r0.apk && \
    rm -rf glibc-2.30-r0.apk

# factorio user and group
RUN adduser factorio --disabled-password --no-create-home && \
    addgroup factorio factorio && \
    chown factorio:factorio /opt

# download and install
USER factorio
RUN git clone https://github.com/Jinxit/factorio-init /opt/factorio-init
WORKDIR /opt/factorio-init
RUN ./factorio install

COPY --chown=factorio:factorio ./server-settings.json /opt/factorio/data/
COPY --chown=factorio:factorio ./docker-entrypoint.sh /opt/factorio-init/

ENTRYPOINT ["/opt/factorio-init/docker-entrypoint.sh"]
