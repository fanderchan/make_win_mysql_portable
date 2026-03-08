# MySQL 便携包使用说明

这个目录由仓库脚本基于官方 MySQL Windows ZIP 包生成，适合解压后直接初始化和运行。

## 首次使用

1. 运行 `init_mysql\init_mysql.bat`
2. 输入端口，直接回车默认使用 `3306`
3. 脚本会创建 `data`、`logs`、`tmp`，生成 `my.ini`、`start_mysql.bat`、`stop_mysql.bat` 和 `scripts\` 下的辅助脚本
4. 初始化方式是 `mysqld --initialize-insecure`，因此 `root` 初始无密码

首次登录后请尽快设置密码：

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password';
```

## 启动和停止

- `start_mysql.bat`
  需要管理员权限。首次运行会注册 Windows 服务 `MySQL<port>`，之后通过该服务启动实例。
- `stop_mysql.bat`
  停止 MySQL 服务，并可按提示决定是否移除服务。

## 常用脚本

- `scripts\connect.bat`
  使用当前端口直接连接本机 MySQL。
- `scripts\backup_scripts\backup.bat`
  备份当前实例全部数据库，输出到 `scripts\backup_scripts\backup\日期\`。
- `scripts\backup_scripts\restore.bat`
  把 `.sql` 文件拖到脚本上即可恢复。

## 配置说明

- 运行时配置文件是根目录的 `my.ini`
- 初始化模板位于 `init_mysql\templates\my.ini.template`
- 如果需要修改端口或路径，建议调整模板后重新初始化，而不是直接复用旧数据目录

## 依赖

- 机器需要安装 Visual C++ Redistributable
- 如果提示缺少 `vcruntime140.dll`，请先安装同目录下的 `vc_redist.x64.exe`（如果随包附带）或自行下载安装

## 注意事项

- 同一台机器可以通过不同端口部署多套实例，服务名格式为 `MySQL<port>`
- `start_mysql.bat` 和 `stop_mysql.bat` 都依赖 Windows 服务机制，因此需要管理员权限
- 备份、恢复和连接脚本默认使用 `root` 账户，执行时会按当前账号状态要求输入密码
