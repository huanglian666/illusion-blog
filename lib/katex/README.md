# KaTeX（自托管）

- 版本：v0.19.0
- 来源：https://github.com/KaTeX/KaTeX/releases/tag/v0.19.0
- 许可证：MIT
- 用途：渲染文章里的数学公式（`$...$` 行内、`$$...$$` 块级）

只保留了运行所需的最小文件：`katex.min.css`、`katex.min.js`、`auto-render.min.js`、`contrib/copy-tex.min.js` 和 `fonts/`。
升级时用同样的方式替换即可，注意 `katex.min.css` 里的字体路径是相对的 `fonts/`。

`contrib/copy-tex.min.js` 是 KaTeX 官方 Copy-tex 扩展：复制页面上的公式时，剪贴板里的纯文本会还原为 LaTeX 源码（行内包 `$...$`、块级包 `$$...$$`）。KaTeX 0.16+ 使用它无需配套 CSS。
