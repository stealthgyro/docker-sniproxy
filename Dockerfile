FROM lsiobase/ubuntu:bionic
#FROM ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="stealthgyro"

# global environment settings
ENV DEBIAN_FRONTEND="noninteractive"

# Creating Directories
RUN mkdir -p \
	/config
RUN mkdir -p \
	/var/log/sniproxy

# Installing dependencies
RUN apt-get update
RUN apt-get install -y git autotools-dev cdbs debhelper dh-autoreconf dpkg-dev gettext libev-dev libpcre3-dev libudns-dev pkg-config fakeroot

# Installing UDNS dependency
RUN mkdir -p /usr/src/udns
WORKDIR /usr/src/udns
RUN curl -O http://archive.ubuntu.com/ubuntu/pool/universe/u/udns/udns_0.4-1.dsc
RUN curl -O http://archive.ubuntu.com/ubuntu/pool/universe/u/udns/udns_0.4.orig.tar.gz
RUN curl -O http://archive.ubuntu.com/ubuntu/pool/universe/u/udns/udns_0.4-1.debian.tar.gz
RUN tar xfz udns_0.4.orig.tar.gz
WORKDIR /usr/src/udns/udns-0.4
RUN tar xfz ../udns_0.4-1.debian.tar.gz
RUN dpkg-buildpackage
WORKDIR /usr/src/udns
RUN dpkg -i libudns-dev_0.4-1_amd64.deb libudns0_0.4-1_amd64.deb

# Installing sniproxy
WORKDIR /usr/src/sniproxy
RUN git clone https://github.com/dlundquist/sniproxy /usr/src/sniproxy
RUN ./autogen.sh && dpkg-buildpackage
RUN dpkg -i /usr/src/sniproxy_$(cat setver.sh | grep 'VERSION=[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' | sed s/VERSION=//)_amd64.deb

# not 100%
WORKDIR /root
# add local files
COPY root/ /

# Cleaning installation dirs (smaller image), requires docker-squash
RUN \
echo "**** cleanup ****" && \
apt-get purge -y \
	autotools-dev \
	cdbs \
	debhelper \
	dh-autoreconf \
	dpkg-dev \
	gettext \
	libev-dev \
	libpcre3-dev \
	libudns-dev \
	pkg-config \
	fakeroot && \
apt-get --purge autoremove -y && \
apt-get clean && \
rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*
RUN rm -rf /usr/src/

EXPOSE 80 443

WORKDIR /config
VOLUME /config

