#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Provide a list of entities ids"
    exit 1
fi

for file in $(cat files); do
    for id in "$@"; do
    	sh ./$file ${id}
    	status=$?

    	if [ $status != 0 ]; then
            echo "Failed to remove entity ${id} in service ${file}"
            exit 1
        fi
    done
done
