# MySQL 参数说明与默认值对照

这个文档补充两部分内容：

- `init_mysql\init_mysql.ps1` 的脚本参数
- `files\init_mysql\templates\my.ini.template` 里已经写入的参数，以及它们在 MySQL `8.0`、`8.4`、`9.7` 下的默认值

## 说明

- `8.0 默认值` 按官方 Windows ZIP `mysql-8.0.45-winx64.zip`
- `8.4 默认值` 按官方 Windows ZIP `mysql-8.4.8-winx64.zip`
- `9.7 默认值` 按 `mysql-9.7.0-er-winx64.zip`
- 截至 `2026-03-25`，`9.7` 还是 ER 快照，不是 GA 版
- 默认值通过官方包自带的 `mysql.exe --no-defaults --help` 和 `mysqld.exe --no-defaults --verbose --help` 实测
- 路径类默认值做了归一化处理：
  - `basedir` 表示 MySQL 解压后的安装目录
  - `datadir` 表示数据目录
  - `%TEMP%` 表示 Windows 当前用户临时目录
  - `<hostname>` 表示当前主机名
- `open_files_limit`、`thread_cache_size` 这类值会受平台或其他参数影响，下表写的是官方 Windows ZIP 在默认条件下的实测值

## 初始化脚本参数

`init_mysql\init_mysql.bat` 本质上只是转调 `init_mysql\init_mysql.ps1`。当前真正对外暴露的脚本参数只有一个：

| 参数名 | 默认值 | 参数解释 |
| --- | --- | --- |
| `Port` | `3306` | 初始化时使用的 MySQL 监听端口。不传时会交互提示；直接回车则使用 `3306`。这个值会同时写入 `my.ini`、服务名 `MySQL<port>`、`start_mysql.bat`、`stop_mysql.bat`、`scripts\connect.bat` 等生成脚本。 |

## 路径与基础参数

| 参数名 | 本项目模板值 | 8.0 默认值 | 8.4 默认值 | 9.7 默认值 | 参数解释 |
| --- | --- | --- | --- | --- | --- |
| `default-character-set` | `utf8mb4` | `auto` | `auto` | `auto` | `mysql.exe` 客户端的默认字符集。`auto` 表示客户端按连接环境自动决定。 |
| `port` | `{port}` | `3306` | `3306` | `3306` | MySQL TCP 监听端口。这里的 `{port}` 会在初始化时替换成你输入的端口。 |
| `basedir` | `{basedir}` | `basedir` | `basedir` | `basedir` | MySQL 安装根目录。初始化脚本会把它替换成当前便携包实际所在目录。 |
| `datadir` | `{basedir}\data` | `basedir\data` | `basedir\data` | `basedir\data` | 数据目录，库文件和系统表都会放这里。 |
| `tmpdir` | `{basedir}\tmp` | `%TEMP%` | `%TEMP%` | `%TEMP%` | 临时文件目录。项目里显式改成了便携包内的 `tmp` 目录，避免占用系统临时目录。 |
| `pid_file` | `{basedir}\mysql.pid` | `datadir\<hostname>.pid` | `datadir\<hostname>.pid` | `datadir\<hostname>.pid` | MySQL 进程 PID 文件路径。 |
| `plugin_dir` | `{basedir}\lib\plugin` | `basedir\lib\plugin` | `basedir\lib\plugin` | `basedir\lib\plugin` | 插件目录，MySQL 会从这里加载插件。 |

## 字符集、连接与常规行为

| 参数名 | 本项目模板值 | 8.0 默认值 | 8.4 默认值 | 9.7 默认值 | 参数解释 |
| --- | --- | --- | --- | --- | --- |
| `character_set_server` | `utf8mb4` | `utf8mb4` | `utf8mb4` | `utf8mb4` | 服务端默认字符集。新建库和表如果没有单独指定，通常会继承它。 |
| `collation_server` | `utf8mb4_0900_ai_ci` | `utf8mb4_0900_ai_ci` | `utf8mb4_0900_ai_ci` | `utf8mb4_0900_ai_ci` | 服务端默认排序规则。决定字符串比较和排序方式。 |
| `max_connections` | `500` | `151` | `151` | `151` | 允许同时连接的客户端数量上限。 |
| `max_connect_errors` | `1000` | `100` | `100` | `100` | 同一主机连续连接出错达到上限后会被阻断。 |
| `connect_timeout` | `10` | `10` | `10` | `10` | 等待客户端完成握手的超时时间，单位秒。 |
| `wait_timeout` | `28800` | `28800` | `28800` | `28800` | 非交互连接空闲多久后断开，单位秒。 |
| `back_log` | `128` | `151` | `151` | `10000` | TCP 监听队列长度。连接突增时，过小会更容易出现拒绝连接。 |
| `thread_cache_size` | `16` | `9` | `9` | `9` | 线程缓存大小。线程复用可以减少频繁创建/销毁线程的开销。 |
| `table_open_cache` | `512` | `4000` | `4000` | `4000` | 表缓存数量。值越大，可减少频繁打开表文件的开销。 |
| `read_only` | `OFF` | `OFF` | `OFF` | `OFF` | 是否将实例置为只读。便携单实例场景通常应保持可写。 |
| `event_scheduler` | `ON` | `ON` | `ON` | `ON` | 是否启用事件调度器。启用后可执行 `EVENT` 定时任务。 |
| `skip_name_resolve` | `OFF` | `OFF` | `OFF` | `OFF` | 是否跳过主机名反查。关闭时允许按主机名授权，开启后只能按 IP。 |
| `lower_case_table_names` | `1` | `1` | `1` | `1` | Windows 下表名大小写规则。`1` 表示表名按小写存储、比较时不区分大小写。 |
| `local_infile` | `0` | `OFF` | `OFF` | `OFF` | 是否允许 `LOAD DATA LOCAL INFILE`。关闭可以降低误导入本地文件的风险。 |
| `open_files_limit` | `65536` | `10209` | `10209` | `10209` | MySQL 可打开文件描述符上限。Windows 下这个值会受平台条件影响。 |

## 日志相关参数

| 参数名 | 本项目模板值 | 8.0 默认值 | 8.4 默认值 | 9.7 默认值 | 参数解释 |
| --- | --- | --- | --- | --- | --- |
| `log_error` | `{basedir}\logs\mysql_error.log` | `stderr` | `stderr` | `stderr` | 错误日志输出位置。项目里显式写入文件，便于排查启动失败或崩溃问题。 |
| `slow_query_log` | `ON` | `OFF` | `OFF` | `OFF` | 是否开启慢查询日志。 |
| `slow_query_log_file` | `{basedir}\logs\slow.log` | `datadir\<hostname>-slow.log` | `datadir\<hostname>-slow.log` | `datadir\<hostname>-slow.log` | 慢查询日志文件路径。 |
| `long_query_time` | `2` | `10` | `10` | `10` | 超过多少秒的 SQL 记为慢查询。 |
| `log_timestamps` | `system` | `UTC` | `UTC` | `UTC` | 日志里时间戳使用的时区。项目里改成了系统时区，方便直接看本地时间。 |
| `general_log` | `OFF` | `OFF` | `OFF` | `OFF` | 是否记录所有 SQL。默认关闭可以减少 I/O 压力。 |

## 复制、GTID 与二进制日志

| 参数名 | 本项目模板值 | 8.0 默认值 | 8.4 默认值 | 9.7 默认值 | 参数解释 |
| --- | --- | --- | --- | --- | --- |
| `log_bin` | `mysql-bin` | `binlog` | `binlog` | `binlog` | 二进制日志基础名。开启后可用于恢复和复制。项目里改成更直观的 `mysql-bin`。 |
| `sync_binlog` | `1` | `1` | `1` | `1` | 每次事务提交都把 binlog 刷盘，可靠性最高，但 I/O 开销也更大。 |
| `log_bin_trust_function_creators` | `ON` | `OFF` | `OFF` | `OFF` | 是否放宽存储函数创建限制。开启后非 `SUPER` 用户也更容易创建函数。 |
| `binlog_rows_query_log_events` | `ON` | `OFF` | `OFF` | `OFF` | 行格式 binlog 中是否附带原始 SQL 文本，便于排查。 |
| `binlog_expire_logs_seconds` | `604800` | `2592000` | `2592000` | `2592000` | binlog 自动过期时间，单位秒。项目里改成 7 天，官方默认约 30 天。 |
| `gtid_mode` | `OFF` | `OFF` | `OFF` | `ON` | 是否启用 GTID。项目是单机便携包，默认显式关掉。 |
| `enforce_gtid_consistency` | `OFF` | `OFF` | `OFF` | `ON` | 是否强制 GTID 兼容写法。启用 GTID 时通常需要一起开启。 |
| `skip_replica_start` | `1` | `OFF` | `OFF` | `OFF` | 启动实例时是否自动启动复制线程。单机便携包里显式禁用，避免误连复制链路。 |

## InnoDB 与存储引擎

| 参数名 | 本项目模板值 | 8.0 默认值 | 8.4 默认值 | 9.7 默认值 | 参数解释 |
| --- | --- | --- | --- | --- | --- |
| `default_storage_engine` | `InnoDB` | `InnoDB` | `InnoDB` | `InnoDB` | 默认存储引擎。 |
| `innodb_buffer_pool_size` | `128M` | `134217728` | `134217728` | `134217728` | InnoDB Buffer Pool 大小。`134217728` 就是 `128M`。 |
| `innodb_flush_log_at_trx_commit` | `1` | `1` | `1` | `1` | 事务提交时 redo log 的刷盘策略。`1` 最安全。 |
| `innodb_file_per_table` | `ON` | `ON` | `ON` | `ON` | 每张表单独使用一个 `.ibd` 文件，便于管理和回收空间。 |
| `innodb_buffer_pool_instances` | `8` | `0` | `0` | `0` | Buffer Pool 实例数量。官方 `0` 表示自动决定；项目里固定成 `8`。 |
| `innodb_strict_mode` | `1` | `ON` | `ON` | `ON` | 是否启用 InnoDB 严格模式。开启后无效配置会直接报错。 |
| `innodb_print_all_deadlocks` | `1` | `OFF` | `OFF` | `OFF` | 是否把所有死锁都写入错误日志，便于定位问题。 |
| `innodb_lock_wait_timeout` | `50` | `50` | `50` | `50` | 行锁等待超时时间，单位秒。 |
| `innodb_autoinc_lock_mode` | `2` | `2` | `2` | `2` | 自增锁模式。`2` 是并发性能更好的 interleaved 模式。 |

## SQL 模式

| 参数名 | 本项目模板值 | 8.0 默认值 | 8.4 默认值 | 9.7 默认值 | 参数解释 |
| --- | --- | --- | --- | --- | --- |
| `sql_mode` | `STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION` | `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION` | `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION` | `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION` | SQL 行为开关集合。项目里去掉了 `ONLY_FULL_GROUP_BY`，减少旧 SQL 在便携环境里直接报错的概率。 |

## 看表时建议关注的几项差异

- `9.7` 的 `gtid_mode` 和 `enforce_gtid_consistency` 默认已经是 `ON`，而这个项目为了单机便携场景显式改成了 `OFF`
- `9.7` 的 `back_log` 默认值已经明显高于 `8.0` / `8.4`
- 项目显式把日志路径、临时目录、PID 文件都收口到便携包目录里，避免依赖系统默认路径
- 项目显式开启了慢查询日志，并把 `long_query_time` 从官方默认的 `10` 秒压到 `2` 秒
