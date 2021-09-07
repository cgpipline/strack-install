#!/bin/bash

cat << EOF
 ____ _____ ____      _    ____ _  __  _   _ ____  ____    _  _____ _____
/ ___|_   _|  _ \\    / \\  / ___| |/ / | | | |  _ \\|  _ \\  / \\|_   _| ____|
\\___ \\ | | | |_) |  / _ \\| |   | ' /  | | | | |_) | | | |/ _ \\ | | |  _|
 ___) || | |  _ <  / ___ \\ |___| . \\  | |_| |  __/| |_| / ___ \\| | | |___
|____/ |_| |_| \\_\\/_/   \\_\\____|_|\\_\\  \\___/|_|   |____/_/   \\_\\_| |_____|
EOF

# 下载新的源码
echo "1. Download the latest code"

rm -rf ./source/strack.zip

wget -c -t 3 http://github.com/cgpipline/strack/archive/refs/heads/main.zip -O ./source/strack.zip 2>&1 >/dev/null ||
{
    echo '下载失败，github网络环境不好请多次尝试'
    rm -rf ${STRACK_ROOT_DIR}
    exit 1
}

# 删除替换strack源码
echo "2. Copy files to ${STRACK_ROOT_DIR}"
rm -rf ${STRACK_CORE_DIR}/strack-main

unzip -o -d ${STRACK_CORE_DIR} ./source/strack.zip

cp -f ./install/strack/config/.env ${STRACK_CORE_DIR}/strack-main/.env
cp -f ./install/strack/index.php ${STRACK_CORE_DIR}/strack-main/index.php

chmod -R 777 ${STRACK_CORE_DIR}/strack-main

# 生成新的docker-compose.yml
echo "3. Generate docker-compose.yml"

DOCKER_COMPOSE_PATH="./update/docker-compose.yml"

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

# 重新启动docker-compose
cp -f ./update/docker-compose.yml ${STRACK_ROOT_DIR}/docker-compose.yml
cd ${STRACK_ROOT_DIR}
docker-compose up -d
