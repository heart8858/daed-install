# daed 安装入口

在目标 OpenWrt / Kwrt x86_64 的 root SSH 终端执行：

```sh
curl -fsSL https://raw.githubusercontent.com/heart8858/daed-install/main/install.sh -o /tmp/daed-install.sh && sh /tmp/daed-install.sh
```

随后选择 **Gitee（默认）或 GitHub**，输入对应私有仓库的访问令牌。令牌输入不显示；临时令牌只用于本次下载，退出时清理。请不要把令牌写进公开仓库或命令参数。自动化可以使用 `--provider gitee|github --token-stdin`，或通过 `DAED_TOKEN_FILE` 指定令牌文件。

## 当前固定版本

- 核心：`10x6.5-install.1` / `custom-kern-takeover-10x6.5`
- 管理台：`management-13`（console `d0c9ce62…`，observer `b52d73e2…`）
- 离线包 SHA256：`30d1f73c6ce2dc8e7e99025545f8dd7e79686d50b79f487bc5580f7509889f85`
- 大小：62,586,316 B；根分区需约 650 MB 可用空间

启动器先校验归档 SHA256，再解压到 `/root` 并运行其中的离线安装器；安装器会再次校验包内 `SHA256SUMS`。核心和管理台分两阶段安装：先核心，后面板；任一阶段失败由安装器事务恢复，不会把归档内容直接覆盖到运行中的数据库。

新装和已有安装走同一入口：已有安装保留用户数据库、订阅、节点和配置，仅升级程序；不修改 WAN、mwan3 或分流策略。核心升级要求已安装核心在允许列表内；无法识别的核心会拒绝升级并要求先导出/检查。

## 安装后

面板默认只监听 `127.0.0.1:2024`（安全默认，不对 LAN 开放）。在管理电脑上建立 SSH 隧道：

```sh
ssh -N -L 2024:127.0.0.1:2024 root@<路由器 LAN IP>
```

然后打开 `http://127.0.0.1:2024/`。新装初始账号在路由器上读取：

```sh
cat /etc/daed/seed/INITIAL-ADMIN.txt
```

导入订阅、配置分组并启动后，确认可用再激活核心发行版：

```sh
/usr/libexec/daed-release/daed-install activate --yes --confirm
```

如需 LAN 直接访问面板（HTTP 明文，请先确认网络可信）：

```sh
uci set daed-console.main.listen='0.0.0.0:2024'
uci commit daed-console
/etc/init.d/daed-console restart
```

## 验证范围

离线包已在隔离的 QEMU OpenWrt 6.12.92 x86_64 VM 完成核心、管理台、登录和十页页面验收；公网入口额外要求私有仓库令牌。Gitee 和 GitHub 两条公网下载与安装链均已实际执行：Gitee 路径完成安装、登录和十页验收，GitHub 路径完成安装、HTTP 检查和冷重启。没有在真实生产路由器上执行本安装包；生产仍是 10x6.5 / management-12。未验证真实订阅、数据面、DNS 激活和 LAN 接管。

## 历史固定入口

### 10x4-install.1

旧的 10x4 公网入口保留为单独文件，行为不变（选择来源、隐藏令牌输入）：

```sh
curl -fsSL https://raw.githubusercontent.com/heart8858/daed-install/main/10x4-install.1.sh -o /tmp/daed-10x4.sh && sh /tmp/daed-10x4.sh
```

它固定安装 10x4，不随当前 `install.sh` 更新。

### 10x6.2 组件更新（历史）

以下入口只更新固定 10x6.2 的管理组件，不升级核心，不修改订阅、节点、DNS 或网络：

- management-9：`management-9.sh`
- management-10：`management-10.sh`
- management-11：`management-11.sh`

这些文件和历史资产保留，不作为当前 10x6.5 的安装入口。
