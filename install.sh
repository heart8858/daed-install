#!/bin/sh
# Public launcher only. No core, account, subscription or credential is embedded.
set +x
set -eu
umask 077
PROVIDER=
TOKEN_STDIN=0
ARCHIVE_SHA='30d1f73c6ce2dc8e7e99025545f8dd7e79686d50b79f487bc5580f7509889f85'
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
for TOOL in curl sha256sum tar mktemp awk df; do
 command -v "$TOOL" >/dev/null || { echo "缺少 $TOOL，请先安装匹配系统的工具。" >&2; exit 1; }
done
echo 'daed 10x6.5 + management-13 一键安装（离线包）'
echo '新装后按提示读取初始账号；已有安装保留用户数据库，失败自动恢复。'
FREE=$(df -Pk /root | awk 'NR==2 {print $4}')
test "${FREE:-0}" -ge 640000 || {
 echo "根分区可用空间不足（${FREE:-0} KB，需约 650 MB）。请先清理 /root 后重试。" >&2
 exit 1
}
if [ -z "$PROVIDER" ]; then
 test "$TOKEN_STDIN" = 0 || { echo '--token-stdin requires --provider' >&2; exit 2; }
 printf '下载来源：1. Gitee  2. GitHub [默认 1]：' > /dev/tty
 IFS= read -r CHOICE < /dev/tty || exit 1
 case "$CHOICE" in ''|1) PROVIDER=gitee ;; 2) PROVIDER=github ;; *) echo '请选择 1 或 2。' >&2; exit 2 ;; esac
fi
case "$PROVIDER" in
 gitee) URL='https://gitee.com/api/v5/repos/meowchow/daed-modify/releases/1254451/attach_files/3534321/download' ;;
 github) URL='https://api.github.com/repos/heart8858/daed-modify/releases/assets/689078570' ;;
 *) echo 'Invalid provider' >&2; exit 2 ;;
esac
WORK=$(mktemp -d /root/daed-oneclick.XXXXXX)
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
 test -r "$DAED_TOKEN_FILE" || { echo "令牌文件不可读：$DAED_TOKEN_FILE" >&2; exit 1; }
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
echo '正在下载安装包（约 63 MB）…'
curl -fsSL --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 1800 \
 --retry 2 --retry-delay 5 -H @"$WORK/header" -H 'Accept: application/octet-stream' \
 "$URL" -o "$WORK/oneclick.tar.gz" || {
 echo '下载失败：请检查网络、令牌权限及所选仓库是否可访问。' >&2; exit 1;
}
GOT=$(sha256sum "$WORK/oneclick.tar.gz" | awk '{print $1}')
test "$GOT" = "$ARCHIVE_SHA" || {
 echo '安装包校验失败，未执行。' >&2; exit 1;
}
mkdir "$WORK/pkg"
tar -xzf "$WORK/oneclick.tar.gz" -C "$WORK/pkg" || {
 echo '安装包展开失败，未执行。' >&2; exit 1;
}
for FILE in install.sh SHA256SUMS daed-install-core daed-10x6.5-install.1-x86_64.tar.gz daed-install-management daed-management-13-x86_64.tar.gz; do
 test -f "$WORK/pkg/$FILE" || { echo "安装包不完整：缺少 $FILE。" >&2; exit 1; }
done
echo '校验通过，开始安装…'
sh "$WORK/pkg/install.sh"
