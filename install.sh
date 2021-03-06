#!/bin/bash

cat << EOF
 ____ _____ ____      _    ____ _  __  ___ _   _ ____ _____  _    _     _
/ ___|_   _|  _ \\    / \\  / ___| |/ / |_ _| \\ | / ___|_   _|/ \\  | |   | |
\\___ \\ | | | |_) |  / _ \\| |   | ' /   | ||  \\| \\___ \\ | | / _ \\ | |   | |
 ___) || | |  _ <  / ___ \\ |___| . \\   | || |\\  |___) || |/ ___ \\| |___| |___
|____/ |_| |_| \\_\\/_/   \\_\\____|_|\\_\\ |___|_| \\_|____/ |_/_/   \\_\\_____|_____|
EOF

# 获取当前系统类型
Get_Dist_Name()
{
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknow'
    fi
}

Get_Dist_Name

echo "0. Initialize ${DISTRO} system environment"

# 判断docker安装好了没
source ./env.sh
$PM install -y unzip zip

# 动态生成配置文件

## 生成默认媒体配置sql文件
echo "1. Generate default media configuration SQL file"

MEDIA_SERVER_SQL_PATH="./install/database/sql/strack_media_server.sql"

rm -rf ${MEDIA_SERVER_SQL_PATH}

cat>"${MEDIA_SERVER_SQL_PATH}"<<EOF
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO \`strack_media_server\` VALUES (2, 'media_default', 'media_default', '${LOCAL_HOSTNAME}:${MEDIA_PORT}/', '${LOCAL_HOSTNAME}:${MEDIA_PORT}/media/upload', '${MEDIA_ACCESS_KEY}', '${MEDIA_SECRET_KEY}', '6b07a8c0-0b9f-11ec-9f14-7dea0b282735');

SET FOREIGN_KEY_CHECKS = 1;
EOF

## 生成 centrifugo config.json 配置文件
echo "2. Generate centrifugo config.json configuration file"

CENTRIFUGO_CONFIG_PATH="./install/centrifugo/config/config.json"

rm -rf ${CENTRIFUGO_CONFIG_PATH}

cat>"${CENTRIFUGO_CONFIG_PATH}"<<EOF
{
  "v3_use_offset": true,
  "token_hmac_secret_key": "${CENTRIFUGO_WS_SECRET}",
  "admin_password": "${CENTRIFUGO_ADMIN_PASSWORD}",
  "admin_secret": "265fcc06-d9d9-4992-9ec7-d38514228bb0",
  "api_key": "${CENTRIFUGO_API_KEY}",
  "secret": "16bfd798-4f9f-4362-98e8-d88cb4997db2",
  "presence": true,
  "history_size": 100,
  "history_lifetime": 600,
  "publish": true,
  "engine": "redis",
  "redis_host": "redis",
  "redis_port": 6379,
  "redis_password": "${REDIS_PASSWORD}"
}
EOF

## 生成媒体服务 application.yml
echo "3. Generate media service application.yml configuration file"

MEDIA_CONFIG_PATH="./install/media/config/application.yml"

rm -rf ${MEDIA_CONFIG_PATH}
cat>"${MEDIA_CONFIG_PATH}"<<EOF
server:
  port: 8080
  mode: debug
  staticPath: ./static/
ffmpeg:
  ffmpegBinPath: ./natron/bin/ffmpeg
  ffprobeBinPath: ./natron/bin/ffprobe
  mode: video_transcode
mysql:
  host: mysql
  port: 3306
  database: strack_media
  username: root
  password: ${MYSQL_PASSWORD}
  charset: utf8
  maxQueryNumber: 1000
amqp:
  host: rabbitmq
  port: 5672
  user: ${RABBITMQ_USER}
  password: ${RABBITMQ_PASSWORD}
  vhost: /
  queueName: strack_machinery
  queueAutoDeleted: false
  resultsExpireIn: 1200
redis:
  host: redis
  password: ${REDIS_PASSWORD}
  port: 6379
  select: 8
transcode:
  workNumber: 3
token:
  access_key: ${MEDIA_ACCESS_KEY}
  secret_key: ${MEDIA_SECRET_KEY}
EOF

## 生成 strack .env 文件
echo "4. Generate stack .env file"

STRACK_ENV_PATH="./install/strack/config/.env"

rm -rf ${STRACK_ENV_PATH}
cat>"${STRACK_ENV_PATH}"<<EOF
company_name="strack opensource team"
version="${STRACK_VERSION}"
show_theme="default"
module_cloud_disk="un_active"
belong_system="task"

default_password="Strack@password"
default_email_suffix="@strack.com"

database_host="mysql"
database_name="strack"
database_user="root"
database_password="${MYSQL_PASSWORD}"
database_port="3306"

database_max_select_rows=2000

redis_host="redis"
redis_port="6379"
redis_password="${REDIS_PASSWORD}"
redis_select=9

status="development"

media_request_url="${LOCAL_HOSTNAME}:${MEDIA_PORT}/"
media_upload_url="${LOCAL_HOSTNAME}:${MEDIA_PORT}/media/upload"
media_access_key="${MEDIA_ACCESS_KEY}"
media_secret_key="${MEDIA_SECRET_KEY}"

WS_HOST="http://centrifugo:8000/api"
WS_CONNECT_URL="${WS_HOSTNAME}:${CENTRIFUGO_PORT}/connection/websocket"
WS_KEY="${CENTRIFUGO_API_KEY}"
WS_SECRET="${CENTRIFUGO_WS_SECRET}"
EOF

## 生成docker-compose.yml文件
echo "5. Generate docker-compose.yml"

DOCKER_COMPOSE_PATH="docker-compose.yml"

rm -rf ${DOCKER_COMPOSE_PATH}
cat>"${DOCKER_COMPOSE_PATH}"<<EOF
version: "3"
services:
  mysql:
    image: 'mysql:5.7'
    ports:
      - '${MYSQL_PORT}:3306'
    restart: always
    volumes:
      - ./install/database/sql:/opt/sql
      - ./install/database/shell:/docker-entrypoint-initdb.d
      - ./install/database/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: '${MYSQL_PASSWORD}'
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    networks:
      strack:
  redis:
    image: 'redis:5'
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    ports:
      - '${REDIS_PORT}:6379'
    volumes:
      - ./install/database/redis:/data
    networks:
      strack:
  rabbitmq:
    image: 'rabbitmq:management'
    restart: always
    environment:
      RABBITMQ_DEFAULT_USER: '${RABBITMQ_USER}'
      RABBITMQ_DEFAULT_PASS: '${RABBITMQ_PASSWORD}'
    ports:
      - '${RABBITMQ_WEB_PORT}:15672'
      - '${RABBITMQ_API_PORT}:5672'
    networks:
      strack:
  centrifugo:
    image: 'weijer/centrifugo:latest'
    restart: always
    ports:
      - '${CENTRIFUGO_PORT}:8000'
    command:
      - wait-for-it.sh
      - redis:6379
      - --
      - centrifugo
      - -c
      - /centrifugo/config.json
    volumes:
      - ./install/waitfor/wait-for-it.sh:/usr/local/bin/wait-for-it.sh
      - ./install/centrifugo/config:/centrifugo
    networks:
      strack:
  strack_media:
    image: 'weijer/strack-media:latest'
    restart: always
    ports:
      - '${MEDIA_PORT}:8080'
    command:
      - wait-for-it.sh
      - redis:6379
      - rabbitmq:5672
      - mysql:3306
      - --
      - strack_media
    volumes:
      - ./install/waitfor/wait-for-it.sh:/usr/local/bin/wait-for-it.sh
      - ./install/media/config:/app/config
      - ./install/media/static:/app/static
    networks:
      strack:
  strack:
    image: 'weijer/strack-docker:latest'
    restart: always
    ports:
      - '${STRACK_PORT}:80'
    command:
      - wait-for-it.sh
      - redis:6379
      - mysql:3306
      - strack_media:8080
      - centrifugo:8000
      - --
      - supervisord
      - -c
      - /etc/supervisor/conf.d/supervisord.conf
    volumes:
      - ./install/waitfor/wait-for-it-php.sh:/usr/local/bin/wait-for-it.sh
      - ./install/strack/core/strack-main:/var/www
    networks:
      strack:
networks:
  strack:
EOF

# 下载最新代码 https://github.com/cgpipline/strack/archive/refs/heads/main.zip
echo "6. Download the latest code"

rm -rf ./source/strack.zip

wget -c -t 3 http://github.com/cgpipline/strack/archive/refs/heads/main.zip -O ./source/strack.zip 2>&1 >/dev/null ||
{
    echo '下载失败，github网络环境不好请多次尝试'
    rm -rf ${STRACK_ROOT_DIR}
    exit 1
}

# 在根目录创建安装根目录文件夹
echo "7. Copy files to ${STRACK_ROOT_DIR}"

rm -rf ${STRACK_ROOT_DIR}
mkdir -p ${STRACK_ROOT_DIR}/install
cp -r ./install/*  ${STRACK_ROOT_DIR}/install

# 解压 strack 到 ./install/starck/ 目录下面
mkdir -p ${STRACK_CORE_DIR}
unzip -o -d ${STRACK_CORE_DIR} ./source/strack.zip

cp -f ./install/strack/config/.env ${STRACK_CORE_DIR}/strack-main/.env
cp -f ./install/strack/index.php ${STRACK_CORE_DIR}/strack-main/index.php

# 执行docker-compose
chmod -R 777 ${STRACK_ROOT_DIR}/install
echo "8. docker-compose up"

cp docker-compose.yml ${STRACK_ROOT_DIR}/docker-compose.yml
cd ${STRACK_ROOT_DIR}
docker-compose up -d
