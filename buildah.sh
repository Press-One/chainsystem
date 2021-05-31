#!/bin/sh

# Build the container using buildah instead of Docker

# Retrieve container
CONTAINER=$(buildah from ubuntu:18.04)
echo $CONTAINER

# Mount the container filesystem
MNT=$(buildah mount $CONTAINER)
echo $MNT

mkdir -p $MNT/opt/eosio/bin
mkdir -p $MNT/opt/eosio/data-dir
mkdir -p $MNT/opt/eosio2/bin
mkdir -p $MNT/opt/eosio2/data-dir
cp eos/bin/nodeos $MNT/opt/eosio/bin/nodeos
cp eos/bin/cleos $MNT/opt/eosio/bin/cleos
cp eos/bin/keosd $MNT/opt/eosio/bin/keosd

cp eos2/bin/nodeos $MNT/opt/eosio2/bin/nodeos
cp eos2/bin/cleos $MNT/opt/eosio2/bin/cleos
cp eos2/bin/keosd $MNT/opt/eosio2/bin/keosd
cp eos2/bin/eosio-blocklog $MNT/opt/eosio2/bin/eosio-blocklog
cp eos2/bin/trace_api_util $MNT/opt/eosio2/bin/trace_api_util

cp nodeosd.sh $MNT/opt/eosio/bin/nodeosd.sh
cp nodeosstart.sh $MNT/opt/eosio/bin/nodeosstart.sh
cp snapshot.sh $MNT/opt/eosio/bin/snapshot.sh
cp cleos.sh $MNT/opt/eosio/bin/cleos.sh
chmod +x $MNT/opt/eosio/bin/nodeosd.sh
buildah config --env EOSIO_ROOT=/opt/eosio

buildah config --env DEBIAN_FRONTEND=noninteractive $CONTAINER
buildah run $CONTAINER apt-get update 
buildah run $CONTAINER apt-get -yq dist-upgrade
buildah run $CONTAINER apt-get install -yq --no-install-recommends \
    wget \
    curl \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    libtinfo-dev libcurl3-gnutls libcurl4-openssl-dev libusb-1.0-0-dev gnupg jq
buildah run $CONTAINER apt-get install -y pkg-config libzmq5-dev 
buildah run $CONTAINER rm -rf /var/lib/apt/lists/*

buildah run $CONTAINER echo "en_US.UTF-8 UTF-8" > /etc/locale.gen 
buildah run $CONTAINER locale-gen

buildah config --env LD_LIBRARY_PATH=/usr/local/lib
buildah config --env PATH=/opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Set container config options (port, entrypoint)
buildah config --entrypoint '["/opt/eosio/bin/nodeosstart.sh"]'  $CONTAINER
buildah commit $CONTAINER pressone/chainsystem
echo "$CONTAINER"
