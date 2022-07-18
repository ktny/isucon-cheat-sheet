# DBのコマンド一覧

## MySQL

```sh
# ログイン
mysql -u<user> -h<host> -p

# DB
show databases;
use <database>;

# テーブル
show tables;
desc <table>;

# インデックス
show index from <table>;

# プロセス
show full processlist;
```

## 実行計画の確認

```sh
explain <query>;

*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: items
   partitions: NULL
         type: ALL
possible_keys: PRIMARY
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 43771
     filtered: 16.29
        Extra: Using where; Using filesort
1 row in set, 1 warning (0.00 sec)
```

### typeから実行計画の行取得種別がわかる

index, ALLは改善の余地あり。

- const: PKEY, UNIQUEによるルックアップアクセス。最速
- eq_ref: JOINにおいてのPKEY, UNIQUEが利用されるときのアクセス。高速
- ref: ユニークでないインデックスを使って等価検索（where key = value）を行ったとき。速い
- range: インデックスを用いた範囲検索。速い
- index: フルインデックススキャン。インデックス全体をスキャンする必要があるので遅い
- ALL: フルテーブルスキャン。インデックスがまったく利用されていない。遅い

### Extraで行われている処理がわかる

- Using where:
- Using filesort: MySQL内部のメモリ上でソートが行われている。インデックスでソートを行えるようにした方がよい
- Backward index scan: 昇順に並んでいるインデックスを逆向きに読んだことを表す。降順インデックスを利用できる可能性がある

## インデックス

```sh
# インデックス
alter table <table> add index <idx_name>(<column>);
alter table <table> drop index <idx_name>;

# 複合インデックス
alter table <table> add index <idx_name>(<column>, <column>);

# 降順インデックス（複合インデックスと組み合わせることで第1カラムは昇順、第2カラムは降順ソートのときなどにより効果が高い）
alter table <table> add index <idx_name>(<column>, <column> desc);
```
 