FROM google/cloud-sdk:alpine

ENV PACKER_VERSION=1.4.5

RUN apk add --no-cache bash ca-certificates ansible python
RUN (wget -qO- https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin/ -) && \
    chmod +x /usr/local/bin/packer

COPY scripts/build-on-gcp.sh /srv/build-on-gcp.sh
COPY scripts/setup-gcp-instance.sh /srv/setup-gcp-instance.sh
COPY scripts/disable-selinux.sh /srv/disable-selinux.sh
RUN chmod +x /srv/build-on-gcp.sh && \
    chmod +x /srv/setup-gcp-instance.sh && \
    chmod +x /srv/disable-selinux.sh

ENTRYPOINT [""]
