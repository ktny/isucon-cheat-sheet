# nginx

## 概要

### C10K問題

- マルチプロセス・シングルスレッドで単純にリクエストを捌くと多数のリクエストを捌くのにその分プロセスが必要になる（例えば1プロセスあたり100MB消費するとすると100個起動すれば10GB近いメモリが必要になる）
- CPUが処理するプロセスを切り替えるにはコンテキストスイッチを実行する必要があり、切り替え直後は新しいプロセス用のCPU上のキャッシュも使用できないのでパフォーマンスが落ちる
- 異なるプロセス同士ではメモリ共有もできず使用するメモリが多くなる
- クライアント数が1万を超えたあたりでパフォーマンスが極端に落ちる

### nginx/リバースプロキシのメリット

- ノンブロッキングI/Oやイベント駆動によりC10K問題を解決している
- 通信が遅いクライアントへのレスポンスにアプリケーションサーバのプロセスが専有されない
- 静的ファイルなどアプリケーションサーバの処理が不要なリクエストにアプリケーションサーバのワークロードが利用されない

## 設定ファイルの説明

### 基本

```conf
server {
  listen 80;

  client_max_body_size 10m;
  root /home/isucon/private_isu/webapp/public/;

  # 静的ファイルへのリクエストはリバースプロキシが直接配信する。ドキュメントルートまでのすべてのディレクトリで一般ユーザーでの実行権限が必要
  location /css/ {
  }

  # 静的ファイルへのリクエストはリバースプロキシが直接配信する。ドキュメントルートまでのすべてのディレクトリで一般ユーザーでの実行権限が必要
  location /js/ {
  }

  # その他のリクエストはアップストリームサーバに転送する
  location / {
    proxy_set_header Host $host; # 元々クライアントが送ってきたHostヘッダーをアップストリームサーバに指定する（デフォルトはproxy_passで指定したホスト名になる）
    proxy_pass http://localhost:8080;
  }
}
```

- root: 公開ディレクトリの指定
- server: 設定が異なるHTTPサーバを複数動作させることができ、そのサーバごとに使用する
- location: URLのパスごとに設定をするときに使用する。デフォルトは前方一致で処理するため`/`はすべてのパスで有効
- proxy_set_header: アップストリームサーバに送るリクエストのHTTPヘッダーを変更、追加する場合に使用する
- proxy_pass: アップストリームサーバの指定

### レスポンスボディの圧縮

### gzip

レスポンスボディをgzip圧縮してレスポンスサイズを小さくすることができる（大体1/5ぐらいのサイズになる）。
リクエストヘッダに`Accept-Encoding: gzip`が付与されていれば可能（現代のブラウザではすべて利用可能）。
レスポンスボディがgzip圧縮されているかはレスポンスヘッダに`Content-Encoding: gzip`が付与されているかで判別可能。

```conf
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
gzip_min_length 1k;
```

- gzip: onにすることで有効化
- gzip_types: gzip圧縮するMIMEタイプを指定。text/htmlはデフォルトで利用できる。JPEG,PNGなどの画像はすでに圧縮された形式のため利用不可
- gzip_min_length: gzip圧縮の対象となる最小のファイルサイズ。小さいサイズの圧縮は元のファイルよりサイズが大きくなる場合がある

#### 事前にgzip圧縮したファイルを配信する

```conf
gzip_static on;
```

ngx_http_gzip_static_moduleにより、あらかじめ`gzip -k <file>`で圧縮したgzipファイルを配信できる（-kは元ファイルを残すオプション）。
ngx_http_gunzip_moduleにより、元ファイルを残す必要もなくなる（元ファイルのディスク容量を節約できる）。
静的ファイルは事前にgzip圧縮しておいた方がよい。動的なものは事前にはできないのでレスポンス時のgzip圧縮と併用する。

### 静的ファイル配信の直接配信

```conf
server {
  location /image/ {
      root /home/isucon/private_isu/webapp/public/;
      try_files $uri @app; # public配下に画像があれば直接配信、なければアップストリームサーバに転送
  }

  location @app {
      proxy_pass http://localhost:8000;
  }
}
```

- locationで区切られた特定のパスへのリクエストはいきなりアップストリームサーバに転送せず静的ファイルを探しに行くようにする

### HTTPヘッダー設定でのクライアントキャッシュ

```conf
server {
  location /image/ {
    root /home/isucon/private_isu/webapp/public/;
    expires 1d; # Cache-Control: max-age=86400がレスポンスされる
    etag off; # Last-Modifiedだけで十分なのでETagはOFFにする
  }
}
```

- 初回、キャッシュが存在しない場合はLast-Modified, ETagのいずれかがレスポンスされるのでブラウザはそれを記憶しておく
- キャッシュ期限切れ後はリクエストヘッダにIf-Modified-Since, If-None-Matchを付与する
  - If-Modified-Sinceには記憶していたLast-Modified, If-None-Matchには記憶していたETagを付与する
  - コンテンツに変化がなければ304 Not Modifiedをレスポンスする（転送量の節約になる）
  - コンテンツに変化があれば新しいコンテンツデータとLast-Modified, ETagをレスポンスする

### アップストリームサーバとのコネクション管理

```conf
upstream app {
    server 127.0.0.1:8001;

    # 以下の設定によりアップストリームサーバとのコネクションを保持する
    keepalive 128; # キープアライブするコネクション数
    keepalive_requests 10000; # コネクションを閉じるまで受け付ける最大リクエスト数
    proxy_http_version 1.1;
    proxy_set_header Connection "";
}

server {
    listen 8000;

    root /home/isucon/private_isu/webapp/public/;

    location / {
        proxy_pass http://app; # アップストリーム名を指定する
        proxy_set_header Host $host;
    }
}
```

### 不要なアクセスを弾く

[ISUCON10 botからのリクエスト](https://gist.github.com/progfay/25edb2a9ede4ca478cb3e2422f1f12f6#bot-%E3%81%8B%E3%82%89%E3%81%AE%E3%83%AA%E3%82%AF%E3%82%A8%E3%82%B9%E3%83%88)

```conf
map $http_user_agent $is_bot {
  default 0;
  "~*^www.domain.com:Agent.*$" 1;
  "~*ISUCONbot(-Mobile)?" 1;
  "~*ISUCONbot-Image\/" 1;
  "~*Mediapartners-ISUCON" 1;
  "~*ISUCONCoffee" 1;
  "~*ISUCONFeedSeeker(Beta)?" 1;
  "~*crawler \(https:\/\/isucon\.invalid\/(support\/faq\/|help\/jp\/)" 1;
  "~*isubot" 1;
  "~*Isupider" 1;
  "~*Isupider(-image)?\+" 1;
  "~*(bot|crawler|spider)(?:[-_ .\/;@()]|$)/" 1;
}

server {
  root /home/isucon/isucon10-qualify/webapp/public;
  listen 80 default_server;
  listen [::]:80 default_server;

  if ($is_bot) {
      return 503;
  }
}
```

## その他

### 使用しているモジュール一覧の取得

```sh
nginx -V 2>&1 | grep -oP '[a-z_]+_module'

http_ssl_module
http_stub_status_module
http_realip_module
http_auth_request_module
http_dav_module
http_slice_module
http_addition_module
http_gunzip_module
http_gzip_static_module
http_sub_module
```