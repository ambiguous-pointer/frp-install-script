#!/bin/bash

# 设置默认值
frp_name="frp_0.51.0_linux_amd64"
frp_version="v0.51.0"
frp_install_path="/opt/software/frp"
server_addr=""
server_port=""
token="nullMiMa00@"
session_id=$(uuidgen)

# 函数用于打印帮助信息
function show_help {
    echo "用法: $0 --frp-name=<frp_name_value> --frp-version=<frp_version_value> --frp-install-path=<frp_install_path_value> -H <server_addr_value> -P <server_port_value> [--token=<token_value>] [--session-id=<session_id_value>]"
    echo "  --frp-name: 可选项，参数frp_name的值，默认值为${frp_name}"
    echo "  --frp-version: 可选项，参数frp_version的值，默认值为${frp_version}"
    echo "  --frp-install-path: 可选项，参数frp_install_path的值，默认值为${frp_install_path}"
    echo "  -H: 必填选项，参数server_addr的值"
    echo "  -P: 必填选项，参数server_port的值"
    echo "  --token: 可选项，参数token的值，默认为空"
    echo "  --session-id: 可选项，参数session_id的值，默认值为${session_id}"
    echo "  --help: 显示帮助信息"
}

# 处理选项参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --frp-name=*)
            frp_name="${1#*=}"
            ;;
        --frp-version=*)
            frp_version="${1#*=}"
            ;;
        --frp-install-path=*)
            frp_install_path="${1#*=}"
            ;;
        -H|--server-addr)
            server_addr="$2"
            shift ;;
        -P|--server-port)
            server_port="$2"
            shift ;;
        --token=*)
            token="${1#*=}"
            ;;
        --session-id=*)
            session_id="${1#*=}"
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "无效的选项: $1" >&2
            show_help
            exit 1
            ;;
    esac
    shift
done

# 判断必填选项 -H 和 -P 是否已经传入
if [ -z "$server_addr" ] || [ -z "$server_port" ]; then
    echo "选项 -H 和 -P 是必填选项，请指定参数值。"
    show_help
    exit 1
fi

# 输出参数值
echo "参数 --frp-name 的值为: $frp_name"
echo "参数 --frp-version 的值为: $frp_version"
echo "参数 --frp-install-path 的值为: $frp_install_path"
echo "参数 -H 的值为: $server_addr"
echo "参数 -P 的值为: $server_port"
echo "参数 --token 的值为: ${token:-无}"
echo "参数 --session-id 的值为: $session_id"

echo "\e[32m判断安装目录是否存在\e[0m"
# 判断目录是否存在
if [ -d "$frp_install_path" ]; then
    # 如果目录存在，则执行删除操作
    rm -rf "$directory"
    rm -rf /tmp/*
    echo "\e[32m目录已存在并成功删除。\e[0m"
else
    echo "\e[32m目录不存在，无需删除。\e[0m"
fi

echo "\e[32m开始下载文件\e[0m"
wget -P /tmp "https://ghproxy.com/https://github.com/fatedier/frp/releases/download/${frp_version}/${frp_name}.tar.gz" 

if [ $? -eq 0 ]; then
  echo "\e[32m下载frp成功\e[0m"
else
  echo "\e[31m下载frp失败\e[0m"
  exit 0
fi

echo "\e[32m开始创建安装路径\e[0m"
mkdir -p $frp_install_path

echo "\e[32m开始解压到安装路径\e[0m"
tar -zxvf /tmp/${frp_name}.tar.gz -C /opt/software/frp

echo "\e[32m开始 创建 frp服务文件\e[0m"
touch /tmp/frps.service
touch /tmp/frpc.service

echo "\e[32m开始 写入 frp服务文件\e[0m"
echo "
[Unit]
Description=Frp Client Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${frp_install_path}/${frp_name}/frpc -c ${frp_install_path}/${frp_name}/frpc.ini

[Install]
WantedBy=multi-user.target
" >> /tmp/frpc.service

echo "
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${frp_install_path}/${frp_name}/frps -c ${frp_install_path}/${frp_name}/frps.ini

[Install]
WantedBy=multi-user.target
" >> /tmp/frps.service

echo "\e[32m开始 创建 frp 配置文件\e[0m"

echo "
[common]
server_addr = ${server_addr}
server_port = ${server_port}
token = ${token}

login_fail_exit = false
log_file = ./frpc.log
log_level = debug
log_max_days = 7

[${session_id}-ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
" > ${frp_install_path}/${frp_name}/frpc.ini

echo "
[common]
bind_port = 10000

dashboard_addr = 0.0.0.0

token = ${token}
#privilege_mode_ports = 10000-50000
#log_file = ./frps.log
#log_level = info
#log_max_days = 7

dashboard_port = 10001

dashboard_user = admin

dashboard_pwd = admin123
" > ${frp_install_path}/${frp_name}/frps.ini


function create_frp_services {
    echo "\e[32m开始 创建 用户frpc服务\e[0m"
    cp /tmp/frps.service /usr/lib/systemd/system/
    cp /tmp/frpc.service /usr/lib/systemd/system/
    echo "\e[32m刷新 用户frpc服务\e[0m"
    systemctl daemon-reload
}
function run_frp_client_or_server_services {
    read -p "运行服务端还是客户端 请输入选项 (S/C): " choice
    # 使用条件语句根据用户输入执行不同的步骤
    if [ "$choice" = "S" ] || [ "$choice" = "s" ]; then
        ${frp_install_path}/${frp_name}/frps -c ${frp_install_path}/${frp_name}/frps.ini
    elif [ "$choice" = "C" ] || [ "$choice" = "c" ]; then
        ${frp_install_path}/${frp_name}/frps -c ${frp_install_path}/${frp_name}/frps.ini
    else
        echo "无效的选项，请输入 S或者C。"
    fi
}
function run_frp_client_or_server {
    read -p "运行服务端还是客户端 请输入选项 (S/C): " choice
    # 使用条件语句根据用户输入执行不同的步骤
    if [ "$choice" = "S" ] || [ "$choice" = "s" ]; then
        systemctl status frps.service
        systemctl restart frps.service
        systemctl status frps.service
        systemctl enable  frps.service
    elif [ "$choice" = "C" ] || [ "$choice" = "c" ]; then
        systemctl status frpc.service
        systemctl restart frpc.service
        systemctl status frpc.service
        systemctl enable  frpc.service
    else
        echo "无效的选项，请输入 S或者C。"
    fi
}
function no_create_frp_services {
    read -p "是否需要不基于服务的方式运行frp 请输入选项 (Y/N): " choice
    # 使用条件语句根据用户输入执行不同的步骤
    if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
        echo "你选择了选项 Y，运行frp"
        # 在此处添加步骤 A 的命令或函数调用
        run_frp_client_or_server_services
    elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
        echo "你选择了选项 N，未运行frp"
    else
        echo "无效的选项，请输入 Y或者N。"
    fi
}

# 打印提示信息并读取用户输入
read -p "是否需要创建用户服务 请输入选项 (Y/N): " choice

# 使用条件语句根据用户输入执行不同的步骤
if [ "$choice" = "Y" ] || [ "$choice" = "y" ]; then
    echo "你选择了选项 Y，执行创建用户服务"
    # 在此处添加步骤 A 的命令或函数调用
    create_frp_services
    run_frp_client_or_server
elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
    echo "你选择了选项 N，未创建用户服务"
    no_create_frp_services
else
    echo "无效的选项，请输入 Y或者N。"
fi

echo "\e[32mfrpc.service 配置文件位于====> /tmp/frpc.service\e[0m"
echo "\e[32mfrps.service 配置文件位于====> /tmp/frps.service\e[0m"
echo "\e[32mfrps.ini 配置文件位于====> ${frp_install_path}/${frp_name}/frps.ini\e[0m"
echo "\e[32mfrpc.ini 配置文件位于====> ${frp_install_path}/${frp_name}/frpc.ini\e[0m"
echo "\e[32m当前的 会话UID为${session_id}\e[0m"

