#!/bin/bash

. ./env-config.sh

if [ $# -eq 0 ]
then
    echo "Provide id to be removed"
    exit 1
fi

id=$1

echo "Remove all data tied to entity ${id}. Environment = ${ENV}, Service = $0"

response=$(curl -s -w "HTTP_STATUS:%{http_code}" --user "${OAUTH_CLIENTID}:${OAUTH_CLIENTSECRET}" -X POST -H "Content-Type: application/json" ${URL}/token?grant_type=client_credentials)

body=$(echo $response | sed -e 's/HTTP_STATUS\:.*//g')
http_status=$(echo $response | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

# Get token as a client

if [ $http_status != '200' ]
then
    echo "Cannot login. Error: $http_status, $body"
    exit 1
fi

echo "Logged in with specified credentials"

access_token=$(echo "$body" | jq -r .access_token)

# Delete entity 

response=$(curl -i -o - -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -H "X-TENANT-ID: ${id}" -d "{ \"operationType\" : \"DELETE\" }" ${URL}/entity-data)
http_status=$(echo "$response" | grep HTTP | awk '{print $2}')
location=$(echo "$response" | grep -i location | awk '{print $2}' | tr -d '\r')
operation_id=${location##*/}

if [ $http_status != '202' ]
then
    echo "Cannot initiate process of deleting entity. Status: $http_status, Error: $response"
    exit 1
fi

echo "Successfully sent the request for deleting entity ${id}"

# Loop until operation status is not COMPLETED

response=$(curl -s -w "HTTP_STATUS:%{http_code}" -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -H "X-TENANT-ID: ${id}" ${URL}/entity-data/${operation_id})
body=$(echo $response | sed -e 's/HTTP_STATUS\:.*//g')
http_status=$(echo $response | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

operation_status=$(echo $body | jq -r .operationStatus)
affected_rows=$(echo $body | jq -r .numberOfAffectedRows)

echo " - Current status of entity ${id} remval process is ${operation_status}. Affected rows: ${affected_rows}"

count=5
while [ "${operation_status}" != "COMPLETED" ]; do
    sleep 15
    response=$(curl -s -w "HTTP_STATUS:%{http_code}" -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -H "X-TENANT-ID: ${id}" ${URL}/entity-data/${operation_id})
    body=$(echo $response | sed -e 's/HTTP_STATUS\:.*//g')
    http_status=$(echo $response | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

    if [ $http_status != '200' ]
    then
        echo "Cannot delete entity. Error: $http_status $body"
        exit 1
    fi

    operation_status=$(echo $body | jq -r .operationStatus)
    affected_rows=$(echo $body | jq -r .numberOfAffectedRows)
    echo " - Current status of entity ${id} removal process is ${operation_status}. Affected rows: ${affected_rows}"

    if [ count -eq 0 ]
    then
        echo "Terminating entity ${id} removal process"
        exit 1
    fi
    ((count=count-1))
done

exit 0

