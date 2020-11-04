# filecoin-doc
filecoin相关，包括安装部署、原理文档等

# 主机依赖环境
1. docker
2. docker-compose

# lotus编译步骤
1. 将源码放入`data-server/filecoin-blouts/lotus/`目录之中
2. 启动编译所需容器：`./main.sh start blotus`
3. 进入容器：`docker exec -it filecoin-blotus /bin/sh`
4. 确认进入容器目录：`/go/src/github.com/filecoin-project/lotus`
5. 执行：`make build`或者`make clean debug`开始编译
6. 等待编译，编译完成后，即可在主机的`data-server/filecoin-blouts/lotus/`中看到编译成功的三个文件：`lotus`、`lotus-miner`、`lotus-worker`
