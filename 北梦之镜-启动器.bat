@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 北梦之镜启动器 - Mirror of NorthDreamad-1.0

:: 配置
set "VERSION_URL=http://svc.maxd.cloud:21128/d/%%E7%%BD%%91%%E7%%AB%%99%%E6%%89%%80%%E9%%9C%%80%%E6%%96%%87%%E4%%BB%%B6/bmxh/versionPC.txt"
set "PROGRAM_PREFIX=北梦之镜-Mirror of NorthDreamad_"

:: 启用 ANSI 颜色支持 (Windows 10+)
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%" geq "10.0" (
    reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
)

:: ANSI 颜色代码定义 (使用 ESC 字符)
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "MAGENTA=%ESC%[95m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"

:: 显示横幅
echo.
echo %CYAN%======================================================================%RESET%
echo %MAGENTA%%BOLD%                  北梦之镜 - Mirror of NorthDreamad%RESET%
echo %CYAN%======================================================================%RESET%
echo %YELLOW%                    北梦星海-北梦之镜-2025-启动器%RESET%
echo %GREEN%            北梦之镜-映你所需-支持Windows客户端/安卓客户端%RESET%
echo %CYAN%======================================================================%RESET%
echo %CYAN%官网: %WHITE%https://bmxh.haovm.gq/%RESET%
echo %CYAN%官方交流群: %WHITE%934966618%RESET%
echo %CYAN%保存位置: %WHITE%%~dp0%RESET%
echo %CYAN%======================================================================%RESET%

:: 步骤 1: 下载版本文件
echo.
echo %CYAN%[步骤 1/4]%RESET% 检查云端版本...
set "VERSION_FILE=%TEMP%\bmxh_version.txt"

:: 使用 PowerShell 下载版本信息
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent', 'Mozilla/5.0'); $wc.DownloadFile('%VERSION_URL%', '%VERSION_FILE%'); exit 0 } catch { exit 1 }}" >nul 2>&1

if errorlevel 1 (
    echo %RED%✗ 连接服务器失败%RESET%
    pause
    exit /b 1
)

echo %GREEN%✓ 连接服务器成功%RESET%

:: 步骤 2: 解析版本
echo.
echo %CYAN%[步骤 2/4]%RESET% 解析版本列表...

:: 读取版本文件，找到最新版本
set "LATEST_VER="
set "DOWNLOAD_URL="

for /f "tokens=1,2*" %%a in (%VERSION_FILE%) do (
    if "%%a" NEQ "" if "%%b" NEQ "" (
        set "ver=%%a"
        if "!ver:~0,1!"=="V" (
            set "LATEST_VER=%%a"
            set "DOWNLOAD_URL=%%b"
        )
    )
)

if "%LATEST_VER%"=="" (
    echo %RED%✗ 错误: 云端版本信息为空%RESET%
    del "%VERSION_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo %GREEN%✓ 发现最新版本: %BOLD%%LATEST_VER%%RESET%

:: 步骤 3: 检查本地文件
echo.
echo %CYAN%[步骤 3/4]%RESET% 检查本地文件...

set "TARGET_FILE=%~dp0%PROGRAM_PREFIX%%LATEST_VER%.exe"

:: 检查文件是否存在且大小合理（大于 1MB）
set "NEED_DOWNLOAD=1"
if exist "%TARGET_FILE%" (
    for %%F in ("%TARGET_FILE%") do set "FILE_SIZE=%%~zF"
    if !FILE_SIZE! gtr 1048576 (
        set "NEED_DOWNLOAD=0"
        set /a size_mb=!FILE_SIZE!/1048576
        echo %GREEN%✓ 已存在最新版本: %PROGRAM_PREFIX%%LATEST_VER%.exe%RESET%
        echo %CYAN%  文件大小: !size_mb! MB%RESET%
    ) else (
        echo %YELLOW%! 文件异常 ^(!FILE_SIZE! 字节^)，需要重新下载%RESET%
        del "%TARGET_FILE%" >nul 2>&1
    )
)

if !NEED_DOWNLOAD! equ 1 (
    echo %YELLOW%需要下载: %PROGRAM_PREFIX%%LATEST_VER%.exe%RESET%
    echo.
    echo %CYAN%正在下载: %PROGRAM_PREFIX%%LATEST_VER%.exe%RESET%
    echo %CYAN%下载地址: %DOWNLOAD_URL:~0,80%...%RESET%
    
    :: 使用 PowerShell 下载（带进度条）
    set "PS_SCRIPT=!TEMP!\bmxh_dl.ps1"
    (
        echo param^($url,$output^)
        echo [System.Net.ServicePointManager]::SecurityProtocol=[System.Net.SecurityProtocolType]::Tls12
        echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
        echo try {
        echo     $req=[System.Net.HttpWebRequest]::Create($url^)
        echo     $req.UserAgent='Mozilla/5.0'
        echo     $req.Timeout=30000
        echo     $resp=$req.GetResponse(^)
        echo     $total=$resp.ContentLength
        echo     $stream=$resp.GetResponseStream(^)
        echo     $temp=$output+'.tmp'
        echo     $file=[System.IO.File]::Create($temp^)
        echo     $buf=New-Object byte[] 8192
        echo     $dl=0
        echo     $last=-1
        echo     while($true^){
        echo         $c=$stream.Read($buf,0,$buf.Length^)
        echo         if($c -eq 0^){break}
        echo         $file.Write($buf,0,$c^)
        echo         $dl+=$c
        echo         if($total -gt 0^){
        echo             $p=[int](($dl/$total^)*100^)
        echo             if($p -ne $last -and $p %% 2 -eq 0^){
        echo                 $mb=[math]::Round($dl/1MB,1^)
        echo                 $tmb=[math]::Round($total/1MB,1^)
        echo                 $bar='='*($p/2^)+' '*(50-$p/2^)
        echo                 Write-Host -NoNewline "`r^|$bar^| $p%% $mb MB/$tmb MB" -ForegroundColor Cyan
        echo                 $last=$p
        echo             }
        echo         }
        echo     }
        echo     $file.Close(^)
        echo     $stream.Close(^)
        echo     $resp.Close(^)
        echo     Write-Host ''
        echo     if(Test-Path $output^){Remove-Item $output -Force}
        echo     Move-Item $temp $output -Force
        echo     exit 0
        echo } catch {
        echo     Write-Host "Error: $_" -ForegroundColor Red
        echo     if(Test-Path $temp^){Remove-Item $temp -Force}
        echo     exit 1
        echo }
    ) > "!PS_SCRIPT!"
    
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!" -url "!DOWNLOAD_URL!" -output "!TARGET_FILE!"
    set "DL_ERR=!ERRORLEVEL!"
    del "!PS_SCRIPT!" >nul 2>&1
    
    if !DL_ERR! neq 0 (
        echo %RED%✗ 下载失败%RESET%
        del "%VERSION_FILE%" >nul 2>&1
        pause
        exit /b 1
    )
    
    :: 验证下载的文件
    if not exist "!TARGET_FILE!" (
        echo %RED%✗ 下载失败: 文件不存在%RESET%
        pause
        exit /b 1
    )
    
    :: 检查文件大小
    for %%F in ("!TARGET_FILE!") do set "DOWNLOAD_SIZE=%%~zF"
    if !DOWNLOAD_SIZE! lss 1024 (
        echo %RED%✗ 下载失败: 文件大小异常 ^(!DOWNLOAD_SIZE! 字节^)%RESET%
        del "!TARGET_FILE!" >nul 2>&1
        pause
        exit /b 1
    )
    
    set /a size_mb=!DOWNLOAD_SIZE!/1048576
    echo %GREEN%✓ 下载完成: !size_mb! MB%RESET%
)

:: 清理临时文件
del "%VERSION_FILE%" >nul 2>&1

:: 步骤 4: 启动程序
echo.
echo %CYAN%[步骤 4/4]%RESET% 启动程序...

if not exist "%TARGET_FILE%" (
    echo %RED%✗ 错误: 程序文件不存在%RESET%
    pause
    exit /b 1
)

echo.
echo %CYAN%正在启动: %PROGRAM_PREFIX%%LATEST_VER%.exe%RESET%
start "" "%TARGET_FILE%"

if errorlevel 1 (
    echo %RED%✗ 启动失败%RESET%
    pause
    exit /b 1
)

echo %GREEN%✓ 启动成功！%RESET%

:: 显示感谢信息
echo.
echo %MAGENTA%======================================================================%RESET%
echo %CYAN%%BOLD%             感谢您使用北梦之镜 - Mirror of NorthDreamad%RESET%
echo %MAGENTA%======================================================================%RESET%
echo.

:: 倒计时 5 秒 (使用 PowerShell 实现单行更新)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {$ESC = [char]27; for ($i = 5; $i -ge 1; $i--) { Write-Host -NoNewline \"$ESC[93m启动器将在 $i 秒后关闭...$ESC[0m`r\"; Start-Sleep -Seconds 1 }; Write-Host ''}"

exit /b 0
