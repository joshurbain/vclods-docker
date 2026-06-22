#!/bin/bash
# Usage: ./full_build.sh [name] [amd64|arm64]
ARCH=$(uname -m)
case "${2:-$ARCH}" in
  amd64|x86_64)  PLATFORM="linux/amd64" ;;
  arm64|aarch64) PLATFORM="linux/arm64" ;;
  *) echo "Unknown architecture: ${2:-$ARCH}"; exit 1 ;;
esac
docker rm -f -v "vclod${1:+-$1}"
docker build --platform "$PLATFORM" --tag vclods:1.0 .
docker container run -i -t -d -v $(realpath ./scripts):/app/scripts -v $(realpath ./oracle_config):/app/oracle_config --name "vclod${1:+-$1}" vclods:1.0
# Example: for using a specific network, use this line instead of the above one
# docker container run -i -t -d -v $(realpath ./scripts):/app/scripts -v $(realpath ./oracle_config):/app/oracle_config --network=mariadb-network --name "vclod${1:+-$1}" vclods:1.0
docker exec -it "vclod${1:+-$1}" /bin/bash