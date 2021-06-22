#!/bin/bash

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

set -e

image_name="$1"
git_commit="$2"
release_version="$3"
google_cloud_project="$4"

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
promote_source_image=""
for found_image_name in $(gcloud --project $google_cloud_project compute images list --filter="name~vshasta-${image_name}-${git_commit}-" --format="value(name)"); do
  build_number=${found_image_name##*-}
  if [ $build_number -gt $max_build_number ]; then
    max_build_number=$build_number
    promote_source_image="${found_image_name}"
  fi
done
if [ -z "$promote_source_image" ]; then
  echo "Couldn't locate a google cloud release candidate for vshasta-${image_name}-${git_commit}-*, unable to promote/release anything"
  exit 1
fi

promote_destination_image="vshasta-${image_name}-${release_version//./-}"
promote_destination_image_family="vshasta-${image_name}"
if echo "$release_version" | grep '-' &>/dev/null; then
  promote_destination_image_family="vshasta-${image_name}-rc"
fi

echo "Promoting Google Cloud image ${promote_source_image} to ${promote_destination_image} in project/family ${google_cloud_project}/${promote_destination_image_family}..."
gcloud --project $google_cloud_project compute images create \
  --source-image $promote_source_image \
  --family $promote_destination_image_family \
  $promote_destination_image
