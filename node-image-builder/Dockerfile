FROM google/cloud-sdk:alpine

ENV PACKER_VERSION=1.4.5

RUN apk add --no-cache -U bash ca-certificates libvirt-daemon qemu-img qemu-system-x86_64 ansible python
RUN (wget -qO- https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin/ -) && \
    chmod +x /usr/local/bin/packer
ENTRYPOINT [""]
