#!/bin/bash
set -euxo pipefail

#################################################################
# 各種ログのローテート
#################################################################

# sshconfig設定済のリモートホスト名を格納
remote='private-isu'
date=$(date +%Y%m%d-%H%M%S)

# nginxアクセスログをローテート
ssh $remote "sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.""$date"""
ssh $remote "sudo nginx -s reopen"

# mysqlスロークエリログをローテート
ssh $remote "sudo mv /var/log/mysql/mysql-slow.log /var/log/mysql/mysql-slow.log.""$date"""
ssh $remote "sudo mysqladmin flush-logs"
