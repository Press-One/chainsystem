#!/bin/bash

API_ENDPOINT="http://127.0.0.1:8888/v1"
CHECKPOINT_FILE="/opt/eosio/data-dir/chaincheckpoint.json"
SNAPSHOT_DIR="/opt/eosio/data-dir/data/snapshots"
LAST_SNAPSHOT_TIME=0
SNAPSHOT_FREQ=21600 #6 hours
CHECK_FREQ=600 #10 minutes 

update_checkpoint(){
    echo "update_checkpoint: $1 $2 $3"
    if [ -z "$3" ]; then
        echo "{ \"last_irreversible_block_num\": $1, \"timestamp\": $2, \"snapshot_time\": 0 }" > ${CHECKPOINT_FILE}
    else
        echo "{ \"last_irreversible_block_num\": $1, \"timestamp\": $2, \"snapshot_time\": $3 }" > ${CHECKPOINT_FILE}
    fi
}

create_snapshot(){
    echo "start snapshoting."
    local snapshot_result=`curl -X POST ${API_ENDPOINT}/producer/create_snapshot | jq .head_block_id`
    echo "snapshot end."
    echo "$snapshot_result"
}

clean_snapshot(){
    echo "clean snapshots"
    echo `ls $SNAPSHOT_DIR -tp | grep -v '/$' | tail -n +6`
    ls $SNAPSHOT_DIR -tp | grep -v '/$' | tail -n +6  | xargs -I {} rm -- $SNAPSHOT_DIR/{}
}

run(){
    last_irreversible_block_num=`curl -s ${API_ENDPOINT}/chain/get_info | jq .last_irreversible_block_num`
    timestamp=$(date +%s)
    
    if [ ! -f $CHECKPOINT_FILE ]; then
        echo "file not exist, init."
        update_checkpoint $last_irreversible_block_num $timestamp $LAST_SNAPSHOT_TIME
        return 0
    else
        echo "file exist, check"
        lastcheck_timestamp=`jq < ${CHECKPOINT_FILE} .timestamp`
        lastcheck_blocknumber=`jq < ${CHECKPOINT_FILE} .last_irreversible_block_num`
        LAST_SNAPSHOT_TIME=`jq < ${CHECKPOINT_FILE} .snapshot_time`
        if [ -z "$lastcheck_blocknumber" ] || [ -z "$lastcheck_timestamp" ] || (( $lastcheck_timestamp == 0 )) || (( $lastcheck_blocknumber ==0 )); then
            echo "checkpoint file read error, init."
            update_checkpoint $last_irreversible_block_num $timestamp $LAST_SNAPSHOT_TIME
        else
            offset_block=$(($last_irreversible_block_num-$lastcheck_blocknumber))
            offset_time=$(($timestamp-$lastcheck_timestamp))
            offset_snapshot=$(($timestamp-$LAST_SNAPSHOT_TIME))
            echo "offset_block: $offset_block  offset_time: $offset_time offset_snapshot $offset_snapshot"
            if (( $offset_block == 0 )) && (( $offset_time > 60 )) ; then
                echo "chain check failed, send alert."
            else
                if (( $offset_block > 0 )); then
                    echo "SNAPSHOT_FREQ: $SNAPSHOT_FREQ  offset_snapshot: $offset_snapshot"
                    if (($offset_snapshot > $SNAPSHOT_FREQ)); then
                        echo "Taking snapshot..."
                        snapshot_result=$(create_snapshot)
                        echo "snapshot result: $snapshot_result"
                        if (( ${#snapshot_result} > 60 )); then #snapshot success, update the checkpoint
                            echo "snapshot success, update the checkpoint."
                            update_checkpoint $last_irreversible_block_num $timestamp $(date +%s)
                            clean_snapshot
                        else #snapshot error, update the checkpoint
                            echo "snapshot error, update the checkpoint."
                            update_checkpoint $last_irreversible_block_num $timestamp $LAST_SNAPSHOT_TIME
                        fi
                    else
                        echo "No need to take snapshot, just update the chain checkpoint."
                        update_checkpoint $last_irreversible_block_num $timestamp $LAST_SNAPSHOT_TIME
                    fi
                else #blcok offset < 0, so we can several times
                    echo "block not increase, but still can wait for the next check. checkpoint not be updated."
                fi
            fi
        fi
    fi
}

if [[ "$1" == "onestart" ]]; then
    echo "run snapshot one time"
    run
else
    echo "run snapshot loop, freq: $SNAPSHOT_FREQ"
    while true
    do
       run || true
       sleep $CHECK_FREQ
    done
fi
