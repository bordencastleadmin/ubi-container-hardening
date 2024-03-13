#!/bin/bash
container=$1

curl --tlsv1.3 -sSf --proto "=https" -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -v 18

docker stop $(docker ps -a -q)
docker remove $(docker ps -a -q)

docker container run --detach -i --name ${containerName} scan4fun

containerId=$(docker container ls --all | grep -w ${containerName} | awk '{print $1}')

inspec exec https://github.com/mitre/redhat-enterprise-linux-8-stig-baseline/archive/refs/tags/v1.12.0.tar.gz -t docker://${containerId} --input-file inspec-inputs.yml --tags container container-conditional --reporter junit2:/tmp/junit.xml html:www/index.html