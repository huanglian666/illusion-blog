#!/usr/bin/env bash
# =============================================================================
# Netlify 构建脚本
#
# 由 netlify.toml 的 [build] command 调用。本地想复现线上构建时也可以直接跑：
#   HUGO_VERSION=0.167.0 DART_SASS_VERSION=1.105.1 bash scripts/netlify-build.sh
#
# 做三件事：
#   1. 拉取主题 submodule（主题是以 git submodule 形式引入的）
#   2. 安装与本地一致的 Hugo extended 和 Dart Sass
#   3. 构建站点，baseURL 取 Netlify 注入的部署地址
# =============================================================================

set -euo pipefail

HUGO_VERSION="${HUGO_VERSION:-0.167.0}"
DART_SASS_VERSION="${DART_SASS_VERSION:-1.105.1}"

echo "=============================================="
echo "Hugo        : ${HUGO_VERSION} (extended)"
echo "Dart Sass   : ${DART_SASS_VERSION}"
echo "=============================================="

# ---------------------------------------------------------------------------
# 1. 主题 submodule
# ---------------------------------------------------------------------------
echo "==> 拉取主题 submodule"
git submodule update --init --recursive

# ---------------------------------------------------------------------------
# 2. Hugo extended
#    装到 /tmp 下的独立目录并临时加进 PATH，避免污染 Netlify 镜像自带的版本
# ---------------------------------------------------------------------------
echo "==> 安装 Hugo extended ${HUGO_VERSION}"
curl -sSL -o /tmp/hugo.tar.gz \
  "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
mkdir -p /tmp/hugo-bin
tar -xzf /tmp/hugo.tar.gz -C /tmp/hugo-bin
export PATH="/tmp/hugo-bin:${PATH}"
hugo version

# ---------------------------------------------------------------------------
# 3. Dart Sass
#    必须装：主题模板写死 transpiler: "dartsass"，且 main.scss 使用了
#    @use "sass:map" 与 map.get()，Hugo extended 内置的 libsass 不支持。
# ---------------------------------------------------------------------------
echo "==> 安装 Dart Sass ${DART_SASS_VERSION}"
curl -sSL -o /tmp/dart-sass.tar.gz \
  "https://github.com/sass/dart-sass/releases/download/${DART_SASS_VERSION}/dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz"
tar -xzf /tmp/dart-sass.tar.gz -C /tmp
export PATH="/tmp/dart-sass:${PATH}"
sass --version

# ---------------------------------------------------------------------------
# 4. 构建
#
#    baseURL 按 Netlify 的部署上下文选择地址，不能一律用 DEPLOY_PRIME_URL：
#
#      正式部署（production）
#        DEPLOY_PRIME_URL 返回的是"分支专属地址"，形如
#        https://main--<站点名>.netlify.app，而不是站点主域名。
#        用它会让 og:url / og:image / RSS 等绝对地址都指向那个地址，
#        社交分享卡片上会显示错误的链接。
#        因此正式部署用 URL —— Netlify 保证它是站点主地址，
#        绑定自定义域名后即为该域名。
#
#      部署预览 / 分支部署
#        这两类部署本就该指向自己的预览地址，用 DEPLOY_PRIME_URL 才正确，
#        否则预览页里的链接会指向正式站。
#
#    Netlify 通过 CONTEXT 变量告知上下文：production / deploy-preview /
#    branch-deploy。取不到时按 production 处理。
# ---------------------------------------------------------------------------
if [ "${CONTEXT:-production}" = "production" ]; then
  BASE="${URL:-}"
else
  BASE="${DEPLOY_PRIME_URL:-${URL:-}}"
fi
echo "==> 部署上下文: ${CONTEXT:-production}"
if [ -n "${BASE}" ]; then
  BASE="${BASE%/}/"
  echo "==> baseURL: ${BASE}"
  hugo --gc --minify --baseURL "${BASE}"
else
  echo "==> 未取到 Netlify 部署地址，沿用 hugo.toml 中的 baseURL"
  hugo --gc --minify
fi

echo "==> 构建完成"
echo "    页面数: $(find public -name '*.html' | wc -l)"
echo "    产物大小: $(du -sh public | cut -f1)"
