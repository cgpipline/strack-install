#!/bin/bash

# 安装strack

# strack 安装根目录
STRACK_ROOT_DIR="/docker_strack"
STRACK_CORE_DIR=${STRACK_ROOT_DIR}"/install/strack/core"

# 在根目录创建安装根目录文件夹
rm -rf ${STRACK_ROOT_DIR}
mkdir -p ${STRACK_ROOT_DIR}/install
cp -r ./install/*  ${STRACK_ROOT_DIR}/install

# 解压 strack 到 ./install/starck/ 目录下面
mkdir -p ${STRACK_CORE_DIR}
tar -zxvf ./source/strack.tar.gz  -C ${STRACK_CORE_DIR}
cp ./install/strack/config/.env ${STRACK_CORE_DIR}/.env

# 执行docker-compose
cp docker-compose.yml ${STRACK_ROOT_DIR}/docker-compose.yml
cd ${STRACK_ROOT_DIR}
docker-compose up -d
