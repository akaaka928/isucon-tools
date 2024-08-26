#!/bin/bash

# サービス再起動
sudo systemctl restart nginx
sudo systemctl restart mysqld
sudo systemctl restart isucondition.ruby.service

# ログをクリア
sudo truncate /var/lib/mysql/my-slow.log --size 0
sudo truncate /var/log/nginx/access.log --size 0

# bench
./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999 > /tmp/my-bench.txt

# alpログ解析結果を出力
# 素のalp出力
sudo cat /var/log/nginx/access.log | alp ltsv > /tmp/alp.txt
# 正規表現でグルーピングしたalp出力
# 合計降順
sudo cat /var/log/nginx/access.log | alp ltsv -m '/api/condition/.*,/api/isu/.*/graph,/api/isu/.*/icon,/api/isu/.*,/isu/.*/graph,/isu/.*/condition,/isu/.*' --sort sum -r > /tmp/alp-grouped-sum.txt
# 平均降順
sudo cat /var/log/nginx/access.log | alp ltsv -m '/api/condition/.*,/api/isu/.*/graph,/api/isu/.*/icon,/api/isu/.*,/isu/.*/graph,/isu/.*/condition,/isu/.*' --sort avg -r > /tmp/alp-grouped-avg.txt

# スロークエリ解析結果を出力
sudo pt-query-digest /var/lib/mysql/my-slow.log > /tmp/pt-query-digest.txt