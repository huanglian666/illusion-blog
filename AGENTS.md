# AGENTS.md

面向 AI 编码代理的项目说明。**动手前先读「环境要求」与「已知坑」** —— 这个项目有一步环境依赖漏装就直接构建失败。

## 项目定位

基于 **Hugo + [幻梦 Illusion](https://github.com/aizexintong/illusion) 主题**的个人博客站点。文章为 page bundle，图片随文章存放。

| 项 | 值 |
| --- | --- |
| 线上地址 | <https://博客.黄炼.site>（punycode `xn--9krq6q.xn--6pxx59g.site`） |
| 仓库 | `git@github.com:huanglian666/illusion-blog.git`，分支 `main` |
| 文章数 | 18 篇 |

> **域名别搞混**：`huanglian.top` 服务的是另一个 VuePress 站（`../vuepress-starter`），不是本站。本站自己的域名以 `hugo.toml` 的 `params.domain` 为准。

## 快速命令

```bash
hugo server                       # http://localhost:1313/
hugo server --disableFastRender   # 改模板后建议加，避免缓存
hugo --gc                         # 构建到 public/
```

## 环境要求

- **Hugo extended** ≥ v0.146.0（本地 0.167.0，与 CI 一致）
- **Dart Sass —— 硬依赖，必须装**

### 为什么 Dart Sass 非装不可

主题模板 `themes/illusion/layouts/partials/_layout/head/css.html` 写死了 `transpiler: "dartsass"`，而 `themes/illusion/assets/scss/main.scss` 用了 `@use "sass:map"` 和 156 处 `map.get()` —— 这是 Dart Sass 的模块语法，Hugo extended 内置的 libsass 完全不支持。漏装会直接报：

```
TOCSS-DART: failed to transform "/scss/main.scss" (text/x-scss).
You need to install Dart Sass ...
```

**安装方式**：独立二进制放 `/opt/homebrew/opt/dart-sass`，软链到 `/opt/homebrew/bin/sass`（当前 1.105.1）。完整步骤见 `README.md`。

- **brew 不管它**：`brew list` 里看不到，`brew upgrade` 不会更新。换机器要重做一遍。
- **不要用 npm 的 `sass` 包**：那是 JS 壳，与 Hugo 的 embedded 协议不兼容，会报 `failed to write payload: write |1: broken pipe`。

## 目录结构

```
├── hugo.toml             # 站点配置（[params] 里有 author/domain/功能开关/评论系统等）
├── content/
│   ├── posts/<slug>/     # 文章（page bundle，图片放同目录）
│   └── *.md              # 单页：about / skills / links / tools / archives / privacy / terms
├── data/theme.yaml       # 主题数据：首页 hero、关于、技能、友链、工具、站点信息
├── i18n/zh-CN.yaml       # 界面文案兜底
├── layouts/              # 站点级模板覆盖（优先级高于主题同名文件）
├── static/
│   ├── css/callouts.css  # 提示框样式
│   └── lib/katex/        # 自托管 KaTeX
└── themes/illusion/      # 主题（git submodule，勿直接改）
```

`layouts/` 下的覆盖文件：

| 文件 | 覆盖内容 |
| --- | --- |
| `partials/_components/page-hero.html` | 首页名言随机逻辑 |
| `partials/_components/section-skills.html` | 技能图标改为读取数据里的 `icon` 字段 |
| `partials/_layout/head/css.html` | KaTeX 与 callout 样式（按需加载） |
| `partials/_layout/head/js.html` | KaTeX 脚本（按需加载） |

**要改样式或结构，优先用 `layouts/` 覆盖，不要直接改 `themes/illusion/`** —— 那是 submodule，改动不会进本站仓库。

## 核心约定

### 1. 文章是 page bundle

`content/posts/<slug>/index.md`，图片直接放同目录、相对路径引用。

### 2. 标签体系分三层

**领域 / 策略 / 类型**：

| 层 | 算法类 | 生活类 |
| --- | --- | --- |
| 领域 | `算法` | `街霸` / `家庭网络` / `杂项` |
| 策略 / 子类 | `分治法` `动态规划` `贪心法` `回溯法` `分支限界法` `随机化算法` `线性规划与网络流` `NP完全性理论` | — |
| 类型 | `算法思想` / `经典问题` | `基础概念` / `实战进阶` / `角色资料` / `实践记录` / `工具指南` |

同一标签下按 `weight` 升序排列，所以「基础概念」类文章要设**更小**的 `weight`，才能排在具体问题前面。

### 3. KaTeX：公式里的中文必须包 `\text{}`

`hugo.toml` 已开启 `[markup.goldmark.extensions.passthrough]`，正文可直接写 `$行内$` 和 `$$块级$$`。KaTeX 自托管在 `static/lib/katex/`，**只在正文含公式的页面加载**（模板用 `findRE` 检测）。

```markdown
✅ $\text{风险曝光度} = 1000000 \times 0.5\%$
❌ $风险曝光度 = 1000000 \times 0.5\%$   # 裸中文渲染失败
```

### 4. 提示框用 HTML，不用 `:::`

VuePress 的 `::: note` / `::: tip` 容器语法 Hugo 不认，已转成 HTML：

```html
<div class="callout callout-note">
<div class="callout-title"><i class="fas fa-circle-info"></i> 说明</div>
<div class="callout-body">

正文（空行隔开，Goldmark 才会按 Markdown 解析）

</div>
</div>
```

支持 `callout-note` / `callout-tip` / `callout-warning` / `callout-danger`，样式在 `static/css/callouts.css`，配色复用主题 CSS 变量，自动适配深浅色。

### 5. 首页名言

配置在 `data/theme.yaml` 的 `home.hero.quote.texts`，前端每次加载随机取一条。

## 已知坑

| 坑 | 说明 |
| --- | --- |
| **Dart Sass 漏装** | 见上，构建直接失败。换机器/重装系统后必查 |
| **改 taxonomy 后要 `rm -rf public`** | 否则 `public/` 里残留已删除的标签页目录，不会被自动清理 |
| **两套部署的 baseURL 不同** | Netlify 部署在域名根目录，GitHub Pages 部署在 `/illusion-blog/` 子路径，**产物不能互相复用**。这也是 Netlify 选择「从源码重新构建」而非「拿 GH Pages 产物部署」的原因 |
| Netlify 的 baseURL 取值 | 正式部署用 `URL`，预览部署用 `DEPLOY_PRIME_URL`（`scripts/netlify-build.sh` 按 `CONTEXT` 区分）。改这段要留意 og:url / og:image / RSS 的绝对地址会跟着变 |
| submodule 未拉取 | 换机器后先 `git submodule update --init --recursive`，否则 `themes/illusion` 是空的 |

## CI / 部署

| 工作流 | 触发 | 作用 |
| --- | --- | --- |
| `netlify.toml` + `scripts/netlify-build.sh` | Netlify 侧 | 拉 submodule、装 Hugo extended + Dart Sass、构建 |
| `.github/workflows/deploy.yml` | push `main` / 手动 | 构建并发布到 GitHub Pages |

两边都固定 `HUGO_VERSION = 0.167.0`，Netlify 另固定 `DART_SASS_VERSION = 1.105.1`，目的是让本地、GH Actions、Netlify 三处版本完全一致。

## 交付前检查

```bash
hugo --gc 2>&1 | tail -20
```

确认无 `TOCSS-DART` 报错、无 KaTeX 相关警告。改了正文链接或新增分类后，另外确认产物里对应 HTML 已生成。
