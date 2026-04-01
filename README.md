English | [简体中文](README.zh-CN.md)

# MySQL Windows Portable Packager

Turn the official MySQL Windows ZIP archive into a portable directory plus a redistributed ZIP package, with helper scripts for initialization, startup, shutdown, connection, backup, and restore.

The project name is `make_win_mysql_portable`. The current implementation already handles different version families and is no longer limited to MySQL 8.0 only.

## Download Examples

If you are not sure where to download `mysql-8.0.x-winx64.zip`, `mysql-8.4.x-winx64.zip`, or `mysql-9.x.x-winx64.zip`, start from the official pages below.

- MySQL 8.0 download page: [MySQL Community Server 8.0](https://dev.mysql.com/downloads/mysql/8.0.html)
- MySQL 8.4 LTS download page: [MySQL Community Server 8.4](https://dev.mysql.com/downloads/mysql/8.4.html)
- Direct ZIP example for 8.0: [`mysql-8.0.45-winx64.zip`](https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.45-winx64.zip)
- Direct ZIP example for 8.4 LTS: [`mysql-8.4.8-winx64.zip`](https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-8.4.8-winx64.zip)
- As of `2026-04-02`, the official Community Server download page lists `9.6.0 Innovation` as the current public 9.x Windows ZIP release.
- The script also recognizes preview snapshot packages such as `mysql-9.x.x-er-winx64.zip`.

## Supported Input Packages

The script currently recognizes these official ZIP naming patterns:

- `mysql-8.0.x-winx64.zip`
- `mysql-8.4.x-winx64.zip`
- `mysql-9.x.x-winx64.zip`
- `mysql-9.x.x-er-winx64.zip`

Not supported:

- MSI installers
- `*-debug-test.zip`
- Anything other than `winx64`

It is recommended to keep only one target ZIP archive in the repository root at a time. The script processes the first matching file it finds.

## Parameter Notes

The parameter details were moved out of the main README into a separate document:

- [MySQL parameter reference and default value comparison (Simplified Chinese)](docs/mysql-default-parameters.md)

That document currently includes:

- The script parameters exposed by `init_mysql\init_mysql.ps1`
- The template values written into `my.ini.template`
- Default-value comparisons for MySQL `8.0`, `8.4`, and `9.7.0 ER`
- A short explanation for each parameter

## What This Project Does

After you run `create_mysql_portable.bat`, the script:

1. Detects the official MySQL ZIP archive in the repository root
2. Extracts it into `output\\mysql-<package-label>-portable\\`
3. Removes `.pdb`, `*-debug.dll`, `*_debug.dll`, `.lib`, `.pl`, `docs`, and `include`
4. Creates `data`, `logs`, and `tmp`
5. Copies `files\\init_mysql` and the packaged `README.md`
6. Produces `output\\mysql-<package-label>-portable.zip`
7. Optionally downloads `vc_redist.x64.exe`

Examples:

- A GA ZIP such as `mysql-9.6.0-winx64.zip` becomes `mysql-9.6.0-portable.zip`
- An ER ZIP such as `mysql-9.7.0-er-winx64.zip` becomes `mysql-9.7.0-er-portable.zip`

The script does not initialize the database automatically. Initialization happens after you extract the generated package and run `init_mysql\\init_mysql.bat`.

## Requirements

- Windows x64
- PowerShell (the script uses `Expand-Archive` and `Compress-Archive`)
- An official MySQL Community Server Windows ZIP package
- Administrator privileges when registering or starting the Windows service for the first time
- `vc_redist.x64.exe` on the target machine if the Visual C++ runtime is not already installed

## Quick Start

### 1. Build the portable package

1. Put one official MySQL ZIP package in the repository root, next to `create_mysql_portable.bat`
2. Run `create_mysql_portable.bat`
3. Retrieve the generated artifacts from `output\\`:
   - `mysql-<package-label>-portable\\`
   - `mysql-<package-label>-portable.zip`

### 2. Use the generated portable package

1. Extract `mysql-<package-label>-portable.zip`
2. Run `init_mysql\\init_mysql.bat`
3. Enter the port, or press Enter to use the default `3306`
4. Run `start_mysql.bat`
5. Run `scripts\\connect.bat`, or connect with `bin\\mysql.exe -u root -P<port>`
6. Run `stop_mysql.bat` when you want to stop the instance

## What Happens During Initialization

- `init_mysql\\init_mysql.bat` is only a PowerShell launcher; the real logic is in `init_mysql\\init_mysql.ps1`
- Initialization creates `my.ini` in the package root
- The initialization command is `mysqld --initialize-insecure --console`
- The `root` account starts with no password
- The Windows service name format is `MySQL<port>`
- Initialization generates:
  - `start_mysql.bat`
  - `stop_mysql.bat`
  - `scripts\\connect.bat`
  - `scripts\\backup_scripts\\backup.bat`
  - `scripts\\backup_scripts\\restore.bat`
- `scripts\\backup_scripts\\backup.bat` creates both a full backup and per-database dumps by default, so you can restore either the whole instance or a single database

Set a password immediately after the first login:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password';
```

## Compatibility Notes

To stay compatible with MySQL 8.4 and later 9.x releases, this repository no longer forces legacy authentication settings into the default template.

- `default_authentication_plugin` was removed in MySQL 8.4
- `mysql_native_password` is disabled by default in MySQL 8.4 and removed in MySQL 9.0
- The current template therefore follows MySQL's default authentication plugin to avoid startup failures caused by removed options in 8.4 and 9.x

If you still depend on a very old client that only supports `mysql_native_password`, you need to evaluate your connector upgrade path yourself. MySQL 8.4 can still enable that plugin manually, but MySQL 9.0 and later no longer provide it.

## Limitations and Notes

- `start_mysql.bat` and `stop_mysql.bat` depend on Windows services, so this is not a completely zero-footprint deployment
- The initialization script creates or removes a local Windows service named `MySQL<port>`
- The current workflow targets single-machine portable instances only; it does not handle in-place upgrades, migrations, or multi-node replication orchestration
- If you want to change the default `my.ini`, edit `files\\init_mysql\\templates\\my.ini.template` first and then rebuild the package
- If you want to re-initialize an existing portable directory, make sure you have backed up the original `data` directory first

## Repository Layout

- `create_mysql_portable.bat`
  Main packaging entry point. Detects the ZIP archive, trims files, copies templates, and builds the final ZIP package.
- `docs\\mysql-default-parameters.md`
  Detailed parameter notes and default-value comparisons.
- `files\\init_mysql\\`
  Initialization scripts and templates that are copied into the generated package as-is.
- `files\\README.md`
  Usage notes bundled inside the generated package. This file is currently written in Simplified Chinese.

## References

- [MySQL 8.4 Release Notes: `default_authentication_plugin` removed](https://dev.mysql.com/doc/relnotes/mysql/8.4/en/news-8-4-0.html)
- [MySQL 8.4 Reference Manual: `mysql_native_password` disabled by default in 8.4 and removed in 9.0](https://dev.mysql.com/doc/refman/8.4/en/native-pluggable-authentication.html)
- [MySQL 9.0 Release Notes: `mysql_native_password` removed](https://dev.mysql.com/doc/relnotes/mysql/9.0/en/news-9-0-0.html)
- [MySQL 8.4 Reference Manual: Windows ZIP archive naming](https://dev.mysql.com/doc/refman/8.4/en/windows-choosing-package.html)
