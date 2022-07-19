# MySQL

## コマンド一覧

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

[MySQL8.0 クエリー実行プランの理解](https://dev.mysql.com/doc/refman/8.0/ja/execution-plan-information.html)

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

- id: SELECT識別子
- select_type: SELECT型
- table: 出力行のテーブル
- partitions: 一致するパーティション
- type: 結合型
- possible_keys: 選択可能なインデックス
- key: 実際に選択されたインデックス
- key_len: 選択されたキーの長さ
- ref: インデックスと比較されるカラム
- rows: 調査される行の見積もり
- filtered: テーブル条件によってフィルタ処理される行の割合
- Extra: 追加情報

### typeから実行計画の行取得種別がわかる

ALL, indexは改善の余地あり。

- const: PKEY, UNIQUEによるルックアップアクセス。最速
- eq_ref: JOINにおいてのPKEY, UNIQUEが利用されるときのアクセス。高速
- ref: ユニークでないインデックスを使って等価検索（where key = value）を行ったとき。速い
- range: インデックスを用いた範囲検索。速い
- index: フルインデックススキャン。ALLよりは速いがインデックス全体をスキャンする必要があるので遅い
- ALL: フルテーブルスキャン。インデックスがまったく利用されていない。遅い

### Extraで行われている処理がわかる

- Using where: where句の検索条件があり、インデックスを見ただけでは解決できない場合に表示される
- Using filesort: MySQL内部のメモリ上でソートが行われている。インデックスでソートを行えるようにした方がよい
- Using index: Covering Indexでクエリを解決できている（セカンダリインデックスのみで解決し、プライマリインデックスを参照していない）。良い状態
- Using index condition: クエリがインデックスを一部利用できていることを表す
- Backward index scan: 昇順に並んでいるインデックスを逆向きに読んだことを表す。降順インデックスを利用できる可能性がある

## インデックス

[MySQL8.0 最適化とインデックス](https://dev.mysql.com/doc/refman/8.0/ja/optimization-indexes.html)

- MySQLでは1つのテーブルに対して使われるインデックスはひとつだけ
- 効率よくインデックスを使わせたければ複合インデックスなどを考慮する必要がある
- 複合インデックスでは左端のカラムから順に使用できる（例: (col1,col2,col3)の複合インデックスの場合、(col1), (col1,col2), (col1,col2,col3)に対してインデックスが使える）
- 様々な条件で検索する機能がある場合は頻繁に使われるものはインデックスを用意し、それ以外はORDER BY狙いのインデックスを作成するとよい
- 可能な限り主キーは短くする（主キーはセカンダリインデックスエントリに複製されるので長いとそれだけ必要サイズが大きくなる）

```sh
# インデックス
alter table <table> add index <idx_name> (<column>);
alter table <table> drop index <idx_name>;

# 複合インデックス
alter table <table> add index <idx_name> (<column>, <column>);

# 降順インデックス（複合インデックスと組み合わせることで第1カラムは昇順、第2カラムは降順ソートのときなどにより効果が高い）
alter table <table> add index <idx_name> (<column>, <column> desc);

# 全文検索インデックス（テキストをN-gramで分割し転置インデックスを構築）。検索時はLIKEではなくMATCHを使う
alter table <table> add fulltext index <idx_name> (<column>) with parser ngram;
select * from <table> where match (comment) against ('word' in boolean mode);

# 空間インデックス（緯度経度を持つPOINT型を空間インデックスとして使用する）
create table <table> (<column> POINT AS (POINT(<latitude>, <longitude>)) STORED NOT NULL)
alter table add spatial index <idx_name> (<column>);

# インデックス接頭辞（文字列カラムの先頭N文字のみをインデックスに使用できる。カラムまるごとインデックスにするより効率的）
create table <table> (<column> blob, index(<column>(N)));

# インデックスヒント（JOINなどによりEXPLAINで期待のインデックスが使われないときに使用する）
select * from <tableA> force index (<idx_name>) join <tableB>...;

# STRAIGHT_JOIN（tableBから処理されることなどがあるが、書いた順にtableAから処理してくれるようになる）
select straight_join * from <tableA> join <tableB>...;
```

## データベース構造の最適化

[MySQL8.0 データベース構造の最適化](https://dev.mysql.com/doc/refman/8.0/ja/optimizing-database-structure.html)

- 可能な限り最小のデータ型を使用する（INT, VARCHARは適切か）[データ型](https://dev.mysql.com/doc/refman/8.0/ja/data-types.html)
- 可能な限りNOT NULLを使用する（インデックスで各値がNULLかどうかをテストするオーバーヘッドがなくなる）
- 文字列または数値として表せるカラムは数値カラムを使う。より少ないバイト数で格納できるため
- サイズが8KB未満の場合はBLOBではなくVARCHARを使う。メモリ効率化になるため
- 長い文字列カラムを多くのクエリで取得しない場合、別テーブルに移し必要なときだけJOINして取得する
- 長い文字列カラムの同等性を確保したい場合、文字列カラム自体ではなくMD5()などでハッシュ化した値と同等性をテストする