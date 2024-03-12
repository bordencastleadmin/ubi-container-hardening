#!/bin/bash
containerName=$1
profile=$2

curl --tlsv1.3 -sSf --proto "=https" -L https://omnitruck.cinc.sh/install.sh | bash -s -- -v 18

docker stop $(docker ps -a -q)
docker remove $(docker ps -a -q)

docker container run --detach -i --name ${containerName} ${containerName}

containerId=$(docker container ls --all | grep -w ${containerName} | awk '{print $1}')

inspec exec ${profile} -t docker://${containerId}  --input-file inspec-inputs.yml --tags container container-conditional --reporter junit2:/tmp/junit.xml html:www/index.html