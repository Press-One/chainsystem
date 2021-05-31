#!/bin/sh
cd /opt/eosio/bin

if [ ! -d "/opt/eosio/data-dir" ]; then
    mkdir /opt/eosio/data-dir
fi


exec /opt/eosio/bin/nodeos --genesis-json /opt/eosio/data-dir/config/genesis.json --config-dir /opt/eosio/data-dir/config --data-dir /opt/eosio/data-dir/data $@
#--delete-all-blocks --filter-on pressone5555:save:

