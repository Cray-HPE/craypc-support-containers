FROM google/cloud-sdk:alpine

ENV PACKER_VERSION=1.6.1

RUN apk add --no-cache bash ca-certificates ansible python gettext libintl qemu qemu-system-x86_64 qemu-img openssh jq rsync coreutils
RUN (wget -qO- https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin/ -) && \
    chmod +x /usr/local/bin/packer

COPY scripts/* /srv/
RUN chmod +x /srv/*.sh

RUN mkdir -p /srv/keys
COPY keys/node-image-builder /srv/keys/
RUN chmod 0600 /srv/keys/*

ENTRYPOINT [""]
