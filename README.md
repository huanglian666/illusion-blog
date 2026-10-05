# illusion-blog

基于 **Hugo** + [幻梦 Illusion](https://github.com/aizexintong/illusion) 主题构建的个人博客站点。

线上地址：<https://huanglian.top>

## 目录结构

采用「站点仓库 + 主题 submodule」分离的官方推荐用法：

```
illusion-blog/            # 站点仓库（本仓库）
├── hugo.toml             # 站点配置
├── content/
│   ├── posts/            # 文章（page bundle，每篇一个目录，图片随文章存放）
│   └── *.md              # 单页：关于、技能、友链、工具、归档、隐私政策、使用条款
├── data/theme.yaml       # 主题数据：首页、关于、技能、友链、工具等页面内容
├── i18n/zh-CN.yaml       # 界面文案与站点基础信息兜底
├── layouts/              # 站点级模板覆盖（优先级高于主题同名文件）
├── static/
│   ├── css/callouts.css  # 提示框样式
│   └── lib/katex/        # 自托管 KaTeX（数学公式）
└── themes/
    └── illusion/         # 主题（git submodule → huanglian666/illusion）
```

## 环境要求

- **Hugo** >= v0.146.0（extended 版）
- **Git**
- **Dart Sass**（必须，见下）

## Dart Sass

### 为什么非装不可

主题模板 `themes/illusion/layouts/partials/_layout/head/css.html` 里写死了
`transpiler: "dartsass"`，而 `assets/scss/main.scss` 用了 `@use "sass:map"`
和 156 处 `map.get()` —— 这是 Dart Sass 的模块系统语法，
Hugo extended 内置的 libsass（`hugo env` 里只有 `github.com/sass/libsass="3.6.6"`）
完全不支持。

不装的话 `hugo server` / `hugo` 会直接报：

```
TOCSS-DART: failed to transform "/scss/main.scss" (text/x-scss).
You need to install Dart Sass ...
```

主题 README 的「快速开始」漏写了这一步，但它确实是硬依赖。

### 当前安装方式（独立二进制，非 Homebrew 包）

| 项 | 路径 |
|---|---|
| 命令 | `/opt/homebrew/bin/sass` |
| 软链指向 | `/opt/homebrew/opt/dart-sass/sass` |
| 实体目录 | `/opt/homebrew/opt/dart-sass/` |
| 版本 | 1.105.1 |

安装步骤（macOS arm64）：

```bash
# 1. 下载官方 release 的独立二进制
curl -L -o /tmp/dart-sass.tar.gz \
  https://github.com/sass/dart-sass/releases/download/1.105.1/dart-sass-1.105.1-macos-arm64.tar.gz

# 2. 解压并放到固定位置
tar -xzf /tmp/dart-sass.tar.gz -C /tmp
cp -R /tmp/dart-sass /opt/homebrew/opt/dart-sass

# 3. 软链到 PATH
ln -sf /opt/homebrew/opt/dart-sass/sass /opt/homebrew/bin/sass

# 4. 验证
sass --version   # 应输出 1.105.1
```

### 几个要注意的点

- **brew 没有接管它**：`brew list` 里看不到，`brew upgrade` 也不会更新它。
  当初 `brew install sass/sass/sass` 需要先信任 `sass/sass` 和 `dart-lang/dart`
  两个第三方 tap，所以改用了独立二进制。
- **换电脑 / 重装系统后要重做一遍**上面四步，否则构建会报 `TOCSS-DART`。
- **卸载**：删两个东西即可 ——
  `rm -rf /opt/homebrew/opt/dart-sass /opt/homebrew/bin/sass`
- **升级**：去 <https://github.com/sass/dart-sass/releases> 下新版，
  替换 `/opt/homebrew/opt/dart-sass` 整个目录即可，软链不用动。
- **不要用 npm 的 `sass` 包**：那是 JS 壳，与 Hugo 的 embedded 协议不兼容，
  会报 `failed to write payload: write |1: broken pipe`。

## 本地开发

```bash
hugo server                 # 默认 http://localhost:1313/
hugo server --disableFastRender   # 改动模板后建议加这个，避免缓存
```

## 构建

```bash
hugo --gc
```

> 注意：修改了 taxonomy（标签 / 分类）后，`public/` 里**旧词条的目录不会自动清理**，
> 需要 `rm -rf public` 后重新构建，否则会残留已删除的标签页。

## 内容维护

### 新增文章

在 `content/posts/<slug>/index.md` 下新建（page bundle），图片直接放同目录、用相对路径引用：

```markdown
---
title: "文章标题"
date: 2026-01-01T00:00:00+08:00
tags: ["算法", "动态规划", "经典问题"]
categories: ["算法"]
weight: 50
description: "一句话摘要"
---

正文……
```

### 标签体系

分三层：**领域 / 策略 / 类型**。

| 层 | 算法类 | 生活类 |
|---|---|---|
| 领域 | `算法` | `街霸` / `家庭网络` / `杂项` |
| 策略 / 子类 | `分治法` `动态规划` `贪心法` `回溯法` `分支限界法` `随机化算法` `线性规划与网络流` `NP完全性理论` | — |
| 类型 | `算法思想` / `经典问题` | `基础概念` / `实战进阶` / `角色资料` / `实践记录` / `工具指南` |

同一标签下按 `weight` 升序排列，因此「基础概念」类文章要设更小的 `weight`，
才能排在具体问题前面。

### 数学公式

`hugo.toml` 已开启 `[markup.goldmark.extensions.passthrough]`，
正文可直接写 `$行内公式$` 和 `$$块级公式$$`。KaTeX 自托管在 `static/lib/katex/`，
**只在正文含公式的页面加载**（模板里用 `findRE` 检测）。

公式里出现中文必须包 `\text{}`，否则 KaTeX 渲染失败。

### 提示框

VuePress 的 `::: note` / `::: tip` 容器语法 Hugo 不认，已转换为 HTML：

```html
<div class="callout callout-note">
<div class="callout-title"><i class="fas fa-circle-info"></i> 说明</div>
<div class="callout-body">

正文（空行隔开，Goldmark 才会按 Markdown 解析）

</div>
</div>
```

支持 `callout-note` / `callout-tip` / `callout-warning` / `callout-danger` 四种，
样式在 `static/css/callouts.css`，配色复用主题 CSS 变量，自动适配深浅色主题。

### 首页名言

配置在 `data/theme.yaml` 的 `home.hero.quote.texts`，前端每次加载随机取一条，
同一次访问内不再变化。

### 站点级模板覆盖

`layouts/` 下的文件优先级高于主题同名文件，改样式/结构优先用覆盖，
不要直接改 `themes/illusion/`（那是 submodule）：

| 文件 | 覆盖内容 |
|---|---|
| `layouts/partials/_components/page-hero.html` | 首页名言随机逻辑 |
| `layouts/partials/_components/section-skills.html` | 技能图标改为读取数据里的 `icon` 字段 |
| `layouts/partials/_layout/head/css.html` | KaTeX 样式与 callout 样式（按需加载） |
| `layouts/partials/_layout/head/js.html` | KaTeX 脚本（按需加载） |

## 初始化步骤（从零搭建时参考）

```bash
hugo new site . --force
git submodule add https://github.com/huanglian666/illusion.git themes/illusion
cp themes/illusion/hugo.toml hugo.toml
cp -R themes/illusion/data/. data/
cp -R themes/illusion/content/. content/
cp -R themes/illusion/i18n/. i18n/
```

> `hugo new site` 会先建出空的 `data/`，所以用 `cp -R 源/. 目标/` 而不是
> `cp -r 源 目标`，否则会套成 `data/data/`。
