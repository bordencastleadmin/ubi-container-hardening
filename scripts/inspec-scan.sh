#!/bin/bash
containerName=$1
profile=$2

docker stop $(docker ps -a -q)
docker remove $(docker ps -a -q)

docker container run --detach -i --name ${containerName} ${containerName}

containerId=$(docker container ls --all | grep -w ${containerName} | awk '{print $1}')

inspec exec ${profile} -t docker://${containerId}