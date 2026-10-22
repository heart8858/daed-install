#!/bin/sh
# Public launcher only. No core, account, subscription or credential is embedded.
set +x
set -eu
umask 077
PROVIDER=
TOKEN_STDIN=0
while [ "$#" -gt 0 ]; do
 case "$1" in
  --provider) test "$#" -ge 2 || exit 2; PROVIDER=$2; shift 2 ;;
  --token-stdin) TOKEN_STDIN=1; shift ;;
  --help) echo 'Usage: sh install.sh [--provider gitee|github] [--token-stdin]'; exit 0 ;;
  *) echo 'Unknown option; use --help' >&2; exit 2 ;;
 esac
done
test "$(id -u)" = 0 || { echo '请以 root 运行。' >&2; exit 1; }
test "$(uname -m)" = x86_64 || { echo '仅支持 x86_64。' >&2; exit 1; }
for TOOL in curl sha256sum jsonfilter mktemp; do
 command -v "$TOOL" >/dev/null || { echo "缺少 $TOOL，请先安装匹配系统的工具。" >&2; exit 1; }
done
echo 'daed 管理组件 · management-9'
echo '仅更新面板，必须已有10x6.2核心；不替换核心、不应用待应用配置。失败自动恢复。'
if [ -z "$PROVIDER" ]; then
 test "$TOKEN_STDIN" = 0 || { echo '--token-stdin requires --provider' >&2; exit 2; }
 printf '下载来源：1. Gitee  2. GitHub [默认 1]：' > /dev/tty
 IFS= read -r CHOICE < /dev/tty || exit 1
 case "$CHOICE" in ''|1) PROVIDER=gitee ;; 2) PROVIDER=github ;; *) echo '请选择 1 或 2。' >&2; exit 2 ;; esac
fi
case "$PROVIDER" in
 gitee) URL='https://gitee.com/api/v5/repos/meowchow/daed-modify/releases/1230701/attach_files/3467360/download'; SHA='53010a89c4b5d5f5aedd98963c865de32aff931d28a1ee663b6f6d18f684734c' ;;
 github) URL='https://api.github.com/repos/heart8858/daed-modify/releases/assets/666105154'; SHA='61b579f19b41d49458ec89ffeeaabe5c28aa2819455af5763abb59337910f45e' ;;
 *) echo 'Invalid provider' >&2; exit 2 ;;
esac
WORK=$(mktemp -d /tmp/daed-quickstart.XXXXXX)
TTY_STATE=
cleanup() {
 if [ -n "$TTY_STATE" ]; then stty "$TTY_STATE" < /dev/tty 2>/dev/null || :; fi
 rm -rf "$WORK"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
if [ "$TOKEN_STDIN" = 1 ]; then
 cat > "$WORK/token"
elif [ -n "${DAED_TOKEN_FILE:-}" ]; then
 cat "$DAED_TOKEN_FILE" > "$WORK/token"
else
 command -v stty >/dev/null || { echo '缺少 stty；也可用 DAED_TOKEN_FILE 指定令牌文件。' >&2; exit 1; }
 TTY_STATE=$(stty -g < /dev/tty)
 printf '%s 访问令牌（输入不显示）：' "$PROVIDER" > /dev/tty
 stty -echo < /dev/tty
 TOKEN=
 IFS= read -r TOKEN < /dev/tty || { echo '未读到令牌。' >&2; exit 1; }
 stty "$TTY_STATE" < /dev/tty
 TTY_STATE=
 printf '\n' > /dev/tty
 printf '%s\n' "$TOKEN" > "$WORK/token"
 unset TOKEN
fi
# Header injection is rejected before the first network request. A single token
# line is accepted with or without a final newline; credentials never enter argv.
awk 'NR != 1 || /[[:space:][:cntrl:]]/ || length($0) == 0 {bad=1} END {exit (NR != 1 || bad)}' "$WORK/token" || {
 echo '令牌为空或格式无效；请仅输入令牌本身。' >&2; exit 1;
}
awk '{print "Authorization: Bearer " $0}' "$WORK/token" > "$WORK/header"
echo '正在获取并校验安装入口…'
curl -fsSL --proto '=https' --proto-redir '=https' --connect-timeout 10 --max-time 180 \
 -H @"$WORK/header" -H 'Accept: application/octet-stream' "$URL" -o "$WORK/entry.sh" || {
 echo '下载失败：请检查网络及所选仓库的令牌权限。' >&2; exit 1;
}
test "$(sha256sum "$WORK/entry.sh" | cut -d ' ' -f1)" = "$SHA" || {
 echo '安装入口校验失败，未执行。' >&2; exit 1;
}
DAED_TOKEN_FILE="$WORK/token" sh "$WORK/entry.sh"
