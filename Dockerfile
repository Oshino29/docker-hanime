FROM golang:1.12.0-alpine3.9 as build
#insall git
## start build
RUN mkdir /hanime
COPY hanime /hanime
WORKDIR /hanime
RUN apk add --no-cache git
## Add this go mod download command to pull in any dependencies
RUN go mod download
## Our project will now successfully build with the necessary go libraries included.
RUN go build -o hanime .


## final stage build
FROM alpine:3.9
## prepare ssl cert & ffmepg
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
RUN apk add --no-cache ffmpeg


## prepare root folder, group, user for process
ENV PUID=1000
ENV PGID=1000
RUN mkdir /app && mkdir /app/downloads && \
    addgroup --gid "${PGID}" abc && \
    adduser --uid "${PUID}" \
	    --ingroup abc \
	    --home "/app" \
        --disabled-password \
        --no-create-home \
        abc && \
    chown -R abc:abc /app
USER abc
WORKDIR /app/downloads

## copy compiled go binary to process root
COPY --from=build --chown=$PUID:$PGID /hanime/hanime /app/

## Our start command which kicks off
## our newly created binary executable
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
## CMD will be override when arguments provided to docker run