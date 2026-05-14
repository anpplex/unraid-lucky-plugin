# Lucky x86_64 Unraid 插件 / Lucky x86_64 Unraid Plugin

[中文](#中文) | [English](#english)

## 中文

这是一个 Lucky 的 Unraid 插件，用于在 Unraid 上直接安装、运行和管理 Lucky，并通过 GitHub Actions 自动跟进 Lucky 上游版本，生成可由 Unraid 插件更新机制识别的新版本。

Lucky 是一个面向家庭服务器和自托管场景的网络工具箱，常用功能包括端口转发、反向代理、动态域名解析、内网穿透、Wake-on-LAN、计划任务、WebDAV、证书管理等，适合在 Unraid 上统一管理常见网络服务入口。

### 上游信息

- 项目地址：https://github.com/gdy666/lucky
- 当前版本：`2.27.2`
- 二进制包：`lucky_2.27.2_Linux_x86_64.tar.gz`
- 启动命令：`lucky -cd <配置目录>`
- 默认 Web UI：`http://<unraid-ip>:16601`
- 默认账号密码：`666 / 666`
- 插件图标来源：https://cdn.jsdelivr.net/gh/IceWhaleTech/CasaOS-AppStore@main/Apps/Lucky/icon.png

### 安装方式

在 Unraid 的插件安装页面使用这个地址：

```text
https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main/dist/lucky.plg
```

也可以在 Unraid 终端中安装：

```sh
installplg https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main/dist/lucky.plg
```

如果需要离线安装，可以下载仓库里的独立安装版：

```text
dist/lucky-x86_64.plg
```

### 安装后的路径

- 主程序：`/usr/local/lucky/lucky`
- 命令软链：`/usr/local/sbin/lucky`
- Lucky 配置目录：`/boot/config/plugins/lucky/luckyconf`
- 插件配置文件：`/boot/config/plugins/lucky/lucky.cfg`
- 启停脚本：`/etc/rc.d/rc.lucky`
- Unraid 页面：`Settings / Lucky`
- 日志文件：`/var/log/lucky.log`
- PID 文件：`/var/run/lucky.pid`

### 构建

```sh
./scripts/build-plugin.sh https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main
```

构建会生成：

- `dist/lucky.plg`：在线安装版，适合 Unraid 插件更新机制。
- `dist/lucky-x86_64.plg`：内嵌 x86_64 包的独立/离线安装版。
- `dist/packages/lucky-<version>-x86_64-1.txz`：Unraid/Slackware 风格安装包。

### 自动追新

仓库包含 GitHub Actions 工作流，会每天检查 Lucky 上游 release，也可以手动运行。发现新版后会自动：

- 下载最新 `Linux_x86_64` 二进制包。
- 计算并更新 `UPSTREAM_SHA256`。
- 更新 `VERSION`。
- 更新 `PLUGIN_VERSION`。
- 重新生成 `dist/lucky.plg`、`dist/lucky-x86_64.plg` 和 `dist/packages/*.txz`。
- 提交生成后的插件产物。

普通用户建议始终使用 `dist/lucky.plg` 的 raw URL 安装，这样 Unraid 后续可以通过插件更新机制发现新版。

[Switch to English](#english)

## English

This is an Unraid plugin for Lucky. It installs, runs, and manages Lucky directly on Unraid, and uses GitHub Actions to track upstream Lucky releases automatically so new plugin versions can be discovered through Unraid's normal plugin update flow.

Lucky is a network toolbox for home servers and self-hosted environments. Common features include port forwarding, reverse proxy, DDNS, intranet tunneling, Wake-on-LAN, scheduled tasks, WebDAV, certificate management, and related entry-point management for network services.

### Upstream

- Project: https://github.com/gdy666/lucky
- Current version: `2.27.2`
- Binary archive: `lucky_2.27.2_Linux_x86_64.tar.gz`
- Runtime command: `lucky -cd <config-dir>`
- Default Web UI: `http://<unraid-ip>:16601`
- Default login: `666 / 666`
- Plugin icon source: https://cdn.jsdelivr.net/gh/IceWhaleTech/CasaOS-AppStore@main/Apps/Lucky/icon.png

### Installation

Use this URL in Unraid's plugin installation page:

```text
https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main/dist/lucky.plg
```

Or install from an Unraid terminal:

```sh
installplg https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main/dist/lucky.plg
```

For offline installation, download the standalone installer from the repository:

```text
dist/lucky-x86_64.plg
```

### Installed Layout

- Binary: `/usr/local/lucky/lucky`
- Symlink: `/usr/local/sbin/lucky`
- Lucky config directory: `/boot/config/plugins/lucky/luckyconf`
- Plugin config file: `/boot/config/plugins/lucky/lucky.cfg`
- rc script: `/etc/rc.d/rc.lucky`
- Unraid page: `Settings / Lucky`
- Log file: `/var/log/lucky.log`
- PID file: `/var/run/lucky.pid`

### Build

```sh
./scripts/build-plugin.sh https://raw.githubusercontent.com/anpplex/unraid-lucky-plugin/main
```

The build creates:

- `dist/lucky.plg`: repository installer for Unraid's plugin update mechanism.
- `dist/lucky-x86_64.plg`: standalone/offline installer with the x86_64 package embedded.
- `dist/packages/lucky-<version>-x86_64-1.txz`: Unraid/Slackware-style package.

### Automatic Updates

This repository includes a GitHub Actions workflow that checks Lucky upstream releases daily and can also be run manually. When a new version is found, it automatically:

- Downloads the latest `Linux_x86_64` binary archive.
- Calculates and updates `UPSTREAM_SHA256`.
- Updates `VERSION`.
- Updates `PLUGIN_VERSION`.
- Rebuilds `dist/lucky.plg`, `dist/lucky-x86_64.plg`, and `dist/packages/*.txz`.
- Commits the generated plugin artifacts.

Users should install from the raw URL for `dist/lucky.plg` so Unraid can discover future plugin updates through its normal plugin update flow.

[切换到中文](#中文)
