#!/bin/bash

set -e

project_id="vshasta-cray"
source_disk_image_name="node-image-builder"
instance_name="node-image-builder-$(date +%s)"
zone="us-central1-a"
subnet="default-network-us-central1"

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Error: GOOGLE_APPLICATION_CREDENTIALS is not set"
  exit 1
fi
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS

function cleanup() {
  exit_status=$?
  echo "Cleaning up..."
  gcloud compute instances delete $instance_name --quiet --zone $zone --project $project_id || true
  if [ -d /tmp/packer_cache ]; then
    mv /tmp/packer_cache $(pwd)/
  fi
  exit $exit_status
}

trap cleanup EXIT

echo "Configuring local ssh to keep connections alive"
mkdir /root/.ssh
chmod 0700 /root/.ssh
cat > /root/.ssh/config <<EOF
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 240
EOF

echo "Creating builder GCP instance..."
gcloud compute instances create $instance_name \
  --project $project_id \
  --zone $zone \
  --machine-type=n1-standard-8 \
  --boot-disk-size=2048GB \
  --boot-disk-type=pd-ssd \
  --image $source_disk_image_name \
  --min-cpu-platform='Intel Haswell' \
  --scopes='https://www.googleapis.com/auth/cloud-platform' \
  --subnet $subnet

echo "Setting up the GCP builder instance"
echo "Y" | gcloud compute scp $this_dir/setup-gcp-instance.sh builder@$instance_name:/tmp/ --zone $zone --project $project_id
gcloud compute ssh --zone $zone --project $project_id builder@$instance_name -- '/tmp/setup-gcp-instance.sh '"$PACKER_VERSION"''

echo "Syncing current directory source to the GCP instance"
rm -rf ./.build
if [ -d $(pwd)/packer_cache ]; then
  mv $(pwd)/packer_cache /tmp/
fi
gcloud compute scp $(pwd) builder@$instance_name:/tmp/build-src --recurse --zone $zone --project $project_id
gcloud compute scp $GOOGLE_APPLICATION_CREDENTIALS builder@$instance_name:/tmp/build-src/key.json --zone $zone --project $project_id
cat > /tmp/build.sh <<EOF
#!/bin/bash
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/build-src/key.json
cd /tmp/build-src
$@
EOF
gcloud compute scp /tmp/build.sh builder@$instance_name:/tmp/build.sh --recurse --zone $zone --project $project_id
gcloud compute ssh --zone $zone --project $project_id builder@$instance_name -- 'mkdir -p /tmp/build-src/http && ln -s /mnt/shasta-cd-repo /tmp/build-src/http/shasta-cd-repo'
echo "Running operation"
gcloud compute ssh --ssh-flag="-ServerAliveInterval=30" --zone $zone --project $project_id builder@$instance_name -- 'chmod +x /tmp/build.sh && /tmp/build.sh'
echo "Syncing .build contents back"
gcloud compute scp builder@$instance_name:/tmp/build-src/.build $(pwd)/ --recurse --zone $zone --project $project_id || true

exit 0
