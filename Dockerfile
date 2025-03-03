# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

FROM ubuntu:18.04

LABEL version="1.0" description="Geniux builder" maintainer="carles.fernandez@cttc.es"

# build with "docker build --build-arg PETA_VERSION=2020.1 --build-arg PETA_RUN_FILE=petalinux-v2020.1-final-installer.run -t docker_petalinux2:2020.1 ."
# or "docker build --build-arg PETA_VERSION=2020.1 --build-arg PETA_RUN_FILE=petalinux-v2020.1-final-installer.run --build-arg VIVADO_INSTALLER=Xilinx_Unified_2020.1_0602_1208.tar.gz -t docker_petalinux2:2020.1 ."

# install dependences:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  autoconf \
  bc \
  bison \
  build-essential \
  ca-certificates \
  chrpath \
  cpio \
  curl \
  dbus \
  dbus-x11 \
  debianutils \
  diffstat \
  expect \
  flex \
  fonts-droid-fallback \
  fonts-ubuntu-font-family-console \
  gawk \
  gcc-multilib \
  git \
  gnupg \
  gtk2-engines \
  gzip \
  iproute2 \
  iputils-ping \
  kmod \
  lib32z1-dev \
  libegl1-mesa \
  libglib2.0-dev \
  libgtk2.0-0 \
  libjpeg62-dev \
  libncurses5-dev \
  libsdl1.2-dev \
  libselinux1 \
  libssl-dev \
  libtool \
  libtool-bin \
  locales \
  lsb-release \
  lxappearance \
  nano \
  net-tools \
  pax \
  pylint3 \
  python3 \
  python3-pexpect \
  python3-pip \
  python3-git \
  python3-jinja2 \
  repo \
  rsync \
  screen \
  socat \
  sudo \
  texinfo \
  tftpd \
  tofrodos \
  ttf-ubuntu-font-family \
  u-boot-tools \
  ubuntu-gnome-default-settings \
  unzip \
  update-inetd \
  wget \
  xorg \
  xterm \
  xvfb \
  xxd \
  zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  zlib1g:i386 libc6-dev:i386 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG PETA_VERSION
ARG PETA_RUN_FILE

RUN locale-gen en_US.UTF-8 && update-locale

# make a petalinux user
RUN adduser --disabled-password --gecos '' petalinux && \
  usermod -aG sudo petalinux && \
  echo "petalinux ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY accept-eula.sh ${PETA_RUN_FILE} /

# run the install
RUN chmod a+rx /${PETA_RUN_FILE} && \
  chmod a+rx /accept-eula.sh && \
  mkdir -p /opt/Xilinx && \
  chmod 777 /tmp /opt/Xilinx && \
  cd /tmp && \
  sudo -u petalinux -i /accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux && \
  rm -f /${PETA_RUN_FILE} /accept-eula.sh

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
# not really necessary, just to make it easier to install packages on the run...
RUN echo "root:petalinux" | chpasswd

USER petalinux
ENV HOME /home/petalinux
ENV LANG en_US.UTF-8
RUN mkdir /home/petalinux/project
WORKDIR /home/petalinux/project
ENV SHELL /bin/bash

# add petalinux tools to path

# Source settings at login
USER root

RUN echo "/usr/sbin/in.tftpd --foreground --listen --address [::]:69 --secure /tftpboot" >> /etc/profile && \
  echo ". /opt/Xilinx/petalinux/settings.sh" >> /etc/profile && \
  if [ "$VIVADO_INSTALLER" ] ; then \
    echo ". /tools/Xilinx/Vivado/${PETA_VERSION}/settings64.sh" >> /etc/profile ; \
  fi && \
  echo ". /etc/profile" >> /root/.profile

EXPOSE 69/udp

USER petalinux

ENTRYPOINT ["/bin/bash", "-l"]
