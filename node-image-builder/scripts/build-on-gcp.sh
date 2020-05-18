#!/bin/bash

set -e

if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID="vshasta-cray"
fi
if [ -z "$PROJECT_SUBNET" ]; then
  PROJECT_SUBNET="default-network-us-central1"
fi
if [ -z "$SERVICE_ACCOUNT" ]; then
  SERVICE_ACCOUNT="1015742806632-compute@developer.gserviceaccount.com"
fi
source_disk_image_family="https://www.googleapis.com/compute/v1/projects/vshasta-cray/global/images/family/node-image-builder"
instance_name="node-image-builder-$(date +%s)"
zone="us-central1-a"

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Error: GOOGLE_APPLICATION_CREDENTIALS is not set"
  exit 1
fi
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS

function cleanup() {
  exit_status=$?
  echo "Cleaning up..."
  gcloud compute instances delete $instance_name --quiet --zone $zone --project $PROJECT_ID || true
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
  --project $PROJECT_ID \
  --zone $zone \
  --machine-type=n1-standard-8 \
  --boot-disk-size=2048GB \
  --boot-disk-type=pd-ssd \
  --image-project vshasta-cray \
  --image-family $source_disk_image_family \
  --min-cpu-platform='Intel Haswell' \
  --scopes='https://www.googleapis.com/auth/cloud-platform' \
  --service-account=$SERVICE_ACCOUNT \
  --subnet $PROJECT_SUBNET

echo "Setting up the GCP builder instance"
echo "Y" | gcloud compute scp $this_dir/setup-gcp-instance.sh builder@$instance_name:/tmp/ --zone $zone --project $PROJECT_ID
gcloud compute ssh --zone $zone --project $PROJECT_ID builder@$instance_name -- '/tmp/setup-gcp-instance.sh '"$PACKER_VERSION"''

echo "Syncing current directory source to the GCP instance"
rm -rf ./.build
if [ -d $(pwd)/packer_cache ]; then
  mv $(pwd)/packer_cache /tmp/
fi
gcloud compute scp $(pwd) builder@$instance_name:/tmp/build-src --recurse --zone $zone --project $PROJECT_ID
gcloud compute scp $GOOGLE_APPLICATION_CREDENTIALS builder@$instance_name:/tmp/key.json --zone $zone --project $PROJECT_ID
cat > /tmp/build.sh <<EOF
#!/bin/bash
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/key.json
gcloud auth activate-service-account --key-file /tmp/key.json
cd /tmp/build-src
$@
EOF
gcloud compute scp /tmp/build.sh builder@$instance_name:/tmp/build.sh --recurse --zone $zone --project $PROJECT_ID
gcloud compute ssh --zone $zone --project $PROJECT_ID builder@$instance_name -- 'mkdir -p /tmp/build-src/http && ln -s /mnt/shasta-cd-repo /tmp/build-src/http/shasta-cd-repo'
echo "Running operation"
gcloud compute ssh --ssh-flag="-ServerAliveInterval=30" --zone $zone --project $PROJECT_ID builder@$instance_name -- 'chmod +x /tmp/build.sh && /tmp/build.sh'
if [[ "$SKIP_SYNC_BACK" != true ]]; then
  echo "Syncing .build contents back"
  gcloud compute scp builder@$instance_name:/tmp/build-src/.build $(pwd)/ --recurse --zone $zone --project $PROJECT_ID || true
fi

exit 0
