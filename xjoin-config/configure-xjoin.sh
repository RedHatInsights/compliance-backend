#!/bin/bash

while true
do
    status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null -H "Accept: application/json" -H "Content-Type: application/json" debezium:8083/connectors/)
    if [[ "$status_code" -ne 200 ]] ; then
        echo "kafka connect is not ready to accept connection."
        echo "waiting for 30 sec."
        sleep 30
    else
        curl -s -o /dev/null -X PUT -H "Accept: application/json" -H "Content-Type: application/json" "elasticsearch:9200/_ingest/pipeline/my-pipeline" --data "@/xjoin-config/my-pipeline.json"
        curl -s -o /dev/null -X PUT -H "Accept: application/json" -H "Content-Type: application/json" "elasticsearch:9200/xjoin.inventory/" --data "@/xjoin-config/elastic_mapping.json"
        curl -s -o /dev/null -X POST -H "Accept: application/json" -H "Content-Type: application/json" debezium:8083/connectors/ --data "@/xjoin-config/debezium.json"
        curl -s -o /dev/null -X POST -H "Accept: application/json" -H "Content-Type: application/json" debezium:8083/connectors/ --data "@/xjoin-config/elasticsearch-sink.json"
        break
    fi
done
