# mac-proxy-launcher (代理启动器)

常驻 macOS 菜单栏的轻量代理启动器（Objective-C / AppKit），用于为指定桌面应用注入独立 HTTP 代理环境并重新启动，不修改系统全局代理。

## 支持应用

点击菜单栏连接图标，可选择以下应用（若已运行会先强制退出旧进程，再带代理环境变量和启动参数重启）：

- ChatGPT
- Visual Studio Code
- Cursor
- Antigravity
- Antigravity IDE

菜单底部显示固定代理地址：`10.126.126.1:8787`（HTTP）。

## 使用说明

1. 启动前请先连接 EasyTier，确保本机可访问 `10.126.126.1:8787`
2. 双击 `~/Applications/代理启动器.app` 启动，菜单栏将显示连接图标（无主窗口、不占 Dock 图标）
3. 从下拉菜单选择目标应用即可带代理启动或重启；点击「退出」关闭启动器

> **注意**：强制重启目标应用会中断正在运行的任务，未保存的内容可能丢失。应用及插件是否遵循代理设置取决于各自实现。

## 构建与打包

需要安装 macOS Command Line Tools，执行：

```zsh
zsh build.sh
```

脚本会使用 `sips` + `iconutil` 生成 `LauncherIcon.icns`，通过 `clang` 编译 `main.m`（最低支持 macOS 12.0），生成 `~/Applications/代理启动器.app` 并进行本地自签名（`codesign --force --sign -`）。

## 文件说明

- `main.m`：菜单栏应用源码
- `build.sh`：图标生成、编译与 `.app` 打包脚本
- `assets/`：应用图标资源
- `README.txt`：原始纯文本使用说明
