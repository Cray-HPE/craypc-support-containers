#!/bin/bash

docker build -t dtr.dev.cray.com/craypc/kiwi-builder:latest .
if [[ "$1" == "push" ]]; then
  docker push dtr.dev.cray.com/craypc/kiwi-builder:latest
fi
