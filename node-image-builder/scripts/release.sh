#!/bin/bash

set -e

image_name="$1"
git_commit="$2"
release_version="$3"
google_cloud_project="vshasta-cray"

if [ -z "$image_name" ]; then
  echo "Error: first argument to the release script should be the name of the image"
  exit 1
fi
if [ -z "$git_commit" ]; then
  echo "Error: second argument to the release script should be the git commit of release candidates"
  exit 1
fi
if [ -z "$release_version" ]; then
  echo "Error: third argument to the release script should be the release version, with or without a pre-release version attached"
  exit 1
fi
if [ -z "$google_cloud_project" ]; then
  echo "Error: fourth argument to the release script should be the google project housing release candidate images"
  exit 1
fi

max_build_number=0
artifacts_root_uri="http://arti.dev.cray.com/artifactory"

promote_source_path=""
unstable_release_candidates_uri="${artifacts_root_uri}/api/storage/node-images-unstable-local/shasta/${image_name}"
echo "Searching $unstable_artifacts_uri for the latest build for commit ${git_commit}"
for folder in $(curl -u$ARTIFACTORY_USERNAME:$ARTIFACTORY_PASSWORD -s $unstable_release_candidates_uri | jq -r .children[].uri); do
  build_number=${folder##*-}
  if [ $build_number -gt $max_build_number ]; then
    max_build_number=$build_number
    promote_source_path="/node-images-unstable-local/shasta/${image_name}${folder}"
  fi
done
if [ -z "$promote_source_path" ]; then
  echo "Couldn't locate an artifactory release candidate directory at ${unstable_release_candidates_uri} for commit ${git_commit}, unable to promote/release anything"
  exit 1
fi

promote_source_version="${git_commit}-${max_build_number}"
destination_artifact_repo="node-images-stable-local"
promote_destination_image_family="vshasta-${image_name}"
if echo "$release_version" | grep '-' &>/dev/null; then
  destination_artifact_repo="node-images-unstable-local"
  promote_destination_image_family="vshasta-${image_name}-rc"
fi

promote_destination_path="/${destination_artifact_repo}/shasta/${image_name}/${release_version}"
if curl -s -I ${artifacts_root_uri}${promote_destination_path} 2>&1 | grep '302 Found'; then
  echo "Found existing promoted artifact at $promote_destination_path, not promoting anything"
  exit 1
fi
echo "Getting all artifacts at ${promote_source_path}"
for artifact_file in $(curl ${artifacts_root_uri}/api/storage${promote_source_path} | jq -r .children[].uri); do
  promoted_artifact_file=${artifact_file/${promote_source_version}/${release_version}}
  echo "Promoting ${promote_source_path}${artifact_file} to ${promote_destination_path}${promoted_artifact_file}"
  curl -u$ARTIFACTORY_USERNAME:$ARTIFACTORY_PASSWORD -s -X POST \
    $artifacts_root_uri/api/copy${promote_source_path}${artifact_file}?to=${promote_destination_path}${promoted_artifact_file}
  echo ""
done

promote_source_image="vshasta-${image_name}-${promote_source_version}"
promote_destination_image="vshasta-${image_name}-${release_version//./-}"
echo "Promoting Google Cloud image ${promote_source_image} to ${promote_destination_image} in project/family ${google_cloud_project}/${promote_destination_image_family}..."
gcloud --project $google_cloud_project compute images create \
  --source-image $promote_source_image \
  --family $promote_destination_image_family \
  $promote_destination_image
