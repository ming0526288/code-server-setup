# code-server 开机自启

适合在使用 systemd 的 Linux 服务器上部署浏览器版 VS Code。服务名为 `code-server.service`，以运行安装脚本的账号启动。登录后可以打开该账号有权访问的项目目录。

## 在服务器上安装

需要有 `sudo` 权限的日常登录账号，以及 Git、Bash、curl、OpenSSL 和 systemd 工具。自动下载使用 Coder 的官方 Linux 发行包，适用于满足官方运行库要求的 x86_64 和 aarch64 服务器，包括常见的 Ubuntu、Debian 和 Fedora。服务器需能访问 GitHub 和 code-server.dev。已安装在 `/usr/bin`、`/usr/local/bin` 或当前账号 `~/.local/bin` 的 code-server 会直接复用。[官方安装与运行库要求](https://coder.com/docs/code-server/install#standalone-releases)

这是私有仓库。新服务器须先用有权限的 GitHub 账号登录，例如使用 `gh auth login` 后执行 `gh auth setup-git`，再运行下面的命令。

```bash
git clone https://github.com/ming0526288/code-server-setup.git
cd code-server-setup
bash install.sh
```

安装成功后会显示 `enabled` 和 `active`。首次安装会生成随机密码，保存在当前账号的 `~/.config/code-server/managed-systemd.yaml` 中。用 `nano ~/.config/code-server/managed-systemd.yaml` 查看或修改 `password`，修改后运行 `sudo systemctl restart code-server`。重复运行脚本时沿用已有密码和配置。系统已有不同的同名服务时，脚本会提示。

## 从另一台电脑打开网页

在要开浏览器的电脑上执行下面的命令。把 `用户名@服务器地址` 替换成实际的 SSH 登录地址。保持 SSH 终端打开，再在浏览器访问 <http://127.0.0.1:8081>。服务在服务器的 `127.0.0.1:8080` 监听。[官方 SSH 转发说明](https://coder.com/docs/code-server/guide#port-forwarding-via-ssh)

```bash
ssh -N -L 8081:127.0.0.1:8080 用户名@服务器地址
```

在登录页面输入服务器配置里的密码，再用「文件 → 打开文件夹」选择项目。在 UE 机器上，可以选择 `/home/lbh/oiwireless/oi-wireless-ran`。

## 日常管理

| 用途 | 命令 |
|---|---|
| 启动 | `sudo systemctl start code-server` |
| 开机自启并立即启动 | `sudo systemctl enable --now code-server` |
| 查看运行状态 | `systemctl status code-server --no-pager` |
| 重启服务 | `sudo systemctl restart code-server` |
| 停止本次运行 | `sudo systemctl stop code-server` |
| 关闭自启并停止服务 | `sudo systemctl disable --now code-server` |
| 查看最近日志 | `sudo journalctl -u code-server -n 50 --no-pager` |

如果服务器的 8080 端口已被占用，把配置中的 `bind-addr` 改成例如 `127.0.0.1:8082`，然后重启服务，并把 SSH 命令最后的 `8080` 改为 `8082`。

可以在服务器上运行 `curl -fsS http://127.0.0.1:8080/healthz` 确认网页已监听。改过端口时用实际端口。
