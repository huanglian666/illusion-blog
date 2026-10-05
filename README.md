# illusion-blog

基于 **Hugo** + [幻梦 Illusion](https://github.com/aizexintong/illusion) 主题构建的个人博客站点。

当前仓库为空白骨架，站点结构与内容后续逐步搭建。

## 计划结构

官方推荐用法是「站点仓库 + 主题 submodule」分离：

```
illusion-blog/            # 站点仓库（本仓库）
├── hugo.toml             # 站点配置（从主题仓库复制后按需修改）
├── content/              # 站点内容：页面与文章
├── data/theme.yaml       # 主题数据：首页、关于、技能、友链、工具等页面数据
├── i18n/                 # 多语言文案
├── static/               # 静态资源
└── themes/
    └── illusion/         # 主题（git submodule，指向主题仓库）
```

## 环境要求

- **Hugo** >= v0.146.0（extended 版）
- **Dart Sass**：主题模板使用 `transpiler: "dartsass"` 编译 SCSS，
  且 `assets/scss/main.scss` 使用了 `@use "sass:map"` 与 `map.get()`，
  libsass（Hugo extended 内置）不支持，**必须额外安装 Dart Sass**，
  否则构建会报 `TOCSS-DART: failed to transform`。
- **Git**

## 初始化步骤（参考）

```bash
hugo new site . --force
git submodule add <主题仓库地址> themes/illusion
cp themes/illusion/hugo.toml hugo.toml
cp -r themes/illusion/data/ data/
cp -r themes/illusion/content/ content/
cp -r themes/illusion/i18n/ i18n/
```
