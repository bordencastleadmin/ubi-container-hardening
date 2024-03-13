#!/bin/bash
tag=$1
name=$2
curl --tlsv1.3 -sSf --proto "=https" -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -v 18

docker stop $(docker ps -a -q)
docker remove $(docker ps -a -q)

docker run -itd --name ${name} ${tag}

containerId=$(docker container ls --all | grep -w ${name} | awk '{print $1}')

inspec plugin search inspec- | grep -i docker
inspec plugin install train-docker
inspec plugin install inspec-docker
inspec exec https://github.com/mitre/redhat-enterprise-linux-8-stig-baseline/archive/refs/tags/v1.12.0.tar.gz -t docker://${containerId} --input-file inspec-inputs.yml --tags container container-conditional --reporter junit2:/tmp/junit.xml html:www/index.html