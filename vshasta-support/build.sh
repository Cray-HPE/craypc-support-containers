#!/bin/bash

docker build -t dtr.dev.cray.com/craypc/vshasta-support:latest .
if [[ "$1" == "push" ]]; then
  docker push dtr.dev.cray.com/craypc/vshasta-support:latest
fi
