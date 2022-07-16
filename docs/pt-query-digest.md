# pt-query-digestによるMySQLスローログ解析

## 公式

https://docs.percona.com/percona-server/8.0/installation/apt_repo.html

## インストール

```sh
curl -LO https://percona.com/get/pt-query-digest
chmod +x pt-query-digest
mv pt-query-digest /usr/local/bin/
pt-query-digest --version
```

## ログ解析

```sh
pt-query-digest /var/log/mysql/mysql-slow.log > mysql-`date "+%Y%m%d_%H%M%S"`.log
```

- --sort: 指定方法でソート
- -r: 降順でソート
- -f: フィルター
- -m: マッチングしたものをグループ化
- -o: 出力形式の変更
