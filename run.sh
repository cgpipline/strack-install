#!/bin/bash

METHOD=("install" "update" "uninstall")

if [[ "${METHOD[*]}" =~ ${1} ]]; then
  EXECUTE_METHOD=$1
else
  EXECUTE_METHOD="install"
fi

# 安装strack

# strack 当前版本号
STRACK_VERSION="4.0.0 bate"

# 当前目录路径
CRT_DIR=$(pwd)

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

# 判断是全新安装还是更新安装

#判断文件夹是否存在 -d
if [[ ! -d "$STRACK_ROOT_DIR" ]]; then
  # 文件夹不存在全新安装
  source ./install.sh
else
  # 文件夹存在更新安装
  case $EXECUTE_METHOD in
  "install")
    # 重新安装
    echo "Removing strack dcoker services"
    cd ${STRACK_ROOT_DIR}
    docker-compose down

    cd ${CRT_DIR}

    source ./install.sh
    ;;
  "uninstall")
    # 卸载
    cd ${STRACK_ROOT_DIR}
    docker-compose down

    rm -rf ${STRACK_ROOT_DIR}
    ;;
  *)
    # 默认更新
    # 停止删除当前工作中的镜像
    echo "Removing strack dcoker services"

    cd ${STRACK_ROOT_DIR}
    docker-compose down

    cd ${CRT_DIR}

    source ./update.sh
    ;;
  esac

fi
