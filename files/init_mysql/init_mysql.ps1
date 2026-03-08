param(
    [string]$Port
)

# Check VC Redistributable dependency
$vcDll = Join-Path $env:windir 'System32\vcruntime140.dll'
if (-not (Test-Path $vcDll)) {
    Write-Host "[ERROR] Visual C++ Redistributable (vcruntime140.dll) is not installed!" -ForegroundColor Red
    Write-Host "Please download and install it from: https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Yellow
    pause
    exit 1
}

# Set default port
if (-not $Port) {
    $Port = Read-Host "Please enter MySQL port (press Enter for default 3306)"
    if ([string]::IsNullOrWhiteSpace($Port)) {
        $Port = "3306"
    }
}

# Get the current script directory (init_mysql)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set base directory to parent of init_mysql directory (MySQL root)
$BaseDir = Split-Path -Parent $ScriptDir

# Create necessary directories
Write-Host "[INFO] Creating data, logs, and tmp directories..."
New-Item -ItemType Directory -Force -Path "$BaseDir\data" | Out-Null
New-Item -ItemType Directory -Force -Path "$BaseDir\logs" | Out-Null
New-Item -ItemType Directory -Force -Path "$BaseDir\tmp" | Out-Null

# Generate my.ini from template
Write-Host "[INFO] Generating my.ini configuration file..."
$TemplateDir = Join-Path $ScriptDir "templates"
$TemplateFile = Join-Path $TemplateDir "my.ini.template"

if (-not (Test-Path $TemplateFile)) {
    Write-Host "[ERROR] Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

(Get-Content $TemplateFile) | ForEach-Object {
    $_ -replace "{port}", $Port -replace "{basedir}", $BaseDir.Replace("\", "\\")
} | Set-Content "$BaseDir\my.ini"

# Check if service is already installed
$serviceName = "MySQL$Port"
$serviceExists = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($serviceExists) {
    Write-Host "[WARNING] MySQL service '$serviceName' already exists. We need to remove it before initialization."
    Write-Host "[INFO] Stopping and removing existing service..."
    
    try {
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $process = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
        if ($process) {
            $process.Delete() | Out-Null
        }
        Write-Host "[INFO] Existing service removed successfully."
    } catch {
        Write-Host "[WARNING] Could not fully remove the service. You might need to restart your computer before reinstalling."
    }
}

# Initialize data directory
Write-Host "[INFO] Initializing MySQL data directory..."
Write-Host "[INFO] This creates a root user without password for local access only"
& "$BaseDir\bin\mysqld.exe" --defaults-file="$BaseDir\my.ini" --initialize-insecure --console

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] MySQL initialization failed!" -ForegroundColor Red
    exit 1
}

# Ensure log file directory permissions
Write-Host "[INFO] Setting up log directory permissions..."
$acl = Get-Acl "$BaseDir\logs"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl "$BaseDir\logs" $acl

# Create start and stop scripts from templates
Write-Host "[INFO] Creating MySQL scripts..."
$StartTemplate = Join-Path $TemplateDir "start_mysql.bat.template"
$StopTemplate = Join-Path $TemplateDir "stop_mysql.bat.template"

# Generate start_mysql.bat
if (Test-Path $StartTemplate) {
    (Get-Content $StartTemplate) | ForEach-Object {
        $_ -replace "{port}", $Port
    } | Set-Content "$BaseDir\start_mysql.bat"
    Write-Host "[INFO] Created start_mysql.bat"
} else {
    Write-Host "[WARNING] Start script template not found: $StartTemplate"
}

# Generate stop_mysql.bat
if (Test-Path $StopTemplate) {
    (Get-Content $StopTemplate) | ForEach-Object {
        $_ -replace "{port}", $Port
    } | Set-Content "$BaseDir\stop_mysql.bat"
    Write-Host "[INFO] Created stop_mysql.bat"
} else {
    Write-Host "[WARNING] Stop script template not found: $StopTemplate"
}

# Create scripts directory structure
Write-Host "[INFO] Creating scripts directory structure..."
$ScriptsTemplateDir = Join-Path $TemplateDir "scripts"
$ScriptsDestDir = Join-Path $BaseDir "scripts"
$BackupScriptsTemplateDir = Join-Path $ScriptsTemplateDir "backup_scripts"
$BackupScriptsDestDir = Join-Path $ScriptsDestDir "backup_scripts"

# Create directories if they don't exist
if (-not (Test-Path $ScriptsDestDir)) {
    New-Item -ItemType Directory -Force -Path $ScriptsDestDir | Out-Null
}
if (-not (Test-Path $BackupScriptsDestDir)) {
    New-Item -ItemType Directory -Force -Path $BackupScriptsDestDir | Out-Null
}
# Create backup directory
New-Item -ItemType Directory -Force -Path "$BackupScriptsDestDir\backup" | Out-Null

# Generate connect.bat
$ConnectTemplate = Join-Path $ScriptsTemplateDir "connect.bat.template"
if (Test-Path $ConnectTemplate) {
    (Get-Content $ConnectTemplate) | ForEach-Object {
        $_ -replace "{port}", $Port
    } | Set-Content "$ScriptsDestDir\connect.bat"
    Write-Host "[INFO] Created scripts\connect.bat"
} else {
    Write-Host "[WARNING] Connect script template not found: $ConnectTemplate"
}

# Generate backup.bat
$BackupTemplate = Join-Path $BackupScriptsTemplateDir "backup.bat.template"
if (Test-Path $BackupTemplate) {
    (Get-Content $BackupTemplate) | ForEach-Object {
        $_ -replace "{port}", $Port
    } | Set-Content "$BackupScriptsDestDir\backup.bat"
    Write-Host "[INFO] Created scripts\backup_scripts\backup.bat"
} else {
    Write-Host "[WARNING] Backup script template not found: $BackupTemplate"
}

# Generate restore.bat
$RestoreTemplate = Join-Path $BackupScriptsTemplateDir "restore.bat.template"
if (Test-Path $RestoreTemplate) {
    (Get-Content $RestoreTemplate) | ForEach-Object {
        $_ -replace "{port}", $Port
    } | Set-Content "$BackupScriptsDestDir\restore.bat"
    Write-Host "[INFO] Created scripts\backup_scripts\restore.bat"
} else {
    Write-Host "[WARNING] Restore script template not found: $RestoreTemplate"
}

Write-Host "[SUCCESS] MySQL initialization completed successfully!" -ForegroundColor Green
Write-Host "You can now start MySQL server using:"
Write-Host "  start_mysql.bat"
Write-Host "Then connect to it using:"
Write-Host "  bin\mysql.exe -u root"
Write-Host ""
Write-Host "IMPORTANT: For security, set a root password after first login:"
Write-Host "  ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password';"