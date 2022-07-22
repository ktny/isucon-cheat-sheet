#!/bin/bash
set -euxo pipefail

#################################################################
# 各種ログ解析。ログローテートと負荷試験後に行う
# sshconfig設定済のリモートホスト名を設定しローカルマシン側で使用する
#################################################################

# sshconfig設定済のリモートホスト名を格納
web_server='private-isu'
db_server='private-isu'
local='/c/users/katsu/Downloads/'
date=$(date +%Y%m%d-%H%M%S)

# nginxアクセスログ解析
ssh $web_server "cat /var/log/nginx/access.log | alp ltsv --sort=count -r -o ""count,2xx,4xx,5xx,method,uri,min,max,sum,avg"" > /tmp/""$date""-nginx.log"
scp private-isu:/tmp/"$date"-nginx.log "$local"

# MySQLスローログ解析
ssh $db_server "sudo pt-query-digest /var/log/mysql/mysql-slow.log > /tmp/""$date""-mysql.log"
scp private-isu:/tmp/"$date"-mysql.log "$local"
