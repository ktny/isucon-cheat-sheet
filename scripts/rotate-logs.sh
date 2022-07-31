#!/bin/bash
set -euxo pipefail

#################################################################
# 各種ログローテーション。負荷試験前に行う
# sshconfig設定済のリモートホスト名を設定しローカルマシン側で使用する
#################################################################

# sshconfig設定済のリモートホスト名を格納
web_server='isu01'
db_server='isu01'
date=$(date +%Y%m%d-%H%M%S)

# nginxアクセスログをローテート
ssh $web_server "sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.""$date"""
ssh $web_server "sudo nginx -s reopen"

# mysqlスロークエリログをローテート
ssh $db_server "sudo mv /var/log/mysql/mysql-slow.log /var/log/mysql/mysql-slow.log.""$date"""
ssh $db_server "sudo systemctl restart mysql"
# ssh $db_server "mysqladmin flush-logs"
# ssh $db_server "mysql -uisucon -pisucon -e'flush logs;' isports"
