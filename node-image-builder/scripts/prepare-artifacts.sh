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
