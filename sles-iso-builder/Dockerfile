# MIT License
#
# (C) Copyright [2021] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

FROM arti.dev.cray.com/baseos-docker-master-local/sles15sp1:sles15sp1-build411 AS base

RUN zypper --non-interactive ar -G http://download.buildservice.us.cray.com/devel:/languages:/go/SLE_15_SP1/ SLE_15_SP1_GO

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000

ENV HOME /home/${user}
RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -m ${user}

CMD ["/bin/bash"]

FROM base as product

RUN zypper ar http://car.dev.cray.com/artifactory/shasta-standard/DST/sle15_ncn/x86_64/dev/master car-install-repo \
  && zypper --no-gpg-check -n install car-install-crayctldeploy \
  && zypper removerepo car-install-repo \
  && zypper --non-interactive ar -G http://car.dev.cray.com/artifactory/mirror-opensuse/ opensuse \
  && zypper refresh

RUN zypper --no-gpg-check -n install \
  make \
  go \
  gcc \
  gcc-c++ \
  coreutils \
  util-linux \
  kernel-headers \
  kernel-devel \
  openssl-devel \
  python-devel \
  git \
  which \
  unzip \
  wget \
  rsync \
  rpm \
  make \
  vim \
  sudo \
  mailx \
  lvm2 \
  python-setuptools \
  python-yaml \
  openssl \
  pam-devel \
  libtool \
  automake \
  autoconf \
  rpm-build \
  xfsprogs \
  python-requests \
  curl \
  openssh \
  createrepo_c \
  python \
  python3 \
  python-pip \
  java \
  rpmlint \
  sshpass \
  mksusecd \
  xorriso \
  gzip

RUN wget http://download.opensuse.org/repositories/home:/cabelo/SLE_15_SP1/x86_64/git-lfs-2.4.2-10.1.x86_64.rpm \
  && zypper -n --no-gpg-checks install git-lfs*rpm \
  && rm git-lfs*rpm

RUN sudo -H python3 -m ensurepip
