# 用 ali.sh 在 Cloady（日本 JPN1）部署节点 — 攻略

> 写于 2026-11-08。核心路线已验证：ali.sh 的行为在 VPS/Box 上实测过，Cloady 的部署方式以官方文档为准；Cloady 上的实际部署正在进行，跑通后这份攻略会再更新一次。

## 一、你要的东西

| 东西 | 说明 |
| --- | --- |
| Cloady 账号 | 工作区 `asen`，项目 `jpn1`，环境 `production`，地区日本 JPN1 |
| ali.sh 脚本 | `bash <(curl -Ls https://main.ssss.nyc.mn/ali.sh)`（你给的那个） |
| Cloudflare 隧道 | 一条新隧道 + 一个域名，指向容器里的 8001 |
| GitHub 仓库 | 放 Dockerfile 和启动脚本，Cloady 从仓库构建 |

## 二、ali.sh 是什么（实测过的）

eooce 的一键脚本，下载后直接跑，不用手动装 xray / cloudflared。

- 不带参数会随机选 Node 版或 Python 版；`-py` 强制 Python 版，`-js` 强制 Node 版，`-u` 卸载。
- 环境变量（不填就用默认值）：
  - `UUID`：节点 UUID，不填每次随机生成。**部署时一定要自己固定一个**，不然每次重启节点链接都会变。
  - `ARGO_DOMAIN`：Cloudflare 隧道域名，如 `cloady-argo.myasen.cc.cd`。
  - `ARGO_AUTH`：隧道 token（或 TunnelSecret JSON）。
  - `ARGO_PORT`：默认 8001，xray 监听这个端口。
- 跑起来后生成 **3 个节点**（VLESS / VMess / Trojan），同一个 UUID，WS 路径分别是 `/vless-argo`、`/vmess-argo`、`/trojan-argo`（后面常带 `?ed=2560`）。
- 节点信息写在 `.cache/sub.txt`（Python 版）或 `.npm/sub.txt`（Node 版），内容是 base64，解码就是 3 条链接。
- 依赖：`screen`、`python3-venv`。Debian/Ubuntu 上如果没装 `python3-venv`，ali.sh 建 venv 会直接失败，先 `apt install -y python3-venv screen`。
- 脚本用 `screen` 把程序挂后台跑，跑完自己退出，进程留在 screen 会话里。

## 三、Cloady 是什么（官方文档）

- PaaS，类似 Railway/Render。部署来源：GitHub 仓库、Docker 镜像、上传文件夹、模板。
- GitHub 仓库用 Railpack 或你自己的 Dockerfile 构建。
- 每个应用一个公网域名 `*.cloady.io` + 自动 HTTPS。
- 免费档：0.5 vCPU、1GB 内存、5GB 磁盘，每月 10GB 出站流量，不用绑卡；日本 JPN1 有免费档。
- 应用由 compose 文件定义：`ports:` 对外公开，`expose:` 只给应用内其他服务用。没 compose 文件的应用默认走 3000 端口，`PORT` 变量可以改。
- **部署上线的条件是 web 服务在声明的端口上接受连接**，1 小时还不通就判部署失败。所以容器里必须有个进程在监听端口。
- 每个服务能 SSH：`ssh.cloady.io:22`，账号密码在面板 Terminal 里看。
- 登录方式：GitHub、Google、邮箱验证码，不用密码。

## 四、部署步骤（主路线：ali.sh + Cloudflare 隧道）

Cloady 不是 VPS，不能直接粘贴命令跑脚本。要把 ali.sh 包进 Docker 镜像再部署。

### 1. 先在 Cloudflare 建一条隧道

Cloudflare 面板 → Zero Trust → Networks → Tunnels → Create，建一条新隧道（比如叫 `cloady-argo`），拿到 token。

Ingress 配一条：域名填你要用的子域名（如 `cloady-argo.myasen.cc.cd`），指向 `http://localhost:8001`。

DNS 加一条 CNAME：`cloady-argo.myasen.cc.cd` → `<隧道ID>.cfargotunnel.com`，proxied 打开。

### 2. 准备 GitHub 仓库

仓库里放两个文件（附在这份攻略同目录）：

- `Dockerfile`：Debian 基础镜像，装好 `curl`、`python3-venv`、`screen`，下载 ali.sh。
- `start.sh`：容器启动时跑的脚本，做两件事：
  1. 在 `$PORT`（Cloady 默认 3000）上起一个极简 HTTP 服务，让平台的健康检查通过；
  2. 跑 `bash ali.sh -py`，环境变量从 Cloady 的变量里读。

### 3. 在 Cloady 里建应用

Deploy 页面粘贴仓库地址，地区选 **JPN1**，环境选 **production**，资源保持免费档（0.5 vCPU / 1GB / 5GB）。

在应用的变量（Environment）里填：

| 变量 | 值 |
| --- | --- |
| `UUID` | 自己固定一个 UUID，如 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`（Linux 上 `cat /proc/sys/kernel/random/uuid` 生成一个） |
| `ARGO_DOMAIN` | `cloady-argo.myasen.cc.cd` |
| `ARGO_AUTH` | 第 1 步拿到的隧道 token |
| `ARGO_PORT` | `8001` |

### 4. 部署，盯日志

点 Deploy，看日志里出现“安装完成”，并且 screen 会话起来、8001 有监听。

### 5. 取节点

进容器（面板 Terminal，或 `ssh.cloady.io:22`），读 `.cache/sub.txt`：

```bash
cat /app/.cache/sub.txt
```

内容是 base64，解码就是 3 条节点链接（VLESS / VMess / Trojan）。

### 6. 验证（按顺序）

1. Cloudflare 面板里隧道状态是 **Healthy**，有连接数。
2. 公网 curl：`curl -s -i https://cloady-argo.myasen.cc.cd/vless-argo?ed=2560`，应返回 **400** 并带 `sec-websocket-version` 头。返回 530 / error 1033 说明隧道没连上。
3. 手机客户端导入节点，实测能上网。

## 五、坑（都是实测踩过的）

- **根路径 `/` 返回 502 不代表隧道挂了。** xray 只认 WS 升级请求，根路径 502 是正常的，看 WS 路径的 400 才算数。
- **没装 `python3-venv`，ali.sh 会失败。** Dockerfile 里已经写好了，别删。
- **UUID 不固定，重启就换节点。** 一定要在变量里固定一个 UUID。
- **免费档每月只有 10GB 出站流量**，节点流量走这个额度，超了要留意。
- **容器重启后 screen 里的进程会丢**，启动脚本每次都要重新跑 ali.sh（`start.sh` 就是这么写的）。
- **隧道 token 是敏感信息**，只放 Cloady 的变量里，别写进仓库、别截图发出来。

## 六、如果这条走不通

- 备选：不用隧道，直接用 Cloady 的 `*.cloady.io` 域名 + 平台 TLS，让 xray 监听平台端口（`PORT` 变量）。WS 升级要过平台代理，不一定稳，先按主路线来。
- 备选：回香港机中转（chisel / SSH 反向隧道）。

## 七、这份攻略里的文件

- `Dockerfile`：构建镜像，装依赖、下载 ali.sh。
- `start.sh`：容器启动脚本（健康检查 HTTP 服务 + 跑 ali.sh）。
- 两个文件和这份攻略一起放在 GitHub 仓库根目录，Cloady 直接从仓库部署。
