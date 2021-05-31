# PRS-chainsystem-docker

### Description

This repository provides an easy and safe way to setup PRS network for block producers. 

The container will start an auto-snapshot process and can auto recover the blockchain service from the latest snapshot.

It can reduce the initial sync time and help with overall PRS chain network stability. 

-----

### Usage

#### build the container
```
./buildah.sh
```

#### Run the service
```
podman run --name [servicename] -d -v [host data-dir]:/opt/eosio/data-dir -p [ip]:8888:8888 -p [ip]:9876:9876 -p [ip]:8080:8080 -t dh.press.one/pressone/chainsystem nodeosstart.sh --delete-all-blocks --disable-replay-opts
```
