#!/usr/bin/env bash
set -euo pipefail
umask 077

fail() {
  printf '安装停止：%s\n' "$*" >&2
  exit 1
}

[[ $# == 0 ]] || fail '请运行 bash install.sh。'
[[ $EUID != 0 ]] || fail '请用日常登录账号执行 bash install.sh，脚本会在需要时调用 sudo。'
[[ $(uname -s) == Linux && -d /run/systemd/system ]] ||
  fail '需要运行 systemd 的 Linux 主机。'

for command in curl getent openssl sudo systemctl systemd-analyze; do
  command -v "$command" >/dev/null || fail "请先安装 $command。"
done

IFS=: read -r account _ _ _ _ account_home _ < <(getent passwd "$EUID") ||
  fail '无法读取当前账号。'
[[ $account =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ && $account_home =~ ^/[a-zA-Z0-9_./@+-]+$ && -d $account_home ]] ||
  fail '当前账号或主目录无法直接用于服务模板。'

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
service=code-server.service
unit_path=/etc/systemd/system/$service
config_dir=$account_home/.config/code-server
config_path=$config_dir/managed-systemd.yaml

# Preserve a configured service, including one installed by a system package.
fragment=$(systemctl show --property=FragmentPath --value "$service")
if [[ -L $unit_path || ( -n $fragment && $fragment != "$unit_path" ) ]] ||
   { [[ -e $unit_path ]] && ! grep -Fxq '# Installed by code-server-setup' "$unit_path"; }; then
  fail "系统已有 $service。请继续使用原服务，或先由管理员处理现有配置。"
fi

binary=
for path in /usr/bin/code-server /usr/local/bin/code-server "$account_home/.local/bin/code-server"; do
  if [[ -x $path && -f $path ]]; then
    binary=$path
    break
  fi
done

temp_dir=$(mktemp -d)
staged_unit=
cleanup() {
  if [[ -n $staged_unit ]]; then
    sudo rm -f -- "$staged_unit" || true
  fi
  rm -rf -- "$temp_dir"
}
trap cleanup EXIT
if [[ -z $binary ]]; then
  case $(uname -m) in
    x86_64|aarch64) ;;
    *) fail '自动安装支持 Linux x86_64 和 aarch64。其他架构请先安装兼容的 code-server。' ;;
  esac
  curl --fail --silent --show-error --location --proto '=https' \
    https://code-server.dev/install.sh --output "$temp_dir/install-upstream.sh"
  sh "$temp_dir/install-upstream.sh" --method=standalone --prefix="$account_home/.local"
  binary=$account_home/.local/bin/code-server
fi
"$binary" --version >/dev/null || fail "无法执行 $binary。"

rendered_unit=$temp_dir/$service
{
  printf '%s\n' '# Installed by code-server-setup'
  sed -e "s|@USER@|$account|g" -e "s|@BINARY@|$binary|g" "$repo_dir/code-server.service.in"
} > "$rendered_unit"
systemd-analyze verify "$rendered_unit"

if [[ -e $unit_path ]] && ! cmp -s -- "$rendered_unit" "$unit_path"; then
  fail "现有 $unit_path 与本次生成的配置不同，请由管理员确认后再替换。"
fi

sudo true
mkdir -p -- "$config_dir"
if [[ -L $config_path || ( -e $config_path && ! -f $config_path ) ]]; then
  fail "配置文件路径不可用：$config_path"
fi
if [[ ! -f $config_path ]]; then
  password=$(openssl rand -hex 24)
  (set -o noclobber
   printf 'bind-addr: 127.0.0.1:8080\nauth: password\npassword: "%s"\ncert: false\n' "$password" > "$config_path")
  unset password
fi
chmod 600 -- "$config_path"

if [[ ! -e $unit_path ]]; then
  staged_unit=$(sudo mktemp "${unit_path}.XXXXXX")
  sudo install -o root -g root -m 0644 -- "$rendered_unit" "$staged_unit"
  sudo ln -T -- "$staged_unit" "$unit_path" ||
    fail "无法安装 $unit_path，可能已有其他安装正在进行。"
fi
sudo systemctl daemon-reload
sudo systemctl enable --now "$service"
systemctl is-enabled "$service"
systemctl is-active "$service"
printf '配置文件：%s\n' "$config_path"
