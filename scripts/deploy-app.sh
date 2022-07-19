#!/bin/bash
set -euxo pipefail

echo "start deploy app ${USER}"

# 配置先
# sqldest=/home/isucon/webapp/sql/
# godest=/home/isucon/webapp/go/
nodedest=/home/isucon/private_isu/webapp/node/

# for server in isu01 isu03; do
for server in private-isu; do
    # deploy db
    # ssh $server "sudo systemctl stop mariadb"
    # ssh $server "sudo rm -f /var/log/mysql/mysql-slow.log"
    # ssh $server "mysql -uisucon -pisucon -e'flush logs;' isucondition"
    # scp mysql.cnf $server:/etc/mysql/conf.d/mysql.cnf
    # scp webapp/sql/init.sh $server:$sqldest
    # scp webapp/sql/0_Schema.sql $server:$sqldest
    # scp webapp/sql/1_InitData.sql $server:$sqldest
    # ssh $server "/home/isucon/webapp/sql/init.sh"
    # ssh $server "sudo systemctl start mariadb"

    # deploy nginx
    # scp nginx.conf $server:/etc/nginx/nginx.conf
    # ssh $server "sudo rm -f /var/log/nginx/access.log"
    # ssh $server "sudo systemctl restart nginx"

    # deploy app
    # ssh $server "sudo systemctl stop isucondition.go.service"
    # scp webapp/go/main.go $server:$godest
    # scp webapp/go/go.mod $server:$godest
    # scp webapp/go/go.sum $server:$godest
    # ssh $server "cd webapp/go && /home/isucon/local/go/bin/go build -o isucondition"
    # ssh $server "sudo systemctl start isucondition.go.service"
    # ssh $server "sudo systemctl restart jiaapi-mock.service"

    # deploy app
    tsc main.ts
    scp main.js $server:$nodedest
done

echo "finish deploy app ${USER}"
