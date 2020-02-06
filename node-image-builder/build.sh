#!/bin/bash

docker build -t dtr.dev.cray.com/craypc/node-image-builder:latest .
if [[ "$1" == "push" ]]; then
  docker push dtr.dev.cray.com/craypc/node-image-builder:latest
fi
