# frp-install-script
frp 快速简易安装脚本
## 使用步骤
 1. 使用`curl -O https://raw.githubusercontent.com/ambiguous-pointer/frp-install-script/main/frp-install-script.sh && chmod u+x frp-install-script.sh` 下载bash脚本
 2. 使用`bash frp-install-script.sh --help`查看使用说明
 3. 例如: 如果是服务器部署只需要输入 `bash frp-install-script.sh -H x.x.x.x -P xxx` 
 4. 
 ```
 frp_0.51.0_linux_amd64/frps.ini
\e[32m开始 创建 frp服务文件\e[0m
\e[32m开始 写入 frp服务文件\e[0m
\e[32m开始 创建 frp 配置文件\e[0m
是否需要创建用户服务 请输入选项 (Y/N): [输入Y创建服务]
 ```
 5. 运行服务输入 S
 6. 按照引导即可

  --frp-name: 可选项，参数frp_name的值，默认值为frp_0.51.0_linux_amd64
  --frp-version: 可选项，参数frp_version的值，默认值为v0.51.0
  --frp-install-path: 可选项，参数frp_install_path的值，默认值为/opt/software/frp
  -H: 必填选项，参数server_addr的值
  -P: 必填选项，参数server_port的值
  --token: 可选项，参数token的值，默认为空
  --session-id: 可选项，参数session_id的值，默认值为5e5859a8-01c4-4aa7-917f-74630cef6978
  --help: 显示帮助信息

> 本脚本基本逻辑只是简单封装了下一般安装逻辑  其中指定版本功能 本质就是拼接不同版本的url地址实现
> 此外 本脚本只在 CentOS下测试过其他Linux系统不保证百分百成功