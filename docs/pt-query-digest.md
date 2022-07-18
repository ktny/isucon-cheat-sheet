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
pt-query-digest /var/log/mysql/mysql-slow.log
```

### 解析結果概要

```txt
# Files: /var/log/mysql/mysql-slow.log
# Overall: 433.33k total, 66 unique, 5.63k QPS, 3.10x concurrency ________
# Time range: 2020-08-23T20:47:45 to 2020-08-23T20:49:02
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time           239s     7us   593ms   550us   626us     7ms   152us
# Lock time            22s       0    22ms    50us   152us   293us       0
# Rows sent        185.89k       0      49    0.44    0.99    2.18       0
# Rows examine      29.70M       0  48.91k   71.88    0.99   1.65k       0
# Query size       134.67M       0 913.29k  325.87   40.45  13.84k   31.70
```

Rows sentがRows examineに対して小さいと無駄が大きく改善する必要がある。

- Exec time: クエリの実行にかかった時間
- Lock time: クエリの実行までにかかった時間。他のスレッドによるロックの待ち時間
- Rows sent: クエリを実行しクライアントに返した行数
- Rows examine: クエリを実行時にスキャンした行数
- Query size: 実行したクエリの長さ

### 負荷の大きいクエリランキング

```txt
# Profile
# Rank Query ID                     Response time Calls  R/Call V/M   Item
# ==== ============================ ============= ====== ====== ===== ====
#    1 0x5AF10ED6AD345D4B930FF1E... 43.8782 18.4%    536 0.0819  0.02 SELECT items
#    2 0xDA556F9115773A1A99AA016... 35.0851 14.7% 143565 0.0002  0.00 ADMIN PREPARE
#    3 0x534F6185E0A0C71693761CC... 29.1767 12.2%     92 0.3171  0.02 SELECT items
#    4 0xE1FCE50427E80F4FD12C536... 27.0992 11.4%  93406 0.0003  0.00 SELECT categories
#    5 0x6D959E4C28C709C1312243B... 21.0794  8.8%    157 0.1343  0.03 SELECT items
#    6 0x07890000813C4CC7111FD2D... 16.7729  7.0% 143565 0.0001  0.00 ADMIN CLOSE STMT
#    7 0x396201721CD58410E070DA9... 13.0910  5.5%  42296 0.0003  0.00 SELECT users
#    8 0x528C15CEBCCFADFD36DB579... 12.9616  5.4%    106 0.1223  0.01 SELECT items
#    9 0x6688844580F541EC2C1B6BE... 12.4524  5.2%    109 0.1142  0.01 SELECT items
#   10 0xC108F424549A524A9A74397...  7.6742  3.2%     82 0.0936  0.03 SELECT items
#   11 0x61B4A126A90B2DEB4C0C6A2...  5.9184  2.5%     54 0.1096  0.01 SELECT items
#   12 0x7769A9D5AB3A5E4B54AA9C3...  3.3948  1.4%    100 0.0339  0.01 INSERT items
# MISC 0xMISC                       10.0689  4.2%   9267 0.0011   0.0 <54 ITEMS>
```

- Response time: 実行時間の合計と全体に占める割合
- Calls: 実行された回数
- R/Call: 1回あたりの時間

### クエリの詳細

```txt
# Query 3: 1.46 QPS, 0.46x concurrency, ID 0x534F6185E0A0C71693761CC3349B416F at byte 143920107
# This item is included in the report because it matches --limit.
# Scores: V/M = 0.02
# Time range: 2020-08-23T20:47:58 to 2020-08-23T20:49:01
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count          0      92
# Exec time     12     29s   219ms   593ms   317ms   455ms    69ms   293ms
# Lock time      0    21ms    74us     2ms   225us   596us   235us   125us
# Rows sent      2   4.40k      49      49      49      49       0      49
# Rows examine  14   4.39M  48.88k  48.91k  48.90k  46.68k       0  46.68k
# Query size     0  19.14k     213     213     213     213       0     213
# String:
# Databases    isucari
# Hosts        localhost
# Users        isucari
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms
# 100ms  ################################################################
#    1s
#  10s+
# Tables
#    SHOW TABLE STATUS FROM `isucari` LIKE 'items'\G
#    SHOW CREATE TABLE `isucari`.`items`\G
# EXPLAIN /*!50100 PARTITIONS*/
SELECT * FROM `items` WHERE `status` IN ('on_sale','sold_out') AND (`created_at` < '2019-08-12 15:48:00'  OR (`created_at` <= '2019-08-12 15:48:00' AND `id` < 49677)) ORDER BY `created_at` DESC, `id` DESC LIMIT 49\G
```

Rows sentがRows examineに対して小さいと無駄が大きく改善する必要がある。

- Count: 解析対象期間中に実行されたクエリ数
- Exec time: クエリの実行にかかった時間
- Lock time: クエリの実行までにかかった時間。他のスレッドによるロックの待ち時間
- Rows sent: クエリを実行しクライアントに返した行数
- Rows examine: クエリを実行時にスキャンした行数
- Query size: 実行したクエリの長さ
