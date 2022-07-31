#!/bin/bash
set -euxo pipefail

#################################################################
# 各種ログ解析。ログローテートと負荷試験後に行う
# sshconfig設定済のリモートホスト名を設定しローカルマシン側で使用する
#################################################################

# sshconfig設定済のリモートホスト名を格納
web_server='isu01'
db_server='isu01'
local='/c/users/katsu/Downloads/'
date=$(date +%Y%m%d-%H%M%S)

# nginxアクセスログ解析
ssh $web_server "cat /var/log/nginx/access.log | alp ltsv --sort=sum -r -m "/api/player/competition/.+/ranking,/api/organizer/competition/.+/score,/api/organizer/competition/.+/finish,/api/player/player/.+,/api/organizer/player/.+/disqualified" -o ""count,2xx,4xx,5xx,method,uri,min,max,sum,avg"" > /tmp/""$date""-nginx.log"
scp $web_server:/tmp/"$date"-nginx.log "$local"

# MySQLスローログ解析
ssh $db_server "sudo pt-query-digest /var/log/mysql/mysql-slow.log > /tmp/""$date""-mysql.log"
scp $db_server:/tmp/"$date"-mysql.log "$local"
