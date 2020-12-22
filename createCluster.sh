#!/bin/bash
. ./env.config

# deploy cluster
curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
--header "Content-Type: application/json" \
--include \
--request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/clusters?pretty=true" \
--data "@sampleCluster.json"
sleep 5
