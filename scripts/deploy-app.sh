#!/bin/bash
set -euxo pipefail

echo "start deploy app ${USER}"

# for server in isu01 isu03; do
for server in isucon11q; do
    cd ./webapp/nodejs
    npm ci
    tsc
    cd ../
    tar zcf isucon.tar.gz ./nodejs
    ssh $server 'sudo rm -rf /home/isucon/webapp/nodejs/'
    ssh $server 'tar zxf - -C /home/isucon/webapp/' < isucon.tar.gz
    ssh $server 'sudo systemctl restart isucondition.nodejs.service'
done

echo "finish deploy app ${USER}"
