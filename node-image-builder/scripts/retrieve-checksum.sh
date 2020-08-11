#!/bin/bash

packer_template_file="$1"
iso_url_json_path="$2"

if [ -z "$packer_template_file" ]; then
  echo "Error: the first argument to this script should be the path to the packer template file"
  exit 1
fi

if [ -z "$iso_url_json_path" ]; then
  echo "Error: the second argument to this script should be the json path within the packer file to the iso_url variable"
  exit 1
fi

iso_url=$(jq -r $iso_url_json_path $packer_template_file)
checksum_url=${iso_url//\[/\\[}
checksum_url=${checksum_url//\]/\\]}
checksum_url="${checksum_url}.sha256"

echo $(curl -s "$checksum_url")
