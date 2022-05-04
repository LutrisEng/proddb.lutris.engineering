FROM golang:1.18.1-bullseye AS base-golang

WORKDIR /goarchos
COPY goarch.go .
RUN go build goarch.go
COPY goos.go .
RUN go build goos.go
RUN cp goarch goos /usr/local/bin/

FROM debian:bullseye-20220418 AS base-debian

COPY --from=base-golang /usr/local/bin/goos /usr/local/bin/
COPY --from=base-golang /usr/local/bin/goarch /usr/local/bin/

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        curl \
        tmux \
        iputils-arping \
        iputils-clockdiff \
        iputils-ping \
        iputils-tracepath \
        netcat-openbsd \
        iproute2 \
        net-tools \
    && \
    apt-get clean

FROM base-golang AS overmind

ARG OVERMIND_VERSION=2.2.2
RUN git clone --branch=v${OVERMIND_VERSION} https://github.com/DarthSim/overmind /overmind
WORKDIR /overmind
RUN go build
RUN ./overmind -v

FROM base-debian AS cockroach

WORKDIR /cockroach
ARG COCKROACK_VERSION=21.2.10
RUN echo Downloading CockroachDB from https://binaries.cockroachdb.com/cockroach-v${COCKROACK_VERSION}.$(goos)-$(goarch).tgz
RUN curl https://binaries.cockroachdb.com/cockroach-v${COCKROACK_VERSION}.$(goos)-$(goarch).tgz | tar -xz
RUN mv cockroach-v${COCKROACK_VERSION}.$(goos)-$(goarch)/cockroach .
RUN ./cockroach version

FROM base-debian AS cloudflared

WORKDIR /cloudflared
ARG CLOUDFLARED_VERSION=2022.5.0
RUN echo Downloading cloudflared from https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-$(goos)-$(goarch)
RUN curl -Lo cloudflared https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-$(goos)-$(goarch)
RUN chmod +x cloudflared
RUN ./cloudflared version

FROM base-debian

COPY --from=cockroach /cockroach/cockroach /usr/local/bin/
COPY --from=overmind /overmind/overmind /usr/local/bin/
COPY --from=cloudflared /cloudflared/cloudflared /usr/local/bin/

COPY init_cluster.sh /usr/local/bin/
COPY start_fly.sh /usr/local/bin/
COPY cloudflared.sh /usr/local/bin/
COPY run_sql_console.sh /usr/local/bin/
COPY Procfile /app/
WORKDIR /app

ENTRYPOINT ["overmind", "start"]
