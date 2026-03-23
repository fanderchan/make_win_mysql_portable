@echo off
setlocal enabledelayedexpansion

rem ===================================================
rem MySQL Portable Creator - Automated Trimming Tool
rem ===================================================

title MySQL Portable Creator

echo =====================================
echo      MySQL Portable Creator
echo =====================================
echo.

rem Set variables
set "SCRIPT_DIR=%~dp0"
set "OUTPUT_DIR=%SCRIPT_DIR%output"
set "FILES_DIR=%SCRIPT_DIR%files"
set "TEMP_DIR=%OUTPUT_DIR%\temp"
set "PACKAGE_CREATED=0"

rem Ensure output directory exists
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [INFO] Scanning for MySQL ZIP archive...

rem Auto-detect MySQL zip file
set "FOUND_ZIP="
set "MYSQL_VERSION="
set "MYSQL_PACKAGE_LABEL="
for %%z in (mysql-*-winx64.zip) do (
    set "MYSQL_VERSION="
    set "MYSQL_PACKAGE_LABEL="
    set "MYSQL_RELEASE_TAG="

    rem Supported filenames:
    rem   mysql-8.0.x-winx64.zip
    rem   mysql-8.4.x-winx64.zip
    rem   mysql-9.x.x-winx64.zip
    rem   mysql-9.x.x-er-winx64.zip
    for /f "tokens=1,2,3,4,5,6,7 delims=-." %%a in ("%%z") do (
        if /i "%%a"=="mysql" (
            if /i "%%e"=="winx64" (
                if "%%b"=="8" if "%%c"=="0" (
                    set "MYSQL_VERSION=%%b.%%c.%%d"
                    set "MYSQL_PACKAGE_LABEL=!MYSQL_VERSION!"
                )
                if "%%b"=="8" if "%%c"=="4" (
                    set "MYSQL_VERSION=%%b.%%c.%%d"
                    set "MYSQL_PACKAGE_LABEL=!MYSQL_VERSION!"
                )
                if "%%b"=="9" (
                    set "MYSQL_VERSION=%%b.%%c.%%d"
                    set "MYSQL_PACKAGE_LABEL=!MYSQL_VERSION!"
                )
            )
            if /i "%%e"=="er" if /i "%%f"=="winx64" (
                if "%%b"=="9" (
                    set "MYSQL_VERSION=%%b.%%c.%%d"
                    set "MYSQL_RELEASE_TAG=%%e"
                    set "MYSQL_PACKAGE_LABEL=!MYSQL_VERSION!-!MYSQL_RELEASE_TAG!"
                )
            )
        )
    )

    if defined MYSQL_PACKAGE_LABEL (
        set "FOUND_ZIP=%%z"
        echo [INFO] Found MySQL archive: %%z (Package: !MYSQL_PACKAGE_LABEL!, Base version: !MYSQL_VERSION!^)
        goto :PROCESS_FILE
    )
)

if not defined FOUND_ZIP (
    echo [ERROR] No compatible MySQL ZIP archive found.
    echo Supported naming patterns:
    echo   mysql-8.0.x-winx64.zip
    echo   mysql-8.4.x-winx64.zip
    echo   mysql-9.x.x-winx64.zip
    echo   mysql-9.x.x-er-winx64.zip
    echo Please place a compatible MySQL ZIP archive in the script directory and try again.
    goto :END
)

:PROCESS_FILE
set "MYSQL_ZIP=%SCRIPT_DIR%%FOUND_ZIP%"
set "TARGET_DIR=%OUTPUT_DIR%\mysql-%MYSQL_PACKAGE_LABEL%-portable"

echo [INFO] Creating target directory: %TARGET_DIR%
if exist "%TARGET_DIR%" rmdir /s /q "%TARGET_DIR%"
mkdir "%TARGET_DIR%"

echo.
echo [INFO] Extracting MySQL archive...
echo [INFO] This may take a few minutes, please be patient...

rem Extract directly to target directory
if exist "%TEMP_DIR%" (
    echo [INFO] Cleaning previous temporary extraction directory...
    rmdir /s /q "%TEMP_DIR%"
)

powershell -Command "Expand-Archive -Path '%MYSQL_ZIP%' -DestinationPath '%TEMP_DIR%' -Force"

rem Find extracted MySQL directory
set "MYSQL_EXTRACTED="
for /d %%i in ("%TEMP_DIR%\mysql*") do (
    set "MYSQL_EXTRACTED=%%i"
)

if not defined MYSQL_EXTRACTED (
    echo [ERROR] Could not find extracted MySQL directory!
    if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
    goto :END
)

echo [INFO] Successfully extracted MySQL to temporary directory: %MYSQL_EXTRACTED%

rem Move to target location
echo [INFO] Moving files to target directory...
xcopy "%MYSQL_EXTRACTED%\*" "%TARGET_DIR%\" /E /H /I /Y > nul

if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"

echo [INFO] Starting to trim unnecessary files...

rem Calculate initial size using PowerShell for better reliability
echo [INFO] Calculating initial size...
for /f "usebackq delims=" %%a in (`powershell -command "(Get-ChildItem -Recurse '%TARGET_DIR%' | Measure-Object -Property Length -Sum).Count"`) do (
    set "BEFORE_FILES=%%a"
)
for /f "usebackq delims=" %%a in (`powershell -command "[math]::Round((Get-ChildItem -Recurse '%TARGET_DIR%' | Measure-Object -Property Length -Sum).Sum / 1MB, 2)"`) do (
    set "BEFORE_SIZE_MB=%%a"
)
echo [INFO] Initial state: !BEFORE_FILES! files, !BEFORE_SIZE_MB! MB

rem ===== Start Trimming =====

rem Delete debug symbol files
echo [INFO] Removing debug symbol files (*.pdb)...
set "COUNT_PDB=0"
set "SIZE_PDB=0"
for /f "tokens=*" %%f in ('dir /s /b "%TARGET_DIR%\*.pdb" 2^>nul') do (
    set /a "COUNT_PDB+=1"
    for %%s in ("%%f") do set /a "SIZE_PDB+=%%~zs/1024"
    del /f /q "%%f"
)
echo [INFO] Removed !COUNT_PDB! PDB files, freed approximately !SIZE_PDB! KB

rem Delete debug DLLs
echo [INFO] Removing debug version DLLs...
set "COUNT_DEBUG_DLL=0"
set "SIZE_DEBUG_DLL=0"
for /f "tokens=*" %%f in ('dir /s /b "%TARGET_DIR%\*-debug.dll" "%TARGET_DIR%\*_debug.dll" 2^>nul') do (
    set /a "COUNT_DEBUG_DLL+=1"
    for %%s in ("%%f") do set /a "SIZE_DEBUG_DLL+=%%~zs/1024"
    del /f /q "%%f"
)
echo [INFO] Removed !COUNT_DEBUG_DLL! debug DLLs, freed approximately !SIZE_DEBUG_DLL! KB

rem Delete static library files
echo [INFO] Removing static library files (*.lib)...
set "COUNT_LIB=0"
set "SIZE_LIB=0"
for /f "tokens=*" %%f in ('dir /s /b "%TARGET_DIR%\*.lib" 2^>nul') do (
    set /a "COUNT_LIB+=1"
    for %%s in ("%%f") do set /a "SIZE_LIB+=%%~zs/1024"
    del /f /q "%%f"
)
echo [INFO] Removed !COUNT_LIB! LIB files, freed approximately !SIZE_LIB! KB

rem Delete Perl script files
echo [INFO] Removing Perl script files (*.pl)...
set "COUNT_PL=0"
set "SIZE_PL=0"
for /f "tokens=*" %%f in ('dir /s /b "%TARGET_DIR%\*.pl" 2^>nul') do (
    set /a "COUNT_PL+=1"
    for %%s in ("%%f") do set /a "SIZE_PL+=%%~zs/1024"
    del /f /q "%%f"
)
echo [INFO] Removed !COUNT_PL! PL script files, freed approximately !SIZE_PL! KB

rem Delete docs and header directories
echo [INFO] Removing documentation and header directories...
set "SIZE_DOCS=0"
if exist "%TARGET_DIR%\docs" (
    for /f "tokens=1,3" %%a in ('dir /s /a "%TARGET_DIR%\docs" ^| findstr /C:"File(s)"') do (
        set /a "SIZE_DOCS=%%b/1024"
    )
    rmdir /s /q "%TARGET_DIR%\docs"
    if !SIZE_DOCS! GTR 0 (
        echo [INFO] Removed docs directory, freed approximately !SIZE_DOCS! KB
    ) else (
        echo [INFO] Removed docs directory
    )
)

set "SIZE_INCLUDE=0"
if exist "%TARGET_DIR%\include" (
    for /f "tokens=1,3" %%a in ('dir /s /a "%TARGET_DIR%\include" ^| findstr /C:"File(s)"') do (
        set /a "SIZE_INCLUDE=%%b/1024"
    )
    rmdir /s /q "%TARGET_DIR%\include"
    if !SIZE_INCLUDE! GTR 0 (
        echo [INFO] Removed include directory, freed approximately !SIZE_INCLUDE! KB
    ) else (
        echo [INFO] Removed include directory
    )
)

rem Format LICENSE file and create documentation
echo [INFO] Formatting LICENSE file and creating documentation...
if exist "%TARGET_DIR%\LICENSE" (
    copy "%TARGET_DIR%\LICENSE" "%TARGET_DIR%\LICENSE.txt" >nul
    del /f /q "%TARGET_DIR%\LICENSE"
)

rem ===== Trimming Complete =====

rem Calculate final size using PowerShell for better reliability
echo [INFO] Calculating final size...
for /f "usebackq delims=" %%a in (`powershell -command "(Get-ChildItem -Recurse '%TARGET_DIR%' | Measure-Object -Property Length -Sum).Count"`) do (
    set "AFTER_FILES=%%a"
)
for /f "usebackq delims=" %%a in (`powershell -command "[math]::Round((Get-ChildItem -Recurse '%TARGET_DIR%' | Measure-Object -Property Length -Sum).Sum / 1MB, 2)"`) do (
    set "AFTER_SIZE_MB=%%a"
)

set /a "SAVED_FILES=BEFORE_FILES-AFTER_FILES"

rem Calculate size difference and percentage with PowerShell
for /f "usebackq delims=" %%a in (`powershell -command "[math]::Round(!BEFORE_SIZE_MB! - !AFTER_SIZE_MB!, 2)"`) do (
    set "SAVED_SIZE_MB=%%a"
)

if !BEFORE_SIZE_MB! GTR 0 (
    for /f "usebackq delims=" %%a in (`powershell -command "[math]::Round((!SAVED_SIZE_MB! / !BEFORE_SIZE_MB!) * 100, 1)"`) do (
        set "SAVED_PERCENT=%%a"
    )
) else (
    set "SAVED_PERCENT=0"
)

echo [INFO] Trimming complete: Removed !SAVED_FILES! files, leaving !AFTER_FILES! files
echo [INFO] Space saved: !SAVED_SIZE_MB! MB (Approximately !SAVED_PERCENT!%%)

rem Create required directories
echo [INFO] Creating data, logs and temp directories...
mkdir "%TARGET_DIR%\data"
mkdir "%TARGET_DIR%\logs"
mkdir "%TARGET_DIR%\tmp"

rem Copy necessary configuration and script files
echo [INFO] Copying configuration and initialization files...

rem Copy init_mysql directory with all its contents
if exist "%FILES_DIR%\init_mysql" (
    mkdir "%TARGET_DIR%\init_mysql"
    xcopy "%FILES_DIR%\init_mysql\*" "%TARGET_DIR%\init_mysql\" /E /H /I /Y >nul
    echo [INFO] Copied init_mysql directory and its contents
) else (
    echo [WARNING] init_mysql directory not found in files directory!
)

rem Copy README file
if exist "%FILES_DIR%\README.md" (
    copy "%FILES_DIR%\README.md" "%TARGET_DIR%\README.md" >nul
    echo [INFO] Copied README.md
)

echo [INFO] Creating portable installation package...
set "ZIP_FILE=%OUTPUT_DIR%\mysql-%MYSQL_PACKAGE_LABEL%-portable.zip"

rem Delete existing zip if it exists
if exist "%ZIP_FILE%" del /f /q "%ZIP_FILE%"

powershell -Command "Compress-Archive -Path '%TARGET_DIR%\*' -DestinationPath '%ZIP_FILE%' -Force"

if exist "%ZIP_FILE%" (
    set "PACKAGE_CREATED=1"
) else (
    echo [ERROR] Failed to create portable installation package!
    goto :END
)

echo.
echo [SUCCESS] MySQL portable installation package created!
echo Output file: %ZIP_FILE%
echo.
echo You can extract the package and run the following:
echo   1. init_mysql\init_mysql.bat - Initialize MySQL
echo   2. start_mysql.bat           - Start MySQL service
echo   3. stop_mysql.bat            - Stop MySQL service
echo.

echo [INFO] Do you want to delete the temporary generated directory? (Y/N)
echo [INFO] Press Enter for default (Y) to delete temporary files
set /p DELETE_TEMP="Enter N to keep or press Enter to delete: "

if /i "%DELETE_TEMP%"=="" (
    set "DELETE_TEMP=Y"
)

if /i "%DELETE_TEMP%"=="Y" (
    echo [INFO] Deleting temporary directory...
    rmdir /s /q "%TARGET_DIR%"
    echo Deletion completed!
) else (
    echo Temporary directory preserved: %TARGET_DIR%
)

echo.
echo Process completed!

:END

if /i not "%PACKAGE_CREATED%"=="1" goto :FINALIZE

rem === Check and download VC Redistributable ===
echo [INFO] Do you want to download and include Visual C++ Redistributable (vc_redist.x64.exe)? (Y/N)
echo [INFO] Press Enter for default (Y) to download and include.
set /p DOWNLOAD_VC="Enter N to skip or press Enter to download: "
if /i "%DOWNLOAD_VC%"=="" set "DOWNLOAD_VC=Y"

if /i "%DOWNLOAD_VC%"=="Y" (
    echo [INFO] Checking network connection...
    powershell -Command "try { (Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -UseBasicParsing -OutFile '%OUTPUT_DIR%\vc_redist.x64.exe'); exit 0 } catch { exit 1 }"
    if exist "%OUTPUT_DIR%\vc_redist.x64.exe" (
        echo [SUCCESS] Downloaded Visual C++ Redistributable to %OUTPUT_DIR%\vc_redist.x64.exe
    ) else (
        echo [WARNING] Failed to download Visual C++ Redistributable. Please download manually if needed.
    )
) else (
    echo [INFO] Skipped downloading Visual C++ Redistributable.
)

:FINALIZE
pause 
