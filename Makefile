include /home/isucon/env.sh
# 変数定義 ------------------------

# SERVER_ID: env.sh内で定義

# 問題によって変わる変数
USER:=isucon
BUILD_DIR:=/home/isucon/recruit-isucon/webapp/nodejs
SERVICE_NAME:=recruit-isucon-node.service

DB_PATH:=/etc/mysql
NGINX_PATH:=/etc/nginx
SYSTEMD_PATH:=/etc/systemd/system

NGINX_LOG:=/var/log/nginx/access.log
DB_SLOW_LOG:=/var/log/mysql/mysql-slow.log


# メインで使うコマンド ------------------------

# サーバーの環境構築　ツールのインストール、gitまわりのセットアップ
.PHONY: setup
setup: install-tools git-setup

# 設定ファイルなどを取得してgit管理下に配置する
.PHONY: get-conf
get-conf: check-server-id get-db-conf get-nginx-conf get-service-file get-envsh get-src

# リポジトリ内の設定ファイルをそれぞれ配置する
.PHONY: deploy-conf
deploy-conf: check-server-id deploy-db-conf deploy-nginx-conf deploy-envsh deploy-src

# ベンチマークを走らせる直前に実行する
.PHONY: bench
bench: check-server-id mv-logs deploy-conf restart watch-service-log

# DBに接続する
.PHONY: access-db
access-db:
	mysql -h $(MYSQL_DB_HOST) -P $(MYSQL_DB_PORT) -u $(MYSQL_DB_user) -p$(MYSQL_DB_PASSWORD) $(MYSQL_DB_NAME)

# 主要コマンドの構成要素 ------------------------

.PHONY: install-tools
install-tools:
	sudo apt update
	sudo apt upgrade
	sudo apt install -y percona-toolkit dstat git unzip snapd graphviz tree

	# alpのインストール
	wget https://github.com/tkuchiki/alp/releases/download/v1.0.15/alp_linux_amd64.zip
	unzip alp_linux_amd64.zip
	sudo install alp /usr/local/bin/alp
	rm alp_linux_amd64.zip alp

.PHONY: git-setup
git-setup:
	# git用の設定は適宜変更して良い
	git config --global user.email "takazawa928@gmail.com"
	git config --global user.name "akaaka928"

	# deploykeyの作成
	ssh-keygen -t ed25519

.PHONY: check-server-id
check-server-id:
ifdef SERVER_ID
	@echo "SERVER_ID=$(SERVER_ID)"
else
	@echo "SERVER_ID is unset"
	@exit 1
endif

.PHONY: set-as-s1
set-as-s1:
	echo "SERVER_ID=s1" >> env.sh

.PHONY: set-as-s2
set-as-s2:
	echo "SERVER_ID=s2" >> env.sh

.PHONY: set-as-s3
set-as-s3:
	echo "SERVER_ID=s3" >> env.sh

.PHONY: get-db-conf
get-db-conf:
	sudo cp -R $(DB_PATH)/* ~/isucon2023/$(SERVER_ID)/etc/mysql
	sudo chown $(USER) -R ~/isucon2023/$(SERVER_ID)/etc/mysql

.PHONY: get-nginx-conf
get-nginx-conf:
	sudo cp -R $(NGINX_PATH)/* ~/isucon2023/$(SERVER_ID)/etc/nginx
	sudo chown $(USER) -R ~/isucon2023/$(SERVER_ID)/etc/nginx

.PHONY: get-service-file
get-service-file:
	sudo cp $(SYSTEMD_PATH)/$(SERVICE_NAME) ~/isucon2023/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME)
	sudo chown $(USER) ~/isucon2023/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME)

.PHONY: get-envsh
get-envsh:
	cp ~/env.sh ~/isucon2023/$(SERVER_ID)/home/isucon/

.PHONY: get-go-src
get-src:
	cp -R /home/isucon/recruit-isucon/webapp/nodejs/src ~/isucon2023/$(SERVER_ID)/home/isucon/recruit-isucon/webapp/nodejs/

.PHONY: deploy-db-conf
deploy-db-conf:
	sudo cp -R ~/isucon2023/$(SERVER_ID)/etc/mysql/* $(DB_PATH)

.PHONY: deploy-nginx-conf
deploy-nginx-conf:
	sudo cp -R ~/isucon2023/$(SERVER_ID)/etc/nginx/* $(NGINX_PATH)

.PHONY: deploy-service-file
deploy-service-file:
	sudo cp ~/isucon2023/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME) $(SYSTEMD_PATH)/$(SERVICE_NAME)

.PHONY: deploy-envsh
deploy-envsh:
	cp ~/isucon2023/$(SERVER_ID)/home/isucon/env.sh ~/env.sh

.PHONY: deploy-src
deploy-src:
	cp -R ~/isucon2023/$(SERVER_ID)/home/isucon/recruit-isucon/webapp/nodejs/src /home/isucon/recruit-isucon/webapp/nodejs

# ec2に合わせて修正する
.PHONY: restart
restart:
	sudo systemctl daemon-reload
	sudo systemctl restart mysql
	sudo systemctl restart $(SERVICE_NAME)
	sudo systemctl restart nginx
# slackに送る処理を追記
.PHONY: mv-logs
mv-logs:
	$(eval when := $(shell date "+%s"))
	mkdir -p ~/logs/nginx/$(when)
	mkdir -p ~/logs/mysql/$(when)
	sudo test -f $(NGINX_LOG) && \
		sudo mv -f $(NGINX_LOG) ~/logs/nginx/$(when)/ || echo ""
	sudo test -f $(DB_SLOW_LOG) && \
		sudo mv -f $(DB_SLOW_LOG) ~/logs/mysql/$(when)/ || echo ""


.PHONY: watch-service-log
watch-service-log:
	sudo journalctl -u $(SERVICE_NAME) -n10 -f
