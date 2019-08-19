# Default dcrd version should be latest stable release
ARG DCRD_VERSION=1.4.0
# Since master branch of the drcd repo is continuously updated
# by default we should use the latest stable release branch
ARG DCRD_REPO_BRANCH=release-v1.4
# Default Go version should be the latest officially tested with dcrd
# built for/on chosen production OS e.g. <dcrd-tested-golang-version>-<production-OS>
ARG GOLANG_IMAGE_TAG=1.12-alpine
# Production OS must work with BusyBox and apk for this Dockerfile to work
ARG PROD_OS=alpine
# Default Production OS version should be the lastest officially tested with dcrd
# e.g. For alpine see https://github.com/decred/dcrd/blob/master/Dockerfile.alpine
# See https://hub.docker.com/_/golang?tab=description&page=4 for more details.
ARG PROD_OS_TAG=3.10.1

FROM alpine/git as git

LABEL description="Production dcrd + dcrctl built from Go source repos onto alpine image"
LABEL version=${DCRD_VERSION}
LABEL maintainer="dominus"

####MAYBE#### Clear alpine/git ENTRYPOINT and CMD to enable RUN with it
####MAYBE#### ENTRYPOINT []
####MAYBE#### CMD []

#WORKDIR //dcrd
#RUN \
ARG DCRD_REPO_BRANCH
ENV DCRD_REPO_BRANCH=${DCRD_REPO_BRANCH}
RUN echo $DCRD_REPO_BRANCH
RUN echo ${DCRD_REPO_BRANCH}
#RUN ["git", "clone", "-b", "$DCRD_REPO_BRANCH", "https://github.com/decred/dcrd.git"]
#RUN git clone -b $DCRD_REPO_BRANCH https://github.com/decred/dcrd.git
# git clone -b release-v1.4 https://github.com/decred/dcrd.git
# RUN git clone -b "$DCRD_REPO_BRANCH" https://github.com/decred/dcrd.git
RUN git clone https://github.com/decred/dcrd.git
RUN git checkout "${DCRD_REPO_BRANCH}"

FROM golang:${GOLANG_IMAGE_TAG} as go

#
# NOTE: The RPC server listens on localhost by default.
#       If you require access to the RPC server,
#       rpclisten should be set to an empty value.
#
# NOTE: When running simnet, you may not want to preserve
#       the data and logs.  This can be achieved by specifying
#       a location outside the default ~/.dcrd.  For example:
#          rpclisten=
#          simnet=1
#          datadir=~/simnet-data
#          logdir=~/simnet-logs
#
# Example testnet instance with RPC server access:
# $ mkdir -p /local/path/dcrd
#
# Place a dcrd.conf into a local directory, i.e. /var/dcrd
# $ mv dcrd.conf /var/dcrd
#
# Verify basic configuration
# $ cat /var/dcrd/dcrd.conf
# rpclisten=
# testnet=1
#
# Run the docker image, mapping the testnet dcrd RPC port.
# $ docker run -d --rm -p 127.0.0.1:19109:19109 -v /var/dcrd:/root/.dcrd user/dcrd
#

WORKDIR /go/src/github.com/decred/dcrd
COPY --from=git git/dcrd/* .

RUN CGO_ENABLED=0 GOOS=linux GO111MODULE=on go install . ./cmd/...

# Production image
## alpine version matched with latest tested release on 
## https://github.com/decred/dcrd/blob/master/Dockerfile.alpine
## FROM alpine:3.10.1
FROM ${PROD_OS}:${PROD_OS_TAG}

#
# Build command
# docker build -t alpine/go-dcrd:v1.4.0
#

# Prep OS config
## Decred general info
####MAY NO LONGER NEED: ENV DECRED_VERSION v1.4.0
ENV DECRED_USER decred
ENV DECRED_GROUP decred
ENV DECRED_INSTALL /usr/local/decred
ENV DECRED_HOME /home/decred
## Decred working directories
ENV DCRD_HOME $DECRED_HOME/.dcrd
ENV DCRCTL_HOME $DECRED_HOME/.dcrctl
ENV DCRWALLET_HOME $DECRED_HOME/.dcrwallet

# Set up OS packages, users, groups, and other OS config
RUN \
    # get packages
    ## permanent packages
    apk add --no-cache ca-certificates \
    ## temporary packages
    && apk add --no-cache -t build_deps bash shadow \
    # add our user and group first to make sure their IDs get assigned consistently
    && set -x \
    && groupadd -r $DECRED_GROUP && useradd -r -m -g $DECRED_GROUP $DECRED_USER \
    # Set correct rights on executables
    ####UNTESTED####&& chown -R $DECRED_USER.$DECRED_USER bin \
    && chown -R root.root bin \
    && chmod -R 755 bin \
    # Cleanup
    && set +x \
    && apk del --purge build_deps \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

COPY --from=go /go/bin/* $DECRED_INSTALL/bin/

ENV PATH $PATH:$DECRED_INSTALL/bin

USER $DECRED_USER

# Working directories
RUN mkdir $DCRD_HOME $DCRCTL_HOME $DCRWALLET_HOME \
    && chmod -R 700 $DECRED_HOME
WORKDIR $DECRED_HOME

# Peer & RPC ports
## mainnet
EXPOSE 9108 9109

## testnet
EXPOSE 19108 19109

## simnet
EXPOSE 18555 19556

####Maybe not needed since we have WORKDIR above: CMD [ "dcrd" ]