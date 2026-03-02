🚀 项目简介
本项目是我在实际生产环境（Debian）中沉淀的一套运维工具脚本，解决多版本开发环境冲突以及前端自动化部署稳定性问题。重点实现了基于软链接的版本隔离机制和具备自校验功能的部署流程。
前端项目Node.js 多版本平滑切换方案start-frontend_build.sh
后端项目健壮型自动化部署脚本 start-backend.sh
Jenkins自动化构建后端service微服务的jenkinsfile 
💻 技术栈
OS: Debian 

Scripting: Bash Shell

Web: Nginx / OpenResty

Tools: 1Panel, Docker, Node.js Ecosystem
生产服务器磁盘空间有限，需定期将上月旧日志归档至阿里云 OSS/
cp_logs.sh
技术实现：
挂载集成：利用 ossfs 将云端存储桶挂载至本地文件系统。
增量拷贝：使用 cp -r 结合日期筛选，将上月日志（如 2026-02-*）平滑迁移至挂载点。
安全卸载/清理：迁移脚本执行完毕并校验 $? 后，触发 rm_logs.sh 清理本地陈旧日志，释放磁盘空间。
运维亮点：防止日志撑爆根分区，确保业务连续性。
