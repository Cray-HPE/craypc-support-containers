#!/bin/bash

set -e

artifacts_directory="$1"
artifacts_version="$2"

if [ -z "$artifacts_directory" ]; then
  echo "The first argument to the script must be a path to the directory containing artifacts"
  exit 1
fi

for artifact_path in $artifacts_directory/*; do
  file_name=$(basename $artifact_path)
  extension=${file_name##*.}
  name_less_extension=${file_name%.*}
  path=${artifact_path%/*}
  new_file_path="${path}/${name_less_extension}-${artifacts_version}.${extension}"
  echo "Renaming $artifact_path to $new_file_path"
  mv $artifact_path $new_file_path
done
