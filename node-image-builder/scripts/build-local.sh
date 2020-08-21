#!/bin/bash

set -e

if [ -z "$USERNAME" ]; then
  echo "Error: USERNAME environment variable should be set as username/whoami"
  exit 1
fi

function cleanup() {
  exit_status=$?
  echo "Cleaning up for user ${USERNAME}..."
  ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder node-images-builder@172.30.86.248 /home/node-images-builder/rm-local-build.sh ${USERNAME} || true
  ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder node-images-builder@172.30.86.248 docker rm -f node-images-builder-${USERNAME} || true
  exit $exit_status
}
trap cleanup EXIT

ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder node-images-builder@172.30.86.248 /home/node-images-builder/rm-local-build.sh ${USERNAME} || true

cat > $(pwd)/r.sh <<EOF
#!/bin/bash
$@
chmod -R 0777 ./.artifacts
EOF
chmod +x $(pwd)/r.sh
rsync -avz --exclude .git --exclude .artifacts --exclude packer_cache --delete \
  -e "ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder" \
  $(pwd)/ node-images-builder@172.30.86.248:~/${USERNAME}/

ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder node-images-builder@172.30.86.248 docker rm -f node-images-builder-${USERNAME} || true
ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder node-images-builder@172.30.86.248 /bin/bash -c "cd ~/${USERNAME} && \
  docker run --rm --name node-images-builder-${USERNAME} \
  -v ~/${USERNAME}:/workspace \
  -w /workspace \
  --privileged \
  --cap-add=ALL -v /lib/modules:/lib/modules \
  dtr.dev.cray.com/craypc/node-image-builder:latest ./r.sh"
rm $(pwd)/r.sh

rsync -avz \
  -e "ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no -i /srv/keys/node-image-builder" \
  node-images-builder@172.30.86.248:~/${USERNAME}/.artifacts/ $(pwd)/.artifacts/

exit 0
