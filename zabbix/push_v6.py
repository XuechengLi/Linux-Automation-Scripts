root@tools:/opt/zabbix# cat push_v6.py 
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Zabbix → 钉钉 JAR 服务监控日报（动态获取远端 jar 包）
单文件版，直接 crontab
使用 Markdown 渲染（修正内存单位为 MB，优化表格样式）
"""
import json
import hmac
import hashlib
import base64
import urllib.parse
import time
import datetime as dt
import requests
import paramiko
from typing import List

# ========== 1. Zabbix 配置 ==========
ZABBIX_URL = "http://:8088/zabbix/api_jsonrpc.php"   # Zabbix API 地址
ZABBIX_USER = "Admin"
ZABBIX_PASSWORD = "Houbaoyan666"

# ========== 2. 钉钉机器人配置 ==========
DING_ACCESS = "" # 钉钉机器人 Access Token
DING_SECRET = "" # 钉钉机器人 Secret

# ========== 3. 主机列表 ==========
HOSTS = [
    {"name": "pord-1", "ip": "",  "port": 22, "user": "dev", "pwd": ""},
    {"name": "pord-2", "ip": "",   "port": 22, "user": "dev", "pwd": ""},
    {"name": "pord-3", "ip": "", "port": 22, "user": "dev", "pwd": ""},
]

# ========== 4. 远端脚本路径 ==========
REMOTE_SCRIPT = "/etc/zabbix/scripts/discover_java_services.sh"

# ---------- 工具函数（无改动）----------
def zabbix_login() -> str:
    payload = {
        "jsonrpc": "2.0", "method": "user.login",
        "params": {"user": ZABBIX_USER, "password": ZABBIX_PASSWORD}, "id": 1
    }
    r = requests.post(ZABBIX_URL, json=payload, timeout=10)
    r.raise_for_status()
    result = r.json().get("result")
    if not result:
        raise RuntimeError(f"Zabbix 登录失败：{r.text}")
    return result


def get_hostid(auth: str, hostname: str) -> str:
    payload = {
        "jsonrpc": "2.0", "method": "host.get",
        "params": {"filter": {"host": [hostname]}}, "auth": auth, "id": 2
    }
    r = requests.post(ZABBIX_URL, json=payload, timeout=10)
    data = r.json().get("result", [])
    return data[0]["hostid"] if data else None


def get_discovered_items(auth: str, hostid: str, key_prefix: str):
    payload = {
        "jsonrpc": "2.0", "method": "item.get",
        "params": {
            "hostids": hostid,
            "output": ["name", "key_", "lastvalue"],
            "search": {"key_": key_prefix},
            "sortfield": "name"
        },
        "auth": auth, "id": 3
    }
    r = requests.post(ZABBIX_URL, json=payload, timeout=10)
    return r.json().get("result", [])


def ssh_discover_jars(ip: str, port: int, user: str, pwd: str) -> List[str]:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(ip, port=port, username=user, password=pwd, timeout=10)
        stdin, stdout, stderr = client.exec_command(f"bash {REMOTE_SCRIPT}", timeout=15)
        out = stdout.read().decode()
        err = stderr.read().decode()
        if err:
            raise RuntimeError(err)
        if not out.strip():
            return []
        lld = json.loads(out)
        return [item["{#JAR_NAME}"] for item in lld.get("data", [])]
    finally:
        client.close()


def send_ding(md_text: str):
    """
    使用 Markdown 消息类型发送钉钉消息，确保表格渲染正常。
    """
    ts = str(round(time.time() * 1000))
    string_for_sign = f"{ts}\n{DING_SECRET}"
    mac = base64.b64encode(
        hmac.new(DING_SECRET.encode(), string_for_sign.encode(), hashlib.sha256).digest()
    ).decode()
    sign = urllib.parse.quote_plus(mac)

    url = (f"https://oapi.dingtalk.com/robot/send"
           f"?access_token={DING_ACCESS}"
           f"&timestamp={ts}"
           f"&sign={sign}")

    data = {
        "msgtype": "markdown",
        "markdown": {
            "title": "Zabbix JAR 服务监控日报",
            "text": md_text
        }
    }

    r = requests.post(url, json=data, timeout=10)
    if r.json().get("errcode") == 0:
        print("✅ 推送成功 (Markdown)")
    else:
        print("❌ 推送失败 (Markdown)：", r.text)

# ---------- 主流程（修正内存单位为 MB，优化渲染） ----------
def main():
    auth = zabbix_login()
    report_lines = [
        f"# 🧩 Zabbix JAR 服务监控日报",
        f"**⏰ 汇总时间：{dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}**\n"
    ]

    for h in HOSTS:
        report_lines.append("") # 添加一个空行作为段落分隔
        report_lines.append(f"### 🖥️ {h['name']}")
        
        try:
            jars = ssh_discover_jars(h["ip"], h["port"], h["user"], h["pwd"])
        except Exception as e:
            # 错误信息使用引用块突出显示
            report_lines.append(f"> ❌ 获取 jar 列表失败：{e}\n")
            continue
        
        if not jars:
            report_lines.append("> **未扫描到任何 jar 包**\n")
            continue

        # 取主机 ID
        hostid = get_hostid(auth, h["name"])
        if not hostid:
            report_lines.append("> ❌ **Zabbix 中找不到该主机**\n")
            continue

        # Markdown 表格构建
        md_table = [
            "| **JAR 包** | **CPU 使用率** | **内存占用** |",
            "| :--- | :---: | :---: |" # 表格对齐设置，数据居中对齐
        ]
        
        # 绿色用于突出正常数据
        NORMAL_COLOR = "#4caf50" 

        for jar in jars:
            cpu_key = f"jar.cpu.usage[{jar}]"
            mem_key = f"jar.mem.rss[{jar}]"

            cpu_val, mem_val = "N/A", "N/A"
            
            # 1. CPU 获取
            items = get_discovered_items(auth, hostid, cpu_key)
            if items and items[0]["lastvalue"]:
                cpu_raw_value = float(items[0]['lastvalue'])
                cpu_val = f"{cpu_raw_value:.2f}%" 
            
            # 2. 内存获取和修正
            items = get_discovered_items(auth, hostid, mem_key)
            if items and items[0]["lastvalue"]:
                try:
                    raw_mem_value = float(items[0]["lastvalue"])
                    
                    # ** 核心修正：假设 Zabbix 返回的值已经是 MB，无需进行任何转换。
                    mem_mb = raw_mem_value
                    
                    # 格式化为两位小数
                    mem_val = f"{mem_mb:.2f} MB"
                except ValueError:
                    mem_val = "Error"

            # 优化表格内容的颜色和粗体
            cpu_display = f"**<font color={NORMAL_COLOR}>{cpu_val}</font>**" 
            mem_display = f"**<font color={NORMAL_COLOR}>{mem_val}</font>**"

            md_table.append(
                f"| {jar} | {cpu_display} | {mem_display} |"
            )
            
        report_lines.extend(md_table)
        report_lines.append("---") # 主机报告之间的分隔线，使用 Markdown 分隔符

    report_lines.append("") # 报告结尾空行
    report_lines.append(f"---")
    report_lines.append(f"**[点击查看 Zabbix 监控系统](http://47.94.143.98:8088/zabbix/)**")


    # 使用单换行符 '\n' 来连接行，保证 Markdown 表格结构紧凑，提高钉钉渲染成功率
    send_ding("\n".join(report_lines))

if __name__ == "__main__":
    main()