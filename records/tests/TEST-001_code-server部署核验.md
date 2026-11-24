# TEST-001 code-server 部署核验

| 核验 | 实际结果 |
|---|---|
| `bash -n install.sh` | Bash 语法通过 |
| `bash install.sh invalid` | 退出 1，提示无参数运行 |
| `bash install.sh` 在本机已有同名服务时运行 | 退出 1，停在安装前检查 |
| 渲染模板后执行 `systemd-analyze verify`，用 `systemctl --root` 在临时目录注册服务 | 两条命令均退出 0。临时环境中的 `is-enabled` 返回 `enabled` |
| 隔离目录下模拟安装与重装 | 使用本机 code-server 可执行文件，替换系统目录并模拟 sudo、systemctl 等系统调用。检查首次配置、权限、自启命令、重装保留自定义端口和拒绝不同同名服务 |
| `systemd-run` 临时启动本机 code-server 4.145.2 | 使用独立回环端口、配置和数据目录。探活 HTTP 200，首页提示登录，随机密码登录后首页返回 HTTP 200。测试服务已停止 |

临时服务前两次验证停在探活判据，应用空闲时接口仍有 HTTP 200，返回状态 `expired`。将就绪判断改为 HTTP 状态，加入登录前后核对，第三次通过。日志保存在宿主 journal。

未从头安装上游发行包，未重启服务器，也未连接 UE 主机执行安装。3GPP/数学推导不适用。
