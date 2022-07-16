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
cat /var/log/nginx/access.log | alp ltsv --sort=count -r -f "not(Uri matches '^/(upload|static)')" -m "/icons/.+,/fonts/.+" -o "count,method,2xx,4xx,5xx,uri,avg,min,max,sum"
```

- --sort: 指定方法でソート
- -r: 降順でソート
- -f: フィルター
- -m: マッチングしたものをグループ化
- -o: 出力形式の変更
