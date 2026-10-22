# daed 安装入口

在目标 OpenWrt / Kwrt x86_64 的 root SSH 终端复制这一条：

```sh
curl -fsSL https://raw.githubusercontent.com/heart8858/daed-install/main/install.sh -o /tmp/daed-install.sh && sh /tmp/daed-install.sh
```

随后选择 **Gitee（默认）或 GitHub**，输入对应私有仓库的访问令牌。输入不会显示，不需要手动建立令牌文件；本轮临时令牌在退出时清理。请不要把令牌发到公开仓库。

当前固定版本：安装器 **10x4-install.1（预发布）**，核心 **custom-kern-takeover-10x4**。启动脚本校验固定入口 SHA256，再由入口校验安装器与安装包。核心和安装包仍在原私有仓库，本公开仓库只包含启动脚本和本说明，不包含核心、订阅、账号或令牌。

新装后读取 `/etc/daed/seed/INITIAL-ADMIN.txt`，打开 `http://<路由器地址>:2023/`，导入订阅、配置分组绑定，并在面板启动。确认可用后执行：

```sh
/usr/libexec/daed-release/daed-install activate --yes --confirm
```

已有安装保留用户数据库；安装器在停服前建立恢复守卫，并保留一致备份。备份在 `/root/daed-releases/transactions/`；不要删 WAL/SHM 或拿历史整库覆盖当前数据库。

仅在具备匹配系统依赖的 OpenWrt 6.12.92 x86_64 上验证，不宣称兼容所有裸镜像或修复全部 IPv6 首屏问题。完整说明、前置条件与原始验证记录在 [原项目](https://github.com/heart8858/daed-modify/blob/main/docs/INSTALL-10x4.md)（需要仓库权限）。

若 raw 域名不可达，可在本仓库下载 `install.sh`，上传到目标机后运行 `sh /tmp/install.sh`。自动化可以使用 `--provider gitee|github --token-stdin`，或 `DAED_TOKEN_FILE`，避免将令牌写入命令参数。

## 已有10x6.2：单独更新管理面板

```sh
curl -fsSL https://raw.githubusercontent.com/heart8858/daed-install/main/management-9.sh -o /tmp/daed-ui.sh && sh /tmp/daed-ui.sh
```

management-9新增当前节点定位/强调、吸顶筛选与近几秒核心流量平均。仅接受固定10x6.2核心；不升级核心，不修改订阅、节点、DNS或网络，不应用待应用配置。安装程序与包从所选私有仓库获取并校验；先备份，失败自动回退。原install.sh及其10x4固定资产保留。

## 定位修正版 management-10（已有10x6.2）

```sh
curl -fsSL https://raw.githubusercontent.com/heart8858/daed-install/main/management-10.sh -o /tmp/daed-ui.sh && sh /tmp/daed-ui.sh
```

立即定位到吸顶栏下方，显示明确提示及高亮，后台延迟更新保留卡片。仍只更新管理组件，原install.sh、management-9.sh与历史资产保留。

## 节点观测 management-11（已有10x6.2）

```sh
curl -fsSL https://raw.githubusercontent.com/heart8858/daed-install/main/management-11.sh -o /tmp/daed-ui.sh && sh /tmp/daed-ui.sh
```

保留节点延迟历史，在卡片操作区下显示IP评分；独立组件通过各节点实际IPv4出口采样，成功结果12小时缓存，失败显示暂不可查并保留旧值。评分不参与路由和健康判定。重启后结果保留，下次有效登录打开节点页恢复后台采集。延迟历史保存在当前浏览器，清理浏览器存储会清除。

仅支持固定10x6.2；更新管理台与独立采集组件，不替换核心、不切换节点或应用待应用配置。两端私有发布附件均下载校验，安装失败自动回退。保留所有旧入口和资产。
