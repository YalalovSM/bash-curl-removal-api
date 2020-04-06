#!/bin/bash

. ./env-config.sh

if [ $# -eq 0 ]
then
    echo "Provide org_id as argument"
    exit 1
fi

org_id=$1

echo "Remove entity data. Environment = ${ENV}, Service = $0"

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

# Delete organization

response=$(curl -i -o - -s -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -H "X-TENANT-ID: ${org_id}" ${URL}/entity)
http_status=$(echo "$response" | grep HTTP | awk '{print $2}')

echo "Entity ${id} has been successfully deleted in service $0"

exit 0
