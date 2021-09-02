#!/bin/bash

cat << EOF
                          _____ _                  _
                         / ____| |                | |
                        | (___ | |_ _ __ __ _  ___| | __
                         \___ \\| __| '__/ _\` |/ __| |/ /
                         ____) | |_| | | (_| | (__|   <
                        |_____/ \\__|_|  \__,_|\\___|_|\\_\\

EOF

# 安装strack

# strack 当前版本号
STRACK_VERSION="4.0.0 bate"

# 安装磁盘路径
STRACK_ROOT_DIR="/docker_strack"

# strack 代码存储路径
STRACK_CORE_DIR=${STRACK_ROOT_DIR}"/install/strack/core"

## 本机IP
LOCAL_HOSTNAME="http://10.168.30.17"
WS_HOSTNAME="ws://10.168.30.17"

## 服务配置

### 服务端口号
STRACK_PORT=19801
MEDIA_PORT=19802
CENTRIFUGO_PORT=19803
RABBITMQ_API_PORT=19804
RABBITMQ_WEB_PORT=19805
REDIS_PORT=19806
MYSQL_PORT=19807

# Redis 密码
REDIS_PASSWORD="strack"

# Mysql 密码
MYSQL_PASSWORD="strack"

# Rabbitmq 用户密码
RABBITMQ_USER="strack"
RABBITMQ_PASSWORD="strack"

### 媒体服务密钥对
MEDIA_ACCESS_KEY="448c93c47bb503b758421ee74cb25b33"
MEDIA_SECRET_KEY="e8d4f937b77c0a343bbba34c5276b395"

### 消息推送服务密钥配置
CENTRIFUGO_WS_SECRET="94375620-0f51-4a67-9836-82a067593bc9"
CENTRIFUGO_API_KEY="f7b1179f-7c23-48fe-a7e1-2d471fa501ad"
CENTRIFUGO_ADMIN_PASSWORD="Strack_Centrifugo@666"


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
      - ./install/waitfor/wait-for-it.sh:/usr/local/bin/wait-for-it.sh
      - ./install/strack/core:/var/www
    networks:
      strack:
networks:
  strack:
EOF

# 在根目录创建安装根目录文件夹
echo "6. Copy files to ${STRACK_ROOT_DIR}"

rm -rf ${STRACK_ROOT_DIR}
mkdir -p ${STRACK_ROOT_DIR}/install
cp -r ./install/*  ${STRACK_ROOT_DIR}/install

# 解压 strack 到 ./install/starck/ 目录下面
mkdir -p ${STRACK_CORE_DIR}
tar -zxvf ./source/strack.tar.gz  -C ${STRACK_CORE_DIR}
cp ./install/strack/config/.env ${STRACK_CORE_DIR}/.env

# 执行docker-compose
echo "7. docker-compose up"

cp docker-compose.yml ${STRACK_ROOT_DIR}/docker-compose.yml
cd ${STRACK_ROOT_DIR}
docker-compose up -d
