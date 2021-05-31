#!/bin/sh

EXEC_DIR=/opt/eosio/bin
EOS_DIR=/opt/eosio/data-dir
SNAPSHOT_DIR=$EOS_DIR/data/snapshots
NODEOS_BIN=$EXEC_DIR/nodeos

#make eos data dir
if [ ! -d $EOS_DIR ]; then
    mkdir -p $EOS_DIR
fi

echo "Starting nodeos..." 
echo "Nodeos bin: ${NODEOS_BIN}" 

/opt/eosio/bin/snapshot.sh | tee -a /opt/eosio/data-dir/snapshot.log &>/dev/null &

if [ -d $SNAPSHOT_DIR ]; then
    LATEST=$(ls -t $SNAPSHOT_DIR | head -1)
    echo "Snapshot dir exist."
    echo "Cleaning shared_memory.bin"
    rm "${EOS_DIR}/data/blocks/reversible/shared_memory.bin" 2> /dev/null
    rm "${EOS_DIR}/data/state/shared_memory.bin" 2> /dev/null
    if [ -z "$LATEST" ]; then
        echo "The snapshot dir is empty. Starting the new node."
    	cmd="${NODEOS_BIN} --genesis-json ${EOS_DIR}/config/genesis.json --config-dir ${EOS_DIR}/config --snapshots-dir snapshots --data-dir ${EOS_DIR}/data $@"
	echo "exec cmd: ${cmd}"
        exec $cmd
    else
        echo "The latest snapshot is: ${LATEST} recovering from snapshot."
    	cmd="${NODEOS_BIN} --genesis-json ${EOS_DIR}/config/genesis.json --config-dir ${EOS_DIR}/config --snapshots-dir snapshots --data-dir ${EOS_DIR}/data --snapshot ${EOS_DIR}/data/snapshots/${LATEST} --disable-replay-opt"
	echo "exec cmd: ${cmd}"
        exec $cmd
    fi
else
    echo "Starting the new node."
    cmd="${NODEOS_BIN} --genesis-json ${EOS_DIR}/config/genesis.json --config-dir ${EOS_DIR}/config --snapshots-dir snapshots --data-dir ${EOS_DIR}/data $@"
    echo "exec cmd: ${cmd}"
    exec $cmd
fi
