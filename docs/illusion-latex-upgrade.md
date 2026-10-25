# Illusion 官方数学公式支持迁移

核对日期：2026-10-25。

## 升级目标与依据

- 原主题版本：`v1.1.0`，提交 `4de4a0c21891ade57dac0aebeefe9260c0a0e699`。
- 升级目标：`fd5f23c3291782c455258b688d9572e783773957`。核对时尚未发布新 tag，因此 submodule 固定到该提交，来源改为作者官方仓库。[官方提交](https://github.com/aizexintong/illusion/commit/fd5f23c3291782c455258b688d9572e783773957)
- 两者之间只有公式支持提交，涉及 README、SCSS、示例配置、head 入口和新增 math partial。[官方比较](https://github.com/aizexintong/illusion/compare/4de4a0c21891ade57dac0aebeefe9260c0a0e699...fd5f23c3291782c455258b688d9572e783773957)

## 最终方案

主题提供公式检测和初始化；站点仅适配同域资源并补充官方复制扩展，满足大陆访问和复制 LaTeX 的需求。

1. 保留 `params.enableMath = true` 及站点 Goldmark passthrough 的四组分隔符。单页 `math` 优先于站点开关；`math: false` 可关闭该页。[官方配置说明](https://github.com/aizexintong/illusion/blob/fd5f23c3291782c455258b688d9572e783773957/README.md#数学公式latex)
2. 站点 `head.html` 在主 CSS 前调用 `math-local.html`，它再调用主题官方 `math.html`。由官方判断正文是否含公式、排除代码并在 `#main` 渲染，沿用其 `throwOnError: false`、`strict: false`、`trust: false` 等设置。[官方 math partial](https://github.com/aizexintong/illusion/blob/fd5f23c3291782c455258b688d9572e783773957/layouts/partials/_layout/head/math.html)
3. `math-local.html` 只将官方输出中的 jsDelivr/unpkg 地址替换为同域路径，移除 CDN 回退，并在确实加载公式资源的页面补充 `copy-tex.min.js`。不复制公式检测或初始化逻辑。若上游版本或资源地址变化，构建报错，提醒同步本地资源。
4. `static/lib/katex/` 使用 KaTeX 0.16.22 官方发布文件（包括完整字体与 MIT 许可证），与主题版本一致。公式的 JS、CSS、字体和复制插件均随博客部署，无需额外公共 CDN 请求。[npm 发布包](https://registry.npmjs.org/katex/-/katex-0.16.22.tgz)
5. 官方 copy-tex 将复制内容的纯文本还原为 LaTeX，行内包 `$...$`，块级包 `$$...$$`；富文本格式仍为 HTML，需要源码时使用纯文本粘贴。[官方扩展说明](https://github.com/KaTeX/KaTeX/blob/v0.16.22/contrib/copy-tex/README.md)
6. 删除旧 `katex-init.js` 及 head/css.html、head/js.html 两份覆盖，CSS/JS 编译恢复使用主题模板。callout 样式由站点 head 独立加载，其他站点定制保留。

公式字号和块级公式横向滚动由官方 SCSS 维护。自托管减少额外第三方依赖，但访问速度仍取决于博客托管与网络；不等于对大陆所有网络的可用性保证。

## 验证结果

- Hugo 0.168.0 extended、Dart Sass 1.105.1：根域名与 GitHub Pages 子路径构建均通过，无构建警告。CI 固定的 Hugo 0.167.0 未在本机另行运行。
- 浏览器检查 10 篇含公式文章，共 339 个公式，无 KaTeX 渲染错误；三份脚本和公式样式均为同域资源。首页、代码专用测试页、`math: false` 页面不加载公式资源。
- 临时文章覆盖四种分隔符和中文公式。实际全选复制后，剪贴板包含 `$E=mc^2$`、`$a_i+b_i$`、带完整中文源码与换行的 `$$...$$`，及 `$$\\sum_{i=1}^{n} i$$`。
- 两种 baseURL 下，10 篇公式页的四个资源引用均能映射到构建文件；CSS 的 60 个字体引用全部存在，旧 `katex-init.js` 和旧路径 `auto-render.min.js` 不再输出。
- 65 个库文件（含许可证）与 npm 0.16.22 发布包逐字节一致。模拟上游版本不匹配，构建按预期失败并提示同步资源。

## 维护与回退

- 更新资源见 `static/lib/katex/README.md`；资源已保存到仓库，构建无需下载或 npm 安装。
- 升级主题时检查 head 新入口，保持 `math-local.html` 与主题 KaTeX 版本匹配。保留同域适配，不恢复旧自写初始化器。
- 公式中文继续用 `\text{}`，正文与 URL 无需更改。
- 迁移前站点提交为 `81d095a`。回退应同时还原主题指针、`.gitmodules`、head、资源与配置；仅将主题切回 v1.1.0 会缺失官方 math partial。完整撤销迁移提交后执行 `git submodule sync -- themes/illusion`、`git submodule update --init --recursive`，再用 `hugo --gc --cleanDestinationDir` 重建。
- 两套部署分别按根域名与 `/illusion-blog/` 子路径构建，不复用产物。
