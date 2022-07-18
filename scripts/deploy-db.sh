#!/bin/bash
set -euxo pipefail

echo "start deploy db ${USER}"

dest=/home/isucon/webapp/sql/

for server in isu01; do
    ssh $server "sudo systemctl stop mariadb"
    ssh $server "sudo rm -f /var/log/mysql/mysql-slow.log"
    # ssh $server "mysql -uisucon -pisucon -e'flush logs;' isucondition"
    # scp mysql.cnf $server:/etc/mysql/conf.d/mysql.cnf
    scp webapp/sql/0_Schema.sql $server:$dest
    scp webapp/sql/1_InitData.sql $server:$dest
    ssh $server "/home/isucon/webapp/sql/init.sh"
    ssh $server "sudo systemctl start mariadb"
done

echo "finish deploy db ${USER}"