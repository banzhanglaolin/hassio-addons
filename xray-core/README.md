# Docker Fly 
https://hub.docker.com/r/banzhanglaolin/xray-core

用于加速git下载

# xray-core使用

安装该模块，前启动后再到/data映射的本地目录下添加xray的配置文件congfig.json后，启动

## 解决

1. 安装此add-on，启动（如果无法添加本仓库，可以将本目录中内容放置在本地的`addons`目录中，在本地安装与启动）

2. 登录到supervisor docker容器中

    `docker exec -it hassio_supervisor bash`

3. 运行

    `git config --global http.proxy http://homeassistant:7088`

4. 如果HomeAssistant社区仓库已经丢失，可以在前端手工添加

    `https://github.com/hassio-addons/repository`

若要取消以上设置，在第三步运行：

`git config --global --unset http.proxy`

查看当前代理:

`git config --global --get http.proxy`
