#!/bin/bash
. ./env.config

# the endpoint id should not be a real endpoint us-west-2. Use a random endpoint id or just pick the id of an endpoint from one of your other regions
# we want the connection to fail for this to work.
ENDPOINTID="vpce-0bec4c5d4256062bd"

# add privatelink region connection for us-west-2
CONNECTIONID=`curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/privateEndpoint/?pretty=true" \
  --data '
    {
      "providerName":"AWS",
      "region":"us-west-2"
    }' | jq -r '.id'`

echo "$CONNECTIONID"

# wait for privatelink to come up
PLINKUP=""
while [ "$PLINKUP" != "WAITING_FOR_USER" ]
do
PLINKUP=`curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
  --header "Accept: application/json" \
  --request GET "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/privateEndpoint/${CONNECTIONID}" | jq -r '.status'`

echo "Status: $PLINKUP"
sleep 10
done

echo $PLINKUP

# configure endpoint id
INTERFACE_ENDPOINT_ID=`curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/privateEndpoint/${CONNECTIONID}/interfaceEndpoints?pretty=true" \
  --data "
    {
      \"interfaceEndpointId\":\"$ENDPOINTID\"
    }" | jq -r '.interfaceEndpointId'`

echo "$INTERFACE_ENDPOINT_ID"

# deploy cluster
curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
--header "Content-Type: application/json" \
--include \
--request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/clusters?pretty=true" \
--data '@sampleCluster.json'
sleep 5

#remove endpoint connection
curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
  --header "Accept: application/json" \
  --request DELETE "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/privateEndpoint/${CONNECTIONID}/interfaceEndpoints/${INTERFACE_ENDPOINT_ID}"
sleep 5

#delete endpoint
curl --user "${PUBLICKEY}:${PRIVATEKEY}" --digest \
  --header "Accept: application/json" \
  --request DELETE "https://cloud.mongodb.com/api/atlas/v1.0/groups/${GROUPID}/privateEndpoint/${CONNECTIONID}"
