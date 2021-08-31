# 测试安装strack

# strack 安装根目录
STRACK_ROOT_DIR="docker_teast"
MYSQL_DATA_DIR=${STRACK_ROOT_DIR}/"mysql"
REDIS_DATA_DIR=${STRACK_ROOT_DIR}/"redis"
CENTRIFUGO_CONFIG_DIR=${STRACK_ROOT_DIR}/"centrifugo/config"
STRACK_MEDIA_CONFIG_DIR=${STRACK_ROOT_DIR}/"media/config"
STRACK_CORE_DIR=${STRACK_ROOT_DIR}/"strack"

# 在根目录创建安装根目录文件夹
mkdir -p /${STRACK_ROOT_DIR}

# 创建mysql数据存储文件夹
mkdir -p /${MYSQL_DATA_DIR}

# 创建redis数据持久化文件夹
mkdir -p /${REDIS_DATA_DIR}

# 创建centrifugo config.json 文件存储文件夹并拷贝文件
mkdir -p /${CENTRIFUGO_CONFIG_DIR}
cp ./../install/centrifugo/config/config.json /${CENTRIFUGO_CONFIG_DIR}/config.json

# 创建strack media application.yml 文件存储文件夹并拷贝文件
mkdir -p /${STRACK_MEDIA_CONFIG_DIR}
cp ./../install/media/config/application.yml /${CENTRIFUGO_CONFIG_DIR}/application.yml

# 创建strack 数据文件夹并解压拷贝代码
mkdir -p /${STRACK_CORE_DIR}

# 配置防火墙 centos
firewall-cmd --permanent --add-port=19567/tcp
firewall-cmd --permanent --add-port=19568/tcp
firewall-cmd --reload

# 执行docker-compose

