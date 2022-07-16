#!/bin/bash
set -euxo pipefail

#################################################################
# 各種ログ解析。ログローテートと負荷試験後に行う
#################################################################

# sshconfig設定済のリモートホスト名を格納
remote='private-isu'
local='/c/users/katsu/Downloads/'
date=$(date +%Y%m%d-%H%M%S)

# nginxアクセスログ解析
ssh $remote "cat /var/log/nginx/access.log | alp ltsv --sort=count -r -o ""count,method,2xx,4xx,5xx,uri,avg,min,max,sum"" > /tmp/""$date""-nginx.log"

# 解析結果ログをローカルホストに転送する
scp private-isu:/tmp/"$date"-nginx.log "$local"

# MySQLスローログ解析
ssh $remote "sudo pt-query-digest /var/log/mysql/mysql-slow.log > /tmp/""$date""-mysql.log"

# 解析結果ログをローカルホストに転送する
scp private-isu:/tmp/"$date"-mysql.log "$local"
