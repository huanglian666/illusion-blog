/*
 * KaTeX 自动渲染初始化。
 *
 * 作用：扫描页面文本，把公式定界符之间的内容交给 KaTeX 渲染。
 * 定界符需与 hugo.toml 里 [markup.goldmark.extensions.passthrough.delimiters] 保持一致：
 *   $$...$$ / \[...\]  块级公式
 *   $...$  / \(...\)   行内公式
 *
 * ignoredTags 里的 pre / code 会让代码块内的 $ 不被误当成公式。
 * throwOnError=false 保证单条公式写错时不会整页崩掉，只把错误渲染成红色提示。
 */
document.addEventListener('DOMContentLoaded', function () {
  if (typeof renderMathInElement !== 'function') return;
  renderMathInElement(document.body, {
    delimiters: [
      { left: '$$', right: '$$', display: true },
      { left: '\\[', right: '\\]', display: true },
      { left: '$', right: '$', display: false },
      { left: '\\(', right: '\\)', display: false }
    ],
    ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code', 'option'],
    throwOnError: false
  });
});
