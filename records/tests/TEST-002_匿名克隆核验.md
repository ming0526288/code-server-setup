# TEST-002 匿名克隆核验

执行 `gh repo edit ming0526288/code-server-setup --visibility public` 后，在临时目录禁用 Git 的系统配置、全局配置、凭据助手和交互提示，再用 HTTPS 执行浅克隆。克隆退出 0，GitHub 查询返回 `isPrivate=false`。本次仅核验仓库访问，3GPP/数学推导不适用。
