# alpによるnginxアクセスログ解析

## 公式

https://github.com/tkuchiki/alp/blob/main/README.ja.md

## インストール

```sh
wget https://github.com/tkuchiki/alp/releases/download/v1.0.10/alp_linux_amd64.zip
unzip alp_linux_amd64.zip
install alp /usr/local/bin/alp
alp --version
```

## nginx.confのログ出力形式をltsvにする

```nginx.conf
log_format ltsv "time:$time_local"
    "\thost:$remote_addr"
    "\tforwardedfor:$http_x_forwarded_for"
    "\treq:$request"
    "\tmethod:$request_method"
    "\turi:$request_uri"
    "\tstatus:$status"
    "\tsize:$body_bytes_sent"
    "\treferer:$http_referer"
    "\tua:$http_user_agent"
    "\treqtime:$request_time"
    "\truntime:$upstream_http_x_runtime"
    "\tapptime:$upstream_response_time"
    "\tcache:$upstream_http_x_cache"
    "\tvhost:$host";

access_log  /var/log/nginx/access.log ltsv;
```

## nginxの再起動

```sh
systemctl restart nginx
```

## ログ解析

```sh
cat /var/log/nginx/access.log | alp ltsv --sort=count -r -f "not(Uri matches '^/(upload|static)')" -m "/icons/.+,/fonts/.+" -o "count,2xx,4xx,5xx,method,uri,min,max,sum,avg"

+-------+-----+-----+-----+-----+-----+--------+--------------------------+-------+-------+-------+-------+
| COUNT | 1XX | 2XX | 3XX | 4XX | 5XX | METHOD |           URI            |  MIN  |  MAX  |  SUM  |  AVG  |
+-------+-----+-----+-----+-----+-----+--------+--------------------------+-------+-------+-------+-------+
|    50 |   0 |  50 |   0 |   0 |   0 | GET    | /items/\d+.json          | 0.000 | 0.010 | 0.190 | 0.004 |
|    16 |   0 |  16 |   0 |   0 |   0 | GET    | /users/\d+.json          | 0.010 | 0.020 | 0.120 | 0.007 |
|    15 |   0 |  15 |   0 |   0 |   0 | GET    | /settings                | 0.000 | 0.020 | 0.100 | 0.007 |
|    14 |   0 |  14 |   0 |   0 |   0 | GET    | /new_items.json          | 0.000 | 0.010 | 0.010 | 0.001 |
|    14 |   0 |  14 |   0 |   0 |   0 | GET    | /users/transactions.json | 0.010 | 0.020 | 0.140 | 0.010 |
|    14 |   0 |  13 |   0 |   1 |   0 | POST   | /login                   | 0.100 | 0.130 | 1.690 | 0.121 |
|     6 |   0 |   3 |   0 |   3 |   0 | POST   | /sell                    | 0.010 | 0.070 | 0.110 | 0.018 |
|     3 |   0 |   3 |   0 |   0 |   0 | GET    | /                        | 0.000 | 0.000 | 0.000 | 0.000 |
|     2 |   0 |   2 |   0 |   0 |   0 | GET    | /new_items/60.json       | 0.000 | 0.000 | 0.000 | 0.000 |
|     2 |   0 |   2 |   0 |   0 |   0 | GET    | /new_items/30.json       | 0.010 | 0.010 | 0.020 | 0.010 |
|     1 |   0 |   1 |   0 |   0 |   0 | POST   | /items/edit              | 0.010 | 0.010 | 0.010 | 0.010 |
|     1 |   0 |   1 |   0 |   0 |   0 | POST   | /initialize              | 6.440 | 6.440 | 6.440 | 6.440 |
|     1 |   0 |   1 |   0 |   0 |   0 | POST   | /buy                     | 0.010 | 0.010 | 0.010 | 0.010 |
|     1 |   0 |   1 |   0 |   0 |   0 | POST   | /ship                    | 0.010 | 0.010 | 0.010 | 0.010 |
|     1 |   0 |   1 |   0 |   0 |   0 | GET    | /transactions/15008.png  | 0.000 | 0.000 | 0.000 | 0.000 |
|     1 |   0 |   1 |   0 |   0 |   0 | POST   | /ship_done               | 0.010 | 0.010 | 0.010 | 0.010 |
|     1 |   0 |   1 |   0 |   0 |   0 | POST   | /complete                | 0.010 | 0.010 | 0.010 | 0.010 |
+-------+-----+-----+-----+-----+-----+--------+--------------------------+-------+-------+-------+-------+
```

- --sort: 指定方法でソート
- -r: 降順でソート
- -f: フィルター
- -m: マッチングしたものをグループ化
- -o: 出力形式の変更
