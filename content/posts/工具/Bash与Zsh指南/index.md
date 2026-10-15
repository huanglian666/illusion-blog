---
title: "⌨️ Bash 与 Zsh 对比及命令行生存指南"
date: 2026-10-15T09:40:00+08:00
lastmod: 2026-10-15T09:40:00+08:00
tags: ["命令行工具", "工具指南"]
categories: ["命令行工具"]
weight: 13
description: "- Bash 与 Zsh 的核心差异、Oh My Zsh 的配置与插件体系、常用 shell 命令、Vim 入门与 ifconfig/netstat 等网络排查命令，一篇讲全。"
image: "https://t.alcy.cc/ycy?random=2"
aliases: ["/posts/Bash与Zsh指南/"]
---

### 1. 前言

每天打开终端，第一眼看到的是提示符，敲下去的第一条命令跑在某个 shell 里。对大多数人来说，这个 shell 就是 **zsh**（macOS 从 Catalina 起的默认 shell）或者 **bash**（绝大多数 Linux 发行版的默认 shell）。但很多人用了几年终端，也说不清这两者到底差在哪，更别提 Oh My Zsh 那一堆插件到底帮自己干了什么。

这篇文章把四件事一次讲清：

1. **Bash 和 Zsh 的区别**——知道差异，才能明白 zsh 的提示符为什么更聪明；
2. **Oh My Zsh 的使用**——安装、配置、主题、插件体系；
3. **常用命令速查**——文件、文本、进程、权限，以及 Vim 的生存级用法；
4. **网络排查命令**——ifconfig、netstat、ping、dig 这些查 IP、查端口的工具。

> 本文环境：macOS + zsh 5.9 + Oh My Zsh，Linux 下命令会单独标注差异。

---

### 2. Bash 与 Zsh：同源不同路

#### 2.1 一句话定位

- **bash**（Bourne Again Shell）是 GNU 项目对经典 sh 的重写，目标是**兼容与通用**：所有 Linux 发行版自带，写脚本最保险。
- **zsh**（Z Shell）诞生于 1990 年，功能上是 bash 的超集再往前走了一大步，强项是**交互体验**：补全、纠错、主题、可定制性。macOS 从 10.15 Catalina（2019 年）起把默认登录 shell 从 bash 换成了 zsh（因为 bash 3.2 的 GPLv3 许可证问题，苹果一直没升级）。

#### 2.2 核心差异对比

| 维度 | bash | zsh |
| --- | --- | --- |
| 默认归属 | 几乎所有 Linux 发行版 | macOS（Catalina 起）、Kali Linux |
| 脚本兼容性 | 事实标准，`#!/bin/bash` 最通用 | 兼容 bash 大部分语法，但写脚本仍建议用 bash |
| Tab 补全 | 基础的文件名/命令补全 | **可编程补全系统**：`git che` → 提示 `checkout`，`kill <Tab>` 直接列出进程名 |
| 拼写纠正 | 无 | 输入 `gti status` 会问 `zsh: correct 'gti' to 'git' [nyae]?` |
| 通配符 | `*` `?` `[abc]` | 额外支持 `**/` 递归匹配、`*(.)` 只匹配文件、`*(/)` 只匹配目录 |
| 右侧提示符 | 无 | 支持 `RPROMPT`（右侧信息），电源线主题靠它实现 |
| 路径别名 | 无 | `hash -d blog=~/Desktop/blog` 后可 `cd ~blog` |
| 数组下标 | 从 **0** 开始 | 从 **1** 开始（脚本移植时最容易踩的坑） |
| 配置文件 | `~/.bashrc` / `~/.bash_profile` | `~/.zshrc`（交互式）/ `~/.zprofile`（登录式） |
| 生态 | 脚本生态庞大 | Oh My Zsh、Powerlevel10k 等交互生态庞大 |

#### 2.3 Zsh 交互层的几个"回不去"的特性

**① 递归通配符**——找文件不再需要 `find`：

```bash
# 列出当前目录所有层级的 .md 文件（bash 里要写 find . -name "*.md"）
ls **/*.md

# 只列出目录（括号是 zsh 的 glob 限定符）
ls -d **/*(/)
```

**② 全局别名（global alias）**——别名可以出现在命令中间：

```bash
alias -g G='| grep'
alias -g L='| less'

history L        # 等价于 history | less
ps aux G node    # 等价于 ps aux | grep node
```

**③ 更聪明的目录跳转**：

```bash
cd -<Tab>        # 列出历史访问过的目录，带编号可选
d                # 内置命令，显示目录栈
cd ~2            # 直接跳到目录栈里第 2 项
```

**④ 自动 pushd**——在 `~/.zshrc` 加一行 `setopt AUTO_PUSHD`，之后每次 `cd` 都自动记录，`cd -` 或 `popd` 随时回头。

<div class="callout callout-warning">
<div class="callout-title"><i class="fas fa-triangle-exclamation"></i> 陷阱：脚本别用 zsh 跑</div>
<div class="callout-body">

zsh 和 bash 在数组下标（1 vs 0）、分词行为、`echo` 转义等细节上不一致。**交互用 zsh，脚本头部永远写 `#!/bin/bash` 或 `#!/usr/bin/env bash`**，别因为自己日常用 zsh 就顺手写 `#!/bin/zsh`——放到别人机器或 CI 上大概率出问题。

</div>
</div>

#### 2.4 查看与切换当前 shell

```bash
echo $SHELL        # 当前默认登录 shell
echo $0            # 当前正在运行的 shell
chsh -s /bin/zsh   # 切换默认 shell 为 zsh（注销重登生效）
chsh -s /bin/bash  # 切回 bash
cat /etc/shells    # 系统里安装了哪些 shell
```

---

### 3. Oh My Zsh 重点讲解

#### 3.1 它是什么

原生的 zsh 虽然强大，但默认配置很朴素，补全系统要自己写，主题要自己调。**Oh My Zsh 是一个 zsh 的配置管理框架**：它把社区里沉淀的 300 多个插件、150 多个主题和一整套合理的默认配置打包好，让你用几行配置就拥有一个高效、好看的终端。

它本身只是一个 Git 仓库 + 一份 `.zshrc` 模板，不修改系统任何东西，卸载即恢复原样。

#### 3.2 安装与更新

```bash
# 安装（前提：zsh 和 git 已装好）
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 手动更新
omz update

# 卸载（会恢复安装前的 .zshrc 备份）
uninstall_oh_my_zsh
```

<div class="callout callout-note">
<div class="callout-title"><i class="fas fa-circle-info"></i> 国内网络提示</div>
<div class="callout-body">

`raw.githubusercontent.com` 在大陆时常连不通。可以先把仓库克隆到本地再执行安装脚本：

```bash
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```

</div>
</div>

安装完成后目录结构如下：

```
~/.oh-my-zsh/
├── lib/           # 核心库：补全、历史、快捷键等通用配置
├── plugins/       # 300+ 内置插件，每个目录一个
├── themes/        # 150+ 内置主题
├── custom/        # ★ 你的自留地：自定义主题、插件、别名都放这里
│   ├── plugins/
│   └── themes/
└── oh-my-zsh.sh   # 总入口，.zshrc 最后 source 的就是它
```

**改配置永远改 `~/.zshrc`，不要动 `~/.oh-my-zsh/` 里的文件**——否则下次 `omz update` 会被覆盖（`custom/` 目录除外）。

#### 3.3 `.zshrc` 关键配置逐行理解

```bash
# 主题：改成 themes/ 目录下任意主题的文件名（不带 .zsh-theme）
ZSH_THEME="robbyrussell"

# 插件列表：空格分隔，按顺序加载
plugins=(git z extract colored-man-pages command-not-found)

# Oh My Zsh 安装目录，一般不动
export ZSH="$HOME/.oh-my-zsh"

# 补全缓存相关，加快启动
zstyle ':omz:update' mode disabled   # 关闭启动时的版本检查提示

# 补全大小写不敏感、连字符下划线等价
CASE_SENSITIVE_COMPATIBLE="true"

source $ZSH/oh-my-zsh.sh   # 加载框架，放在自定义别名之前

# ↓ 这里往下写你自己的别名、环境变量、PATH
alias ll='ls -lah'
export EDITOR='vim'
```

改完记得 `source ~/.zshrc` 让配置生效，或者直接开个新标签页。

#### 3.4 主题

**内置主题**：设好 `ZSH_THEME` 重新 source 即可。常用的几个：

| 主题 | 特点 |
| --- | --- |
| `robbyrussell` | 默认主题，极简、零依赖 |
| `agnoster` | 经典电源线风格，需要 Nerd Font |
| `fino` / `half-life` | 信息量大且不依赖特殊字体 |

**Powerlevel10k（p10k）**：目前事实上的标准答案，速度快（提示符渲染 < 40ms）、可显示 git 状态/执行耗时/k8s 上下文等任意信息，首次安装会启动交互式向导：

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# .zshrc 里改一行
ZSH_THEME="powerlevel10k/powerlevel10k"
```

之后随时用 `p10k configure` 重新跑向导调整样式。它需要终端安装 **Nerd Font** 字体（向导会引导下载），iTerm2 用户配合 iTerm2 的 Shell Integration 还能显示命令执行时长。

<div class="callout callout-tip">
<div class="callout-title"><i class="fas fa-lightbulb"></i> 随机主题彩蛋</div>
<div class="callout-body">

把 `ZSH_THEME` 设为 `random`，每次开终端随机换一个主题；配 `ZSH_THEME_RANDOM_CANDIDATES=(robbyrussell agnoster fino)` 可以限定候选范围。想从 150 个主题里挑一个顺眼的，这是最快的办法。

</div>
</div>

#### 3.5 插件机制

插件本质就是一段 `.zsh` 脚本（别名、函数、补全定义），写进 `plugins=(...)` 数组后按序加载。分两类：

**内置插件**（`~/.oh-my-zsh/plugins/` 里自带，写名字即用）：

| 插件 | 作用 |
| --- | --- |
| `git` | 几十个 git 别名：`gst`=`git status`、`gco`=`git checkout`、`gp`=`git push`、`glg`=带图形的 log |
| `z` | 目录跳跃：`z blog` 直接跳到访问频率最高的匹配目录，不用敲全路径 |
| `extract` | 万能解压：`xxx.tar.gz`、`xxx.zip`、`xxx.7z` 全都用 `extract 文件名` 搞定，不用记参数 |
| `colored-man-pages` | man 手册彩色渲染，读起来舒服很多 |
| `command-not-found` | 敲错命令时提示"装哪个包能获得它" |
| `history` | `h` 查历史、`hs` 查历史并 grep |
| `jsontools` | `echo '{"a":1}' \| pp_json` 等一组 JSON 格式化别名 |
| `web-search` | `google 关键词`、`github 关键词` 直接开浏览器搜索 |
| `macos` | `cdf` 跳到 Finder 当前目录、`tab` 新开标签页等 Mac 专属命令 |

**外部插件**（需要手动 clone 到 `custom/plugins/`，装完写进 plugins 数组）：

```bash
# ① 语法高亮：敲对的命令是绿色，敲错是红色，回车前就能发现错误
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# ② 自动建议：灰色显示历史记录里匹配的命令，按 → 补全
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# ③ 补全定义合集：补充官方没有覆盖的命令补全
git clone https://github.com/zsh-users/zsh-completions.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
```

```bash
plugins=(git z extract colored-man-pages
         zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
```

<div class="callout callout-warning">
<div class="callout-title"><i class="fas fa-triangle-exclamation"></i> 加载顺序</div>
<div class="callout-body">

`zsh-syntax-highlighting` 官方建议放在 **plugins 数组的最后一个**，它需要 hook 其他插件的输出。顺序不对可能导致高亮不生效。

</div>
</div>

#### 3.6 custom 目录：写自己的配置

别在 `.zshrc` 里堆太多东西，个人别名和函数建议放到 `~/.oh-my-zsh/custom/`：

```bash
# ~/.oh-my-zsh/custom/example.zsh 会被框架自动加载
alias blog='cd ~/Desktop/blog/illusion-blog && hugo server'
alias ports='lsof -i -P -n | grep LISTEN'   # 查本机监听端口（下文详解）
proxy_on()  { export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890; }
proxy_off() { unset https_proxy http_proxy; }
```

> `custom/` 目录不受 `omz update` 影响，Git 管理的 dotfiles 仓库也建议把这个目录纳入版本控制。

---

### 4. 常用命令速查

这一节是通用 shell 命令，bash 和 zsh 下行为一致。按使用场景分组，只列高频用法。

#### 4.1 文件与目录

| 命令 | 说明 |
| --- | --- |
| `ls -lah` | 列表显示（含隐藏文件、人类可读的文件大小） |
| `pwd` | 显示当前目录绝对路径 |
| `cd -` | 回到上一次所在目录（zsh 里 `cd -<Tab>` 可选历史目录） |
| `mkdir -p a/b/c` | 递归创建多级目录 |
| `cp -r src dst` | 复制目录必须带 `-r` |
| `mv old new` | 移动或重命名 |
| `rm -rf dir` | 递归强制删除——**没有回收站，敲之前看三遍** |
| `tree -L 2` | 树状显示目录结构，两层深度 |
| `du -sh *` | 统计当前目录下每个条目占用的磁盘空间 |
| `df -h` | 查看磁盘整体使用情况 |

#### 4.2 文本查看与搜索

| 命令 | 说明 |
| --- | --- |
| `cat file` | 输出整个文件；`less file` 分页看大文件（`q` 退出，`/` 搜索） |
| `head -n 20` / `tail -n 20` | 看开头/结尾 20 行；`tail -f app.log` 实时追日志 |
| `grep -rn "关键词" .` | 递归搜索并显示行号；`-i` 忽略大小写，`-C 2` 显示上下文 |
| `find . -name "*.png"` | 按名字找文件；`-mtime -1` 找 24 小时内改过的 |
| `wc -l file` | 统计行数 |
| `diff a.txt b.txt` | 对比两个文件差异 |

**管道与重定向**是把小命令串成大工具的关键：

```bash
cat app.log | grep ERROR | wc -l       # 统计日志里 ERROR 的行数
command > out.txt 2>&1                  # 标准输出和错误都写进文件
ps aux | grep hugo | grep -v grep       # 查进程并排除 grep 自身
```

#### 4.3 权限与归属

| 命令 | 说明 |
| --- | --- |
| `ls -l` | 长格式：`-rw-r--r--` 依次是 所有者/组/其他 的读写执行权限 |
| `chmod +x script.sh` | 给脚本加执行权限；数字写法 `chmod 755` = `rwxr-xr-x` |
| `chown user:group file` | 改归属（Mac 上常配 `sudo`） |
| `sudo !!` | 用 sudo 重跑上一条命令（权限不足时的救命快捷键） |

#### 4.4 进程与系统

| 命令 | 说明 |
| --- | --- |
| `ps aux` | 快照式列出所有进程；常配管道 grep 使用 |
| `top` / `htop` | 实时监控（htop 需 brew 安装，交互更友好） |
| `kill -9 <PID>` | 强制杀进程；先试不带 -9 的优雅退出 |
| `pkill -f hugo` | 按命令名/匹配串杀进程 |
| `command &` | 后台运行；`jobs` 查看后台任务，`fg` 调回前台 |
| `Ctrl+Z` → `bg` | 把前台任务暂停丢到后台继续跑 |
| `uname -a` | 内核与系统信息 |
| `uptime` | 开机时长与负载 |

#### 4.5 压缩与网络传输（简要）

```bash
tar -czf backup.tar.gz dir/    # 打包并 gzip 压缩（c 创建 z gzip f 文件名）
tar -xzf backup.tar.gz         # 解压（x 解开）——装了 extract 插件可无脑 extract
curl -O https://example.com/f.zip   # 下载文件
ssh user@host                  # 远程登录；配 ~/.ssh/config 可给主机起别名
scp file user@host:~/          # 远程复制
```

---

### 5. Vim 生存指南

#### 5.1 为什么终端用户绕不开 Vim

不是因为要用它写代码，而是因为**太多工具默认调它**：`git commit` 不带 `-m` 时、`crontab -e`、`visudo`、`ssh` 到没有 GUI 的服务器上改配置……这些场景里打开的就是 Vim（或其兼容品 vi）。目标不是精通，而是**打开后能改字、能保存、能退出去**。

#### 5.2 三种模式

Vim 一切反直觉的设计都源于"模式"这个概念：

```
        i / a / o（进入插入）
普通模式 ─────────────→ 插入模式（正常打字）
   ↑  │                      │
   │  │ v（进入可视）         │ Esc
   │  ↓                      │
   │  可视模式（选中文本）────┘
   │
   └── :（进入命令行模式，输入 wq 回车保存退出）
```

- **普通模式**：启动后的默认模式，所有按键都是命令（`hjkl` 移动、`dd` 删行、`yy` 复制行）。**迷路了就狂按 Esc 回这里**。
- **插入模式**：按 `i`（光标前）`a`（光标后）`o`（下方新开一行）进入，此时才能像普通编辑器一样打字。
- **命令行模式**：按 `:` 进入，输入命令如 `:w`（保存）、`:q`（退出）、`:wq`（保存并退出）、`:q!`（不保存强制退出）。

#### 5.3 生存命令集

**移动**（普通模式下）：

| 按键 | 作用 |
| --- | --- |
| `h j k l` | 左 下 上 右（也支持方向键） |
| `0` / `$` | 行首 / 行尾 |
| `gg` / `G` | 文件开头 / 文件末尾 |
| `:n` 回车 | 跳到第 n 行 |
| `/关键词` 回车 | 向下搜索，`n` 下一个，`N` 上一个 |

**编辑**：

| 按键 | 作用 |
| --- | --- |
| `i` / `a` / `o` | 进入插入模式（前插 / 后插 / 下行插） |
| `x` | 删除光标处单个字符 |
| `dd` | 删除（剪切）整行 |
| `yy` → `p` | 复制整行 → 粘贴到下方 |
| `u` / `Ctrl+r` | 撤销 / 重做 |
| `d$` | 从光标删到行尾 |

**保存退出**（命令行模式）：

| 命令 | 作用 |
| --- | --- |
| `:wq` 或 `:x` | 保存并退出 |
| `:q!` | 不保存强制退出（改乱了就靠它） |
| `ZZ` | 普通模式下直接保存退出，两连击 |

**替换**：`:%s/旧/新/g` 全文替换（`%` 表示全文件范围，`g` 表示行内全部）；去掉 `%` 只替换当前行。

<div class="callout callout-tip">
<div class="callout-title"><i class="fas fa-lightbulb"></i> 逃生舱口</div>
<div class="callout-body">

被 Vim 卡住时按顺序尝试：`Esc` → 输入 `:q!` 回车。如果键盘布局异常（如远程服务器），`Esc` 可以换成 `Ctrl+C`。记住这一条，Vim 就永远不会"关不上"。

</div>
</div>

#### 5.4 最小可用 `~/.vimrc`

```vim
set number          " 显示行号
syntax on           " 语法高亮
set expandtab       " Tab 转空格
set shiftwidth=2    " 缩进宽度 2（Go/Python 项目按惯例改 4）
set softtabstop=2
set ignorecase      " 搜索忽略大小写
set hlsearch        " 高亮搜索结果
set backspace=indent,eol,start   " 让退格键行为和普通编辑器一致
```

---

### 6. 网络 / IP 排查命令

这一组命令解决三类问题：**我（本机）的 IP 是什么**、**到某台机器通不通**、**端口被谁占了**。

#### 6.1 查本机 IP

**ifconfig**（macOS 自带；新版 Linux 已由 `ip` 命令取代）：

```bash
ifconfig                    # 全部网卡信息
ifconfig en0                # 只看 en0（Mac 的 Wi-Fi 网卡）
```

输出重点看两行：`inet 192.168.1.23` 是**局域网 IPv4**，`inet6 fe80::...` 是 IPv6 链路本地地址。没有 `inet` 行说明没拿到 IP（没连上网/DHCP 失败）。

Mac 上更直接的写法：

```bash
ipconfig getifaddr en0      # 一行输出 Wi-Fi 的 IPv4，写脚本最方便
```

Linux 对应命令：

```bash
ip addr                     # 或简写 ip a，看所有网卡
ip -4 addr show eth0        # 只看指定网卡的 IPv4
hostname -I                 # 所有局域网 IPv4，空格分隔
```

**查公网 IP**（局域网地址查不到的，让外部服务告诉你）：

```bash
curl ifconfig.me            # 或 curl ip.sb / curl cip.cc（后者显示运营商归属地）
```

#### 6.2 连通性与路径

| 命令 | 说明 |
| --- | --- |
| `ping 8.8.8.8` | 测基础连通性与延迟（ICMP）；Mac 下 `Ctrl+C` 停止，`-c 4` 发 4 个包 |
| `ping baidu.com` | 能 ping 通说明 DNS 解析也正常；ping IP 通但域名不通 = DNS 问题 |
| `traceroute baidu.com` | 逐跳显示路由路径，定位哪一跳开始丢包（Linux 上是 `tracepath`） |
| `dig baidu.com` | 专业 DNS 查询：`A` 记录、TTL、使用的 DNS 服务器一目了然 |
| `nslookup baidu.com` | 简版 DNS 查询，Windows/Linux/Mac 通用 |
| `host baidu.com` | 更简洁的 DNS 查询 |

排查顺序经验法则：**ping IP 通不通 → ping 域名通不通 → dig 看解析结果对不对**，三步把"网络不通"切成物理链路、DNS 两类问题。

#### 6.3 端口与连接：netstat 及其替代

**netstat**（macOS 自带；新版 Linux 上已被 `ss` 取代）：

```bash
netstat -an                 # 所有连接，数字形式显示地址和端口（不做 DNS 反查，快）
netstat -rn                 # 路由表，看默认网关（Default gateway 那一行）
netstat -anv | grep LISTEN  # macOS 上查看监听端口（-v 能顺带看到 PID）
```

**lsof**——macOS 上查"端口被谁占"最常用的命令：

```bash
lsof -i :8080               # 谁在占用 8080 端口
lsof -iTCP -sTCP:LISTEN     # 所有处于监听状态的 TCP 端口
lsof -i -P -n | grep LISTEN # 加 -P（不解析端口名）-n（不解析主机名），输出更快更清晰
```

典型场景：`hugo server` 报 "port 1313 already in use"，先 `lsof -i :1313` 找到 PID，再 `kill -9 <PID>`。

**Linux 上的 ss**（netstat 的现代替代，速度更快）：

```bash
ss -tlnp                    # 监听中的 TCP 端口及进程（t=tcp l=listen n=数字 p=进程）
ss -s                       # 连接状态统计总览
```

**nc（netcat）**——测试远程端口通不通：

```bash
nc -zv example.com 443      # z=只探测不发数据 v=显示过程
```

#### 6.4 一组实战组合

```bash
# 场景①：完整查看本机网络三要素（IP / 网关 / DNS）
ipconfig getifaddr en0                    # 本机 IP
netstat -rn | grep default                # 默认网关
scutil --dns | grep nameserver            # DNS 服务器（macOS）

# 场景②：Web 服务起不来，逐步排查
ping 服务器IP              # 网络通吗？
nc -zv 服务器IP 80         # 端口通吗？
ssh 服务器 "ss -tlnp"      # 服务真的在监听吗？
# 若 ping 通、端口不通：多半是防火墙/安全组没放行

# 场景③：确认代理环境变量是否真的生效
env | grep -i proxy        # 看 http_proxy / https_proxy 指向
curl -I https://google.com # 2xx/3xx 说明流量已经走通
```

---

### 7. 总结

一张图收束全文的选择路径：

| 你要做什么 | 用什么 |
| --- | --- |
| 交互式日常使用 | zsh + Oh My Zsh + p10k + autosuggestions/syntax-highlighting |
| 写跨机器脚本 | `#!/usr/bin/env bash`，别依赖 zsh 特性 |
| 快速编辑文件 / 服务器上改配置 | Vim 生存集：`i` 改字、`Esc`、`:wq` / `:q!` |
| 查本机 IP | `ipconfig getifaddr en0`（Mac）/ `ip a`（Linux）/ `curl ifconfig.me` 查公网 |
| 查端口占用 | `lsof -i :端口`（Mac）/ `ss -tlnp`（Linux） |
| 查连通性 | `ping IP` → `ping 域名` → `dig` 三步定位 |
| 看路由与网关 | `netstat -rn` |

命令行工具的价值不在"背命令"，而在于知道**每类问题该摸哪个工具**：这份清单覆盖了日常 90% 的场景，剩下 10% 交给 `man 命令名` 和搜索引擎。
