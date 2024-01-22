#!/bin/bash

if [ ! -d "./demo-data/raw/customers" ]; then
    mkdir -p ./demo-data/raw
    mkdir -p ./demo-data/outputs

    docker compose run -i -t anaml-demo-setup bootstrap
fi

pushd demo-setup

docker compose run -i -t terraform \
  init -reconfigure

docker compose run -i -t terraform \
  apply -auto-approve

popd
