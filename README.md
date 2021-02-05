# filecoin-doc
filecoin相关，包括安装部署、原理文档等

# 主机依赖环境
1. docker
2. docker-compose
3. 下方涉及到的dockerfile可以在[my-dockerfile](https://github.com/jason-wj/my-dockerfile/tree/master/lotus) 查阅

# lotus编译步骤
1. 将源码放入`data-server/filecoin-blouts/lotus/`目录之中
2. 启动编译所需容器：`./main.sh start blotus`
3. 进入容器：`./main.sh exec blotus`
4. 确认在容器目录：`/go/src/github.com/filecoin-project/lotus`
5. 执行：`/bin/bash -c "source /root/.cargo/env" && make build`或者`/bin/bash -c "source /root/.cargo/env" && make clean debug`或者`/bin/bash -c "source /root/.cargo/env" && make 2k`开始编译
    * 注意：一定要加上：`/bin/bash -c "source /root/.cargo/env"`
    * 受限于网络，最好在网络环境好的地方操作
6. 等待编译，编译完成后，即可在主机的`data-server/filecoin-blouts/lotus/`中看到编译成功的三个文件：`lotus`、`lotus-miner`、`lotus-worker`
7. 安装：`make install`

# 运行
`./main.sh exec elotus`
进入目录后，自行用命令操作elotus