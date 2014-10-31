#!/bin/bash
set -ex

echo "-----> Running script: $0"

docker run \
  --rm=true \
  --volume=${PWD}:/vsphere_clients \
  --workdir=/vsphere_clients \
  ${DOCKER_REGISTRY_HOST}/${DOCKER_IMAGE_NAME} \
  --env VCENTER_IP=${VCENTER_IP} \
  --env USERNAME=${USERNAME} \
  --env PASSWORD=${PASSWORD} \
  --env DATACENTER_NAME=${DATACENTER_NAME} \
  --env DATASTORE_NAME=${DATASTORE_NAME} \
  /bin/sh -c 'bundle && bundle exec rspec --format documentation'
