#!/bin/bash

docker build -t arti.dev.cray.com/csm-internal-docker-stable-local/craypc/craycli-builder:latest .
if [[ "$1" == "push" ]]; then
  docker push arti.dev.cray.com/csm-internal-docker-stable-local/craypc/craycli-builder:latest
fi
