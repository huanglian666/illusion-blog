# KaTeX 官方资源（同域托管）

- 版本：0.16.22，与 Illusion `fd5f23c` 的渲染版本一致。
- 来源：[npm 官方版本包](https://registry.npmjs.org/katex/-/katex-0.16.22.tgz)。
- 许可证：MIT，原文见本目录 `LICENSE`。
- 文件均来自发布包，未修改库代码。保留 `dist/katex.min.css`、`dist/katex.min.js`、
  `dist/contrib/auto-render.min.js`、`dist/contrib/copy-tex.min.js` 和 `dist/fonts/`，
  相对目录保持不变（去掉 `dist/` 前缀）。

本站 `layouts/partials/_layout/head/math-local.html` 调用主题官方 math partial，
仅将资源地址替换为同域路径，去除 CDN 回退并补充官方 copy-tex。
公式检测、页面开关、渲染分隔符与初始化逻辑仍由主题维护。

copy-tex 使选中公式后复制的纯文本成为带 `$...$` / `$$...$$` 定界符的 LaTeX。
富文本剪贴板仍为 HTML；需要源码时，请粘贴到文本编辑器或使用“粘贴为纯文本”。

## 更新

1. 核对主题 `layouts/partials/_layout/head/math.html` 中的 KaTeX 版本。
2. 下载同版本 npm 发布包，替换上述文件及 `LICENSE`；不要混用版本。
3. 同步 `math-local.html` 的 `$version` 与本文档版本。
4. 保留 CSS 相对引用的完整 `fonts/`。不需要恢复旧的自写 `katex-init.js`。
5. 干净构建，检查根路径与 `/illusion-blog/` 子路径下的公式资源、实际渲染和复制结果。

依赖已随仓库保存，日常构建无需 npm 安装或下载 KaTeX。此方式减少额外 CDN
依赖；实际访问速度仍取决于博客自身的托管和网络。
