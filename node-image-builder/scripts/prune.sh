#!/bin/bash

set -e

DRY_RUN=${DRY_RUN:-false}

if [ -z "$GOOGLE_CLOUD_SA_KEY" ]; then
  echo "Error: GOOGLE_CLOUD_SA_KEY must be defined"
  exit 1
fi

gcloud auth activate-service-account --key-file ${GOOGLE_CLOUD_SA_KEY}

######################################### Artifactory  #########################################
echo "Determining Artifactory locations to prune..."
prune_locations=""
artifactory_root_uri="http://arti.dev.cray.com/artifactory"
commit_builds=""
for node_image in $(curl -s ${artifactory_root_uri}/api/storage/node-images-unstable-local/shasta | jq -r '.children[].uri'); do
  for artifact_directory in $(curl -s ${artifactory_root_uri}/api/storage/node-images-unstable-local/shasta/${node_image} | jq -r '.children[].uri'); do
    node_image_name=$(basename $node_image)
    artifact_id=$(basename $artifact_directory)
    artifact_data=$(curl -s ${artifactory_root_uri}/api/storage/node-images-unstable-local/shasta/${node_image}/${artifact_directory})
    last_modified=$(echo $artifact_data | jq -r '.lastModified')
    last_modified_timestamp="$(date --date="$last_modified" +%s)"
    if [[ "$artifact_id" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-.*)?$ ]]; then
      most_recent_timestamp_variable="${node_image_name//-/_}_most_recent_timestamp"
      if [[ -z "$(eval echo \${$most_recent_timestamp_variable})" ]] || [[ "$(eval echo \${$most_recent_timestamp_variable})" -lt "$last_modified_timestamp" ]]; then
        eval "$most_recent_timestamp_variable=$last_modified_timestamp"
      fi
    else
      commit_builds="$commit_builds $node_image,${artifact_directory},${last_modified_timestamp}"
    fi
  done
done
for commit_build in $commit_builds; do
  node_image=$(echo $commit_build | awk -F',' '{print $1}')
  artifact_directory=$(echo $commit_build | awk -F',' '{print $2}')
  timestamp=$(echo $commit_build | awk -F',' '{print $3}')
  node_image_name=$(basename $node_image)
  pre_release_most_recent_timestamp_variable="${node_image_name//-/_}_most_recent_timestamp"
  if [[ "$(eval echo \${$pre_release_most_recent_timestamp_variable})" -gt "$timestamp" ]]; then
    prune_locations="$prune_locations ${artifactory_root_uri}/node-images-unstable-local/shasta${node_image}${artifact_directory}"
  fi
done

echo ""
echo "-----------------------------------------------------"
echo "Artifactory locations to prune:"
echo "-----------------------------------------------------"
echo "Candidates:$prune_locations" | sed "s/ /\n * /g"
echo ""

if [[ "$DRY_RUN" != true ]]; then
  for prune_location in $prune_locations; do
    echo "Pruning $prune_location..."
    curl -u$ARTIFACTORY_USERNAME:$ARTIFACTORY_PASSWORD -s -X DELETE $prune_location
  done
fi
echo ""

######################################### Google Cloud #########################################
echo "Determining Google Cloud images to prune in the vshasta-cray project..."
if [ -f ./key.json ]; then
  gcloud auth activate-service-account --key-file ./key.json &>/dev/null
fi
prune_images_released=""
rc_images=""
while read image family created; do
  if ! ( echo $family | grep -e '-dev$' || echo $family | grep -e '-rc$' ) &>/dev/null; then
    created_timestamp="$(date --date="$created" +%s)"
    count_variable="${family//-/_}_count"
    most_recent_timestamp_variable="${family//-/_}_most_recent_timestamp"
    if [ -z "$(eval echo \${$count_variable})" ]; then
      eval "$count_variable=0"
    fi
    eval "let $count_variable=$count_variable+1"
    if [[ "$(eval echo \${$count_variable})" == "1" ]]; then
      eval "$most_recent_timestamp_variable=$created_timestamp"
    fi
    if [[ "$(eval echo \${$count_variable})" -ge "4" ]]; then
      prune_images_released="$prune_images_released $image"
    fi
  else
    rc_images="$rc_images $image,$family,$created"
  fi
done < <(gcloud --quiet --project vshasta-cray compute images list --filter="family~vshasta-*" --format="value(name,family,creationTimestamp)" --sort-by="~creationTimestamp")

prune_images_rc=""
for rc_image in $rc_images; do
  image="$(echo $rc_image | awk -F',' '{print $1}')"
  family="$(echo $rc_image | awk -F',' '{print $2}')"
  created="$(echo $rc_image | awk -F',' '{print $3}')"
  created_timestamp="$(date --date="$created" +%s)"
  release_family=${family%-*}
  most_recent_timestamp_variable="${release_family//-/_}_most_recent_timestamp"
  if [[ "$(eval echo \${$most_recent_timestamp_variable})" -gt "$created_timestamp" ]]; then
    prune_images_rc="$prune_images_rc $image"
  fi
done

echo ""
echo "-----------------------------------------------------"
echo "Google Cloud images to prune in vshasta-cray project:"
echo "-----------------------------------------------------"
echo "Released:$prune_images_released" | sed "s/ /\n * /g"
echo "Candidates:$prune_images_rc" | sed "s/ /\n * /g"
echo ""

if [[ "$DRY_RUN" != true ]]; then
  echo "Pruning Google Cloud images in vshasta-cray project..."
  if [ ! -z "$prune_images_rc" ]; then
    gcloud --quiet --project vshasta-cray compute images delete $prune_images_rc
  fi
  if [ ! -z "$prune_images_released" ]; then
    gcloud --quiet --project vshasta-cray compute images delete $prune_images_released
  fi
fi
echo ""
