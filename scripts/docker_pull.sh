#!/bin/bash
IMAGES=$(grep -rh 'image:' k8s/   | grep -v '#'   | awk '{print $2}'   | tr -d '"'   | sort -u)
for IMAGE in $IMAGES; do
  echo ">>> $IMAGE"
  docker pull "$IMAGE"
  kind load docker-image "$IMAGE" --name edcv
done
