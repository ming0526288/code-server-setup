# CHG-001 code-server 部署仓库

新增独立安装脚本、systemd 服务模板和 README。沿用现有部署的服务名和开机自启方式。模板以安装账号运行，首次生成仅账号可读的随机密码配置，默认地址为 `127.0.0.1:8080`。已有其他同名服务时停止安装。安装入口为 `bash install.sh`。

依据为 Coder 的官方安装说明和 SSH 转发说明，均在 README 链接。3GPP/数学推导不适用。核验记录见 [TEST-001](../tests/TEST-001_code-server部署核验.md)。
