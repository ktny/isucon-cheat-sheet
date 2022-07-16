#!/bin/bash
set -euxo pipefail

#################################################################
# nginx-access.logとmysql-slow.logのローテート
#################################################################

# nginxログファイルをローテート
mv /var/log/nginx/access.log /var/log/nginx/access.log.`date +%Y%m%d-%H%M%S`
nginx -s reopen

# mysqlログファイルをローテート
mv /var/log/mysql/mysql-slow.log /var/log/mysql/mysql-slow.log.`date +%Y%m%d-%H%M%S`
mysqladmin flush-logs


# 負荷試験
# ab -c 1 -n 10 http://localhost/

# alpによる解析
# cat /var/log/nginx/access.log | alp ltsv -f "not(Uri matches '^/(upload|static)')" -m "/icons/.+,/fonts/.+"
# path=/tmp/result-nginx.log.`date +%Y%m%d-%H%M%S`
# cat /var/log/nginx/access.log | alp ltsv --sort=count -r -o "count,method,2xx,4xx,5xx,uri,avg,min,max,sum" > "$path"
# cat "$path"
