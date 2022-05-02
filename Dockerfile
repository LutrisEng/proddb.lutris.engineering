FROM golang:1.18.1-bullseye AS base-golang
FROM debian:bullseye-20220418 AS base-debian

FROM base-golang AS overmind

ARG OVERMIND_VERSION=2.2.2
RUN git clone --branch=v${OVERMIND_VERSION} https://github.com/DarthSim/overmind /overmind
WORKDIR /overmind
RUN go build
RUN ./overmind -v

FROM base-golang AS cockroach

RUN apt-get update
RUN apt-get install -y curl

WORKDIR /cockroach
COPY goarch.go .
RUN go build goarch.go
COPY goos.go .
RUN go build goos.go
ARG COCKROACK_VERSION=21.2.10
RUN echo cockroach-v${COCKROACK_VERSION}.$(./goos)-$(./goarch)
RUN curl https://binaries.cockroachdb.com/cockroach-v${COCKROACK_VERSION}.$(./goos)-$(./goarch).tgz | tar -xz
RUN mv cockroach-v${COCKROACK_VERSION}.$(./goos)-$(./goarch)/cockroach .
RUN ./cockroach version

FROM base-golang AS cloudflared

RUN apt-get update
RUN apt-get install -y curl

WORKDIR /cloudflared
COPY goarch.go .
RUN go build goarch.go
COPY goos.go .
RUN go build goos.go
RUN echo cloudflared-$(./goos)-$(./goarch)
ARG CLOUDFLARED_VERSION=2022.4.1
RUN curl -Lo cloudflared https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-$(./goos)-$(./goarch)
RUN chmod +x cloudflared
RUN ./cloudflared version

FROM base-debian

RUN apt-get update && \
    apt-get install -y tmux iputils-ping netcat-openbsd && \
    apt-get clean

COPY --from=cockroach /cockroach/cockroach /usr/local/bin/
COPY --from=overmind /overmind/overmind /usr/local/bin/
COPY --from=cloudflared /cloudflared/cloudflared /usr/local/bin/

COPY init_cluster.sh /usr/local/bin/
COPY start_fly.sh /usr/local/bin/
COPY cloudflared.sh /usr/local/bin/
COPY Procfile /app/
WORKDIR /app

ENTRYPOINT ["overmind", "start"]
