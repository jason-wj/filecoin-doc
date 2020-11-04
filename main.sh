#!/usr/bin/env bash

MODE=$1
STATE=$2

# 项目名(根据项目改，同时需要改掉docker-compose.yml中的myflag)
PROJECT_NAME=filecoin

# 项目模式：开发-dev、生产-prod
# 当 使用到了传到仓库的自定义镜像的时候，需要切换为prod，否则默认dev即可
PROJECT_MODE=dev

# 镜像推送的账号和密码
DOCKER_USERNAME=xxx@xxx.xx
DOCKER_PASSWORD=xxx

# 镜像推送名称
PUSH_ROOT_REGISTRY="registry.cn-hangzhou.aliyuncs.com"

# docker-compose 文件名
DOCKER_COMPOSE_FILE="docker-compose.yml"

# 项目根路径
export ROOT_PATH=$(pwd)

# 外部触发指令
# 用户级
COMMAND_BLOTUS="blotus"
COMMAND_ELOTUS="elotus"

# 容器版本
export IMAGE_BLOTUS="wujason/lotus-build-env:latest"
export IMAGE_ELOTUS="wujason/lotus-exec-env:latest"

# container：必须保留，当一个容器涉及到多个依赖时，方便选择加入
export CONTAINER_BLOTUS=${PROJECT_NAME}"-"${COMMAND_BLOTUS}
export CONTAINER_ELOTUS=${PROJECT_NAME}"-"${COMMAND_ELOTUS}

# 根据不同项目模式切换镜像，同时
if [[ ${PROJECT_MODE} == "prod" ]]; then
  docker login --username=${DOCKER_USERNAME} --password ${DOCKER_PASSWORD} ${PUSH_ROOT_REGISTRY}
fi

# 日志查看
function logs_one() {
    docker logs -f ${PROJECT_NAME}"-"${STATE} --tail 15
}

# 推送一个项目docker到仓库
function push_one() {
  docker push ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
  docker rmi -f ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
}

# 启动指定服务
function start_one() {
    case ${STATE} in
        ${COMMAND_ELOTUS})
            if [ ! -f "${ROOT_PATH}/data-server/filecoin-elotus/bin/lotus" ];then
               mkdir ${ROOT_PATH}/data-server/filecoin-elotus/bin/
               cp ${ROOT_PATH}/data-server/filecoin-blotus/lotus/{lotus,lotus-miner,lotus-seed,lotus-worker} ${ROOT_PATH}/data-server/filecoin-elotus/bin/
            fi
        ;;
    esac
    docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
}

function release_state() {
    if [[ ${STATE} == "" ]]; then
        printHelp
        exit 1
    elif [[ ${STATE} == "all" ]]; then
        release_all
    else
        release_one "${STATE}"
    fi
}

# 无论全局清理还是单独清理，都会执行如下内容，删除无效网络、卷、容器、镜像等
function release_base(){
    docker volume ls -qf dangling=true
    # 查看指定的volume
    # docker inspect docker_orderer.example.com

    # 开始清理
    if [[ -n $(docker volume ls -qf dangling=true) ]]; then
      docker volume rm $(docker volume ls -qf dangling=true)
    fi
    # 删除为none的镜像
    docker images | grep none | awk '{print $3}' | xargs docker rmi -f
    docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs docker rmi

    # 该指令默认会清除所有如下资源：
    # 已停止的容器（container）、未被任何容器所使用的卷（volume）、未被任何容器所关联的网络（network）、所有悬空镜像（image）。
    # 该指令默认只会清除悬空镜像，未被使用的镜像不会被删除。添加-a 或 --all参数后，可以一并清除所有未使用的镜像和悬空镜像。
    docker system prune -f

    # 删除无用的卷
    docker volume prune -f

    # 删除无用网络
    docker network prune -f
}

# 全局释放所有docker环境，当前系统所有镜像都会受到影响
# 不确定则请慎用
function release_all() {
    docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} stop
    # 关闭当前系统正在运行的容器，并清除
    docker stop $(docker ps -a | awk '{ print $1}' | tail -n +2)
    docker rm -f $(docker ps -a | awk '{ print $1}' | tail -n +2)
    release_base
}

# 清理关闭一个指定容器
function release_one() {
  docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} stop ${PROJECT_NAME}"-"$1
  docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} rm -f ${PROJECT_NAME}"-"$1
  release_base
}

function printHelp() {
    echo "当前支持的指定服务：[blotus、elotus]"
    echo "./main.sh start [+操作码]：启动服务"
    echo "          [操作码]"
    echo "               指定服务：启动指定服务"
    echo "./main.sh logs [+操作码]：查看日志"
    echo "          [操作码]"
    echo "               指定服务：查看指定日志"
    echo "./main.sh push [+操作码]：推送镜像到仓库"
    echo "          [操作码]"
    echo "               指定服务：推送到指定仓库，当前支持[]"
    echo "./main.sh release [+操作码]：用于释放项目和其余容器"
    echo "          [操作码]"
    echo "               all：释放项目所有内容，包括各种容器、网络等，非当前docker-compose编排的容器也会被清理，务必谨慎使用！"
    echo "               指定容器名：释放指定容器，主要是用来释放项目所在的容器"
    echo "其余操作将触发此说明"
}

#启动模式
case ${MODE} in
    "start")
        start_one ;;
    "logs")
        logs_one ;;
    "push")
        push_one ;;
    "release")
        release_state ;;
    *)
        printHelp
        exit 1
esac
