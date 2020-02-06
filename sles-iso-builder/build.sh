#!/bin/bash

docker build -t dtr.dev.cray.com/craypc/sles-iso-builder:latest .
if [[ "$1" == "push" ]]; then
  docker push dtr.dev.cray.com/craypc/sles-iso-builder:latest
fi
