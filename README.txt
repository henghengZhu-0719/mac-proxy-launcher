代理启动器

双击 ~/Applications/代理启动器.app，菜单栏显示一个连接图标。
点击图标，从下拉菜单选择 ChatGPT、Visual Studio Code、Cursor、Antigravity 或 Antigravity IDE；已运行时会强制退出并带代理重新启动。
菜单底部显示固定代理 10.126.126.1:8787（HTTP），用于全部五个应用。
点击“退出”关闭启动器。
没有主窗口，不占 Dock 图标；关闭目标应用后启动器仍留在菜单栏。
启动前请连接 EasyTier，确保能访问代理地址。
注意：强制重启会中断正在运行的任务，未保存的内容可能丢失。
等待旧进程退出后才会重新启动；重复点击不会重复触发同一应用的重启。

使用每个应用独立的代理环境和页面启动参数，不执行 launchctl，不修改系统代理。
已有系统代理和之前保存的 launchctl 环境不由本应用清除。
应用及插件是否遵循代理设置取决于各自实现。

另一台同架构 Mac 加入同一个 EasyTier 网络并安装 ChatGPT / VS Code / Cursor / Antigravity / Antigravity IDE 后，
可以复制此 .app 使用。本地签名未公证，另一台 Mac 可能要求在“隐私与安全性”中允许打开。
不同 CPU 架构的 Mac 请复制源码，在装有 Command Line Tools 的目标 Mac 执行 zsh build.sh。

源码：main.m
重新打包：zsh build.sh
