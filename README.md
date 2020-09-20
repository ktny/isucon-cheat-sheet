# 準備
## 最初に行うこと
- レギュレーションの理解
    - スコアの算出方法
    - 許容されるエラー数
    - 失格条件
- サイトへアクセスして動作確認
- ベンチマークを動かしてスコアを確認

## 環境整備
- ssh接続設定
- アプリのgit化
- ミドルウェア設定ファイルのgit化
    - MySQL
    - nginx
- デプロイ環境の整備

## 初期チューニング
- my.cnf
- nginx.cnf
- SELinux無効化
- ベンチマークを動かして初期状態とスコア比較

## 全体アーキテクチャ理解
- サーバスペック
- OS、ミドルウェアのバージョン
- アプリケーションの実装

# 計測とチューニング
## MySQL
- pt-query-digest: スローログ解析
    - time、R/Callが大きいところは1回あたりのクエリに時間がかかっており全体で占める割合も大きい
    - Rows sentに比してRows examineが大きいものはインデックスが有効に使われてない可能性が高い
- インデックス
    - 降順と昇順の組み合わせORDER BYはインデックスが効かない
        - Generated columnsで降順用カラムを作るか、MySQL8で降順インデックス
- 無駄なTEXT, BIGINTなどで余計にストレージを消費していないか
- オンメモリで載せられる更新のないテーブルがないか
- データ内容、テーブル分割の妥当性
- レプリケーション
- コネクションプール

## nginx
- alp: ログ解析
- 静的ファイル配信の圧縮、効率化
- アプリケーションとの接続方法の効率化（ソケットの利用など）

## アプリケーション
- N+1問題
- pprof

## OS
- netdata: パフォーマンス監視
- dstat: ボトルネック検出

# アーキテクチャ変更の検討
- 複数サーバの活用
- ミドルウェアの導入
    - redis
    - memcached
- 既存データの持ち方の変更
    - 画像
    - 一時データ
    - キャッシュ
    - ジョブキュー
    - DBのテーブル分割

# 最後にはやること
- ログ・計測関連のオフ
