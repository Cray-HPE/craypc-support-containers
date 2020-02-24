#!/bin/bash

packer_version="$1"

echo "Installing Packer"
wget -q https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip
unzip packer_${packer_version}_linux_amd64.zip
sudo mv packer /usr/local/bin/packerio
chmod +x /usr/local/bin/packerio
rm packer_${packer_version}_linux_amd64.zip

echo "Adding shasta-cd-repo disk to instance"
project_id=$(curl -s http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
zone=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | sed 's:.*/::')
instance_name=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/name -H "Metadata-Flavor: Google")
access_token=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" -s | python3 -c \
  'import sys; import json; print(json.loads(sys.stdin.read())["access_token"])')
cat > /tmp/create-disk.json <<EOF
{
  "name": "$(hostname)-shasta-cd-repo",
  "sizeGb": "1024",
  "sourceImage": "projects/vshasta-cray/global/images/family/vshasta-shasta-cd-repo"
}
EOF
curl -X POST -H "Authorization: Bearer ${access_token}" -H "Content-Type: application/json" -d @/tmp/create-disk.json \
  https://compute.googleapis.com/compute/beta/projects/${project_id}/zones/${zone}/disks
cat > /tmp/attach-disk.json <<EOF
{
  "source": "/compute/v1/projects/${project_id}/zones/${zone}/disks/$(hostname)-shasta-cd-repo",
  "autoDelete": true
}
EOF
echo "Waiting for disk to be ready to be attached..."
sleep 5
result=""
while ! echo $result | grep "RUNNING" &>/dev/null; do
  result=$(curl -s -X POST -H "Authorization: Bearer ${access_token}" -H "Content-Type: application/json" -d @/tmp/attach-disk.json \
    https://compute.googleapis.com/compute/v1/projects/${project_id}/zones/${zone}/instances/${instance_name}/attachDisk)
  echo $result
  sleep 10
done

echo "Mounting shasta-cd-repo"
username=$(whoami)
sudo mkdir -p /mnt/shasta-cd-repo
sudo mount -o discard,defaults /dev/sdb /mnt/shasta-cd-repo
sudo chown -R $username:$username /mnt/shasta-cd-repo
sudo chmod -R 0777 /mnt/shasta-cd-repo

echo "Configuring SSH Keep-Alive"
sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=60 net.ipv4.tcp_keepalive_intvl=60 net.ipv4.tcp_keepalive_probes=5
cat > /tmp/sshd_config <<EOF
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 240
EOF
cat > /tmp/ssh_config <<EOF
ServerAliveInterval 60
EOF
sudo mv /tmp/sshd_config /etc/ssh/sshd_config
sudo mv /tmp/ssh_config /etc/ssh/ssh_config
sudo service sshd restart &
exit 0
