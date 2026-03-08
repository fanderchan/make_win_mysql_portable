# MySQL Windows Portable Packager

把官方 MySQL Windows ZIP 包裁剪成便携目录和分发压缩包，并补齐初始化、启动、停止、连接、备份、恢复脚本。

项目名为 `make_win_mysql_portable`，当前实现已经按版本家族处理，不再只限定在 8.0。

## 支持范围

当前脚本识别以下官方 ZIP 命名：

- `mysql-8.0.x-winx64.zip`
- `mysql-8.4.x-winx64.zip`
- `mysql-9.x.x-winx64.zip`

当前不支持：

- MSI 安装包
- `*-debug-test.zip`
- 非 `winx64` 的压缩包

建议每次只在仓库根目录放一个待处理 ZIP，脚本会处理找到的第一个匹配文件。

## 这个项目实际会做什么

运行 `create_mysql_portable.bat` 后，脚本会：

1. 自动识别根目录下的官方 MySQL ZIP 包
2. 解压到 `output\\mysql-<version>-portable\\`
3. 删除 `.pdb`、`*-debug.dll`、`*_debug.dll`、`.lib`、`.pl`、`docs`、`include`
4. 创建 `data`、`logs`、`tmp`
5. 拷贝 `files\\init_mysql` 和包内 `README.md`
6. 输出 `output\\mysql-<version>-portable.zip`
7. 可选下载 `vc_redist.x64.exe`

脚本不会自动初始化数据库。初始化发生在你解压生成包后运行 `init_mysql\\init_mysql.bat` 时。

## 环境要求

- Windows x64
- PowerShell（脚本使用 `Expand-Archive` 和 `Compress-Archive`）
- 官方 MySQL Community Server Windows ZIP 包
- 首次注册 / 启动服务时需要管理员权限
- 如果目标机器没有安装 VC 运行库，需要安装 `vc_redist.x64.exe`

## 快速开始

### 1. 打包

1. 把一个官方 MySQL ZIP 包放到仓库根目录，与 `create_mysql_portable.bat` 同级
2. 运行 `create_mysql_portable.bat`
3. 在 `output\\` 目录获得：
   - `mysql-<version>-portable\\`
   - `mysql-<version>-portable.zip`

### 2. 使用生成的便携包

1. 解压 `mysql-<version>-portable.zip`
2. 运行 `init_mysql\\init_mysql.bat`
3. 输入端口，直接回车默认 `3306`
4. 运行 `start_mysql.bat`
5. 运行 `scripts\\connect.bat` 或使用 `bin\\mysql.exe -u root -P<port>` 连接
6. 需要停止时运行 `stop_mysql.bat`

## 初始化后的实际行为

- `init_mysql\\init_mysql.bat` 只是一个 PowerShell 启动器，真正逻辑在 `init_mysql\\init_mysql.ps1`
- 初始化会生成根目录 `my.ini`
- 初始化命令是 `mysqld --initialize-insecure --console`
- `root` 账户初始无密码
- 服务名格式是 `MySQL<port>`
- 初始化时会生成：
  - `start_mysql.bat`
  - `stop_mysql.bat`
  - `scripts\\connect.bat`
  - `scripts\\backup_scripts\\backup.bat`
  - `scripts\\backup_scripts\\restore.bat`

首次登录后建议立即设置密码：

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password';
```

## 兼容性说明

为了兼容 MySQL 8.4 以及后续 9.x，这个仓库不再在默认模板里强行写入旧认证设置。

- `default_authentication_plugin` 已在 MySQL 8.4 移除
- `mysql_native_password` 在 MySQL 8.4 默认禁用，并在 MySQL 9.0 移除
- 因此当前模板跟随 MySQL 默认认证插件，避免 8.4/9.x 因配置项失效而启动失败

如果你的客户端非常老，只支持 `mysql_native_password`，需要你自行评估连接器升级方案。8.4 还能手动启用该插件，但 9.0 起已经不再提供。

## 项目限制和注意事项

- `start_mysql.bat` / `stop_mysql.bat` 依赖 Windows 服务，不属于完全“零侵入”
- 初始化脚本会在本机创建或删除 Windows 服务 `MySQL<port>`
- 当前脚本只覆盖单机便携实例场景，没有做升级迁移或多节点复制编排
- 如果你想修改默认 `my.ini`，优先编辑 `files\\init_mysql\\templates\\my.ini.template` 后重新打包
- 如果要重新初始化同一个便携目录，先确认原有 `data` 是否需要备份

## 仓库结构

- `create_mysql_portable.bat`
  打包入口，负责识别 ZIP、裁剪文件、复制模板并生成最终压缩包。
- `files\\init_mysql\\`
  初始化脚本和模板目录，会原样复制到生成包。
- `files\\README.md`
  生成包内附带的使用说明。
- `简介 (1).docx`
  旧文档来源，当前 README 已按仓库真实实现重新整理。

## 参考

- [MySQL 8.4 Release Notes: `default_authentication_plugin` removed](https://dev.mysql.com/doc/relnotes/mysql/8.4/en/news-8-4-0.html)
- [MySQL 8.4 Reference Manual: `mysql_native_password` disabled by default in 8.4 and removed in 9.0](https://dev.mysql.com/doc/refman/8.4/en/native-pluggable-authentication.html)
- [MySQL 9.0 Release Notes: `mysql_native_password` removed](https://dev.mysql.com/doc/relnotes/mysql/9.0/en/news-9-0-0.html)
- [MySQL 8.4 Reference Manual: Windows ZIP archive naming](https://dev.mysql.com/doc/refman/8.4/en/windows-choosing-package.html)
