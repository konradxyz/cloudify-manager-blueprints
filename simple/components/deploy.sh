#!/bin/bash

name=$1

cd /tmp
wget https://github.com/cloudify-cosmo/cloudify-nodecellar-example/archive/3.2.tar.gz -O /tmp/nc.tar.gz
tar -xzvf /tmp/nc.tar.gz
cd cloudify-nodecellar-example-3.2/

echo '
host_ip: 10.10.1.10
agent_user: vagrant
agent_private_key_path: /root/.ssh/id_rsa
' >> inputs/nodecellar-singlehost.yaml

cfy init
cfy use -t 10.10.1.10
cfy blueprints upload -b $name -p singlehost-blueprint.yaml
cfy deployments create -b $name -d $name --inputs inputs/nodecellar-singlehost.yaml
cfy executions start -w install -d $name
