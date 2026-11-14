@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CAI DAT VA DONG BO GEMINI API CHO TV LAUNCHER

cd /d "%~dp0"

echo ======================================================================
echo          TOOL CAI DAT VA DONG BO GEMINI API CHO TV LAUNCHER
echo                 [Android TV / Xiaomi MiTV Launcher]
echo ======================================================================
echo.

:: 1. Tim adb.exe
set "ADB="
if exist ".\adb.exe" set "ADB=.\adb.exe"
if "!ADB!"=="" if exist ".\INSTALL\adb.exe" set "ADB=.\INSTALL\adb.exe"
if "!ADB!"=="" if exist "..\INSTALL\adb.exe" set "ADB=..\INSTALL\adb.exe"
if "!ADB!"=="" (
    for %%X in (adb.exe) do (
        set "FOUND=%%~$PATH:X"
        if defined FOUND set "ADB=adb.exe"
    )
)

if "!ADB!"=="" (
    echo [LOI] Khong tim thay cong cu adb.exe trong thu muc hoac he thong!
    echo Vui long chep adb.exe vao thu muc nay hoac thu muc INSTALL.
    pause
    exit /b 1
)

:: 2. Kiem tra tham so dong lenh (non-interactive mode)
set "CLI_KEY=%~1"
set "CLI_IP=%~2"
set "CLI_MODEL=%~3"

:: 3. Khoi dong ADB
"%ADB%" start-server >nul 2>&1

:: 4. Xac dinh thiet bi TV
set "DEVICE_ID="
if not "!CLI_IP!"=="" (
    echo [*] Dang ket noi toi TV theo IP: !CLI_IP!...
    "%ADB%" connect !CLI_IP!:5555 >nul 2>&1
)

:: Kiem tra thiet bi da ket noi
for /f "skip=1 tokens=1,2" %%i in ('"%ADB%" devices') do (
    if "%%j"=="device" (
        if "!DEVICE_ID!"=="" set "DEVICE_ID=%%i"
    )
)

if not "!DEVICE_ID!"=="" goto DEVICE_READY

:PROMPT_DEVICE
echo [!] Chua phat hien thiet bi TV nao ket noi san qua ADB.
set "INPUT_IP="
set /p INPUT_IP="[*] Nhap IP cua TV [Mac dinh: 192.168.18.151, hoac 's' de quet tu dong]: "
if "!INPUT_IP!"=="" set "INPUT_IP=192.168.18.151"

if /i "!INPUT_IP!"=="s" (
    echo [*] Dang quet tim Smart TV tren mang cuc bo...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$adapter = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.InterfaceAlias -notmatch 'VMware|Virtual|Loopback|vEthernet|TAP|VPN|Bluetooth' -and $_.IPv4Address.IPAddress -notlike '169.254*' -and $_.IPv4Address.IPAddress -notlike '127*' } | Select-Object -First 1; if (-not $adapter) { $adapter = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object -First 1 }; if ($adapter) { $localIP = $adapter.IPv4Address.IPAddress; $prefix = $localIP.Substring(0, $localIP.LastIndexOf('.') + 1); $pool = [runspacefactory]::CreateRunspacePool(1, 60); $pool.Open(); $tasks = 1..254 | ForEach-Object { $ip = $prefix + $_; $ps = [powershell]::Create().AddScript({ param($t) $c = New-Object System.Net.Sockets.TcpClient; $a = $c.BeginConnect($t, 5555, $null, $null); if ($a.AsyncWaitHandle.WaitOne(350, $false)) { try { $c.EndConnect($a); $c.Close(); return $t } catch {} }; $c.Close(); return $null }).AddArgument($ip); $ps.RunspacePool = $pool; [PSCustomObject]@{ P = $ps; A = $ps.BeginInvoke() } }; $found = ''; foreach ($t in $tasks) { $r = $t.P.EndInvoke($t.A); if ($r -and -not $found) { $found = $r }; $t.P.Dispose() }; $pool.Close(); $pool.Dispose(); if ($found) { Set-Content -Path $env:TEMP\tv_ip_found.txt -Value $found -Encoding ASCII } }"
    if exist "%TEMP%\tv_ip_found.txt" (
        set /p INPUT_IP=<"%TEMP%\tv_ip_found.txt"
        del "%TEMP%\tv_ip_found.txt" >nul 2>&1
        echo [OK] Tim thay Smart TV tai IP: !INPUT_IP!
    ) else (
        echo [CANH BAO] Khong quet thay TV tu dong. Su dung IP mac dinh 192.168.18.151.
        set "INPUT_IP=192.168.18.151"
    )
)

echo [*] Dang ket noi den TV tai !INPUT_IP!:5555...
"%ADB%" connect !INPUT_IP!:5555
timeout /t 1 >nul 2>&1

for /f "skip=1 tokens=1,2" %%i in ('"%ADB%" devices') do (
    if "%%j"=="device" (
        if "!DEVICE_ID!"=="" set "DEVICE_ID=%%i"
    )
)

if "!DEVICE_ID!"=="" (
    echo.
    echo [LOI] Khong the ket noi toi TV qua ADB!
    echo Vui long kiem tra TV da mo port 5555 va ket noi chung mang Wi-Fi / LAN.
    pause
    exit /b 1
)

:DEVICE_READY
echo [OK] Da ket noi thiet bi TV: !DEVICE_ID!
echo.

:: 5. Doc cau hinh Gemini hien tai (neu co)
set "CURRENT_KEY="
set "CURRENT_MODEL=gemini-3.5-flash"

if exist "gemini_config.json" (
    for /f "tokens=*" %%a in ('powershell -NoProfile -Command "try { $j = Get-Content gemini_config.json -Raw | ConvertFrom-Json; Write-Host $j.gemini_api_key '|' $j.gemini_model } catch {}"') do (
        for /f "tokens=1,2 delims=|" %%k in ("%%a") do (
            set "CURRENT_KEY=%%k"
            set "CURRENT_MODEL=%%l"
        )
    )
)

if "!CURRENT_KEY!"=="" (
    for /f "tokens=*" %%a in ('"%ADB%" -s !DEVICE_ID! shell "cat /sdcard/com.ts.launcher/gemini_config.json 2>/dev/null"') do (
        for /f "tokens=*" %%x in ('powershell -NoProfile -Command "$txt = @'%%a'@; try { $j = $txt | ConvertFrom-Json; Write-Host $j.gemini_api_key '|' $j.gemini_model } catch {}"') do (
            for /f "tokens=1,2 delims=|" %%k in ("%%x") do (
                set "CURRENT_KEY=%%k"
                set "CURRENT_MODEL=%%l"
            )
        )
    )
)

if defined CURRENT_KEY set "CURRENT_KEY=!CURRENT_KEY: =!"
if defined CURRENT_MODEL set "CURRENT_MODEL=!CURRENT_MODEL: =!"
if "!CURRENT_MODEL!"=="" set "CURRENT_MODEL=gemini-3.5-flash"

echo ----------------------------------------------------------------------
if "!CURRENT_KEY!"=="" (
    echo  Gemini API Key hien tai : [Chua co / Rong]
) else (
    for /f "tokens=*" %%m in ('powershell -NoProfile -Command "$k='!CURRENT_KEY!'; if ($k.Length -gt 10) { Write-Host ($k.Substring(0, 8) + '...' + $k.Substring($k.Length - 4)) } else { Write-Host '********' }"') do (
        echo  Gemini API Key hien tai : %%m
    )
)
echo  Gemini Model hien tai   : !CURRENT_MODEL!
echo ----------------------------------------------------------------------
echo.

:: 6. Nhap API Key
set "NEW_KEY="
if not "!CLI_KEY!"=="" (
    set "NEW_KEY=!CLI_KEY!"
    goto KEY_READY
)

echo Nhap Gemini API Key cua ban (Chuot phai vao day de Paste).
if not "!CURRENT_KEY!"=="" (
    echo [Nhan Enter neu muon GIU NGUYEN Key hien tai]
)
set /p NEW_KEY="> API Key: "

if "!NEW_KEY!"=="" (
    if not "!CURRENT_KEY!"=="" (
        set "NEW_KEY=!CURRENT_KEY!"
        echo [*] Giu nguyen Gemini API Key hien tai.
    ) else (
        echo [LOI] Gemini API Key khong duoc de trong!
        pause
        exit /b 1
    )
)

:KEY_READY
set "NEW_KEY=!NEW_KEY: =!"

:: 7. Chon Model
set "NEW_MODEL="
if not "!CLI_MODEL!"=="" (
    set "NEW_MODEL=!CLI_MODEL!"
    goto MODEL_READY
)

echo.
echo Chon Gemini Model [Mac dinh: !CURRENT_MODEL!]:
echo   [1] gemini-3.5-flash        - Khuyen dung, nhanh nhat va on dinh nhat
echo   [2] gemini-3-flash-preview  - Ban thu nghiem
echo   [3] gemini-2.5-flash        - Ban on dinh the he 2.5
echo   [4] gemini-2.5-pro          - Model suy luan cao cap
echo   [5] Tu nhap ten model khac
set "MODEL_OPT="
set /p MODEL_OPT="> Lua chon [1-5, hoac Enter de giu '!CURRENT_MODEL!']: "

if "!MODEL_OPT!"=="1" set "NEW_MODEL=gemini-3.5-flash"
if "!MODEL_OPT!"=="2" set "NEW_MODEL=gemini-3-flash-preview"
if "!MODEL_OPT!"=="3" set "NEW_MODEL=gemini-2.5-flash"
if "!MODEL_OPT!"=="4" set "NEW_MODEL=gemini-2.5-pro"
if "!MODEL_OPT!"=="5" (
    set /p CUSTOM_MODEL="> Nhap ten model: "
    if not "!CUSTOM_MODEL!"=="" set "NEW_MODEL=!CUSTOM_MODEL!"
)
if "!NEW_MODEL!"=="" set "NEW_MODEL=!CURRENT_MODEL!"

:MODEL_READY
set "NEW_MODEL=!NEW_MODEL: =!"

echo.
echo [*] Dang tao file cau hinh gemini_config.json...

:: 8. Ghi file JSON cuc bo
set "TEMP_JSON=%TEMP%\gemini_config_%RANDOM%.json"
powershell -NoProfile -Command "$json = ConvertTo-Json @{ gemini_api_key = '!NEW_KEY!'; gemini_model = '!NEW_MODEL!' }; Set-Content -Path '%TEMP_JSON%' -Value $json -Encoding UTF8; Copy-Item '%TEMP_JSON%' 'gemini_config.json' -Force; if (Test-Path 'INSTALL') { Copy-Item '%TEMP_JSON%' 'INSTALL\gemini_config.json' -Force }; if (Test-Path '..\INSTALL') { Copy-Item '%TEMP_JSON%' '..\INSTALL\gemini_config.json' -Force }"

:: 9. Day file len TV
echo [*] Dang day cau hinh len TV (!DEVICE_ID!)...
"%ADB%" -s !DEVICE_ID! shell "mkdir -p /sdcard/com.ts.launcher" >nul 2>&1
"%ADB%" -s !DEVICE_ID! push "%TEMP_JSON%" /sdcard/com.ts.launcher/gemini_config.json
del "%TEMP_JSON%" >nul 2>&1

:: 10. Trich xuat IP cua TV
set "TV_IP_ONLY=!DEVICE_ID!"
for /f "tokens=1 delims=:" %%a in ("!DEVICE_ID!") do (
    set "TV_IP_ONLY=%%a"
)

:: 11. Dong bo qua socket LAN TCP cong 8999
echo [*] Dang dong bo truc tiep toi Launcher qua TCP port 8999...
powershell -NoProfile -Command "$c = New-Object System.Net.Sockets.TcpClient; try { $c.Connect('!TV_IP_ONLY!', 8999); $s = $c.GetStream(); $w = New-Object System.IO.StreamWriter($s, [System.Text.Encoding]::UTF8); $p = ConvertTo-Json @{ action = 'sync_gemini_config'; gemini_api_key = '!NEW_KEY!'; gemini_model = '!NEW_MODEL!' } -Compress; $w.WriteLine($p); $w.Flush(); $c.Close(); Write-Host '  -> [OK] Da cap nhat truc tiep vao RAM cua TV qua cong 8999' } catch { Write-Host '  -> Da luu file vao bo nho TV' }"

:: 12. Phat broadcast
echo [*] Dang kich hoat tai lai widget thi truong tren TV...
"%ADB%" -s !DEVICE_ID! shell am broadcast -a vn.herotran.launcher.ACTION_REFRESH_MARKET -p com.ts.launcher >nul 2>&1

echo.
echo ======================================================================
echo    DA LUU VA DONG BO GEMINI API VAO TV LAUNCHER THANH CONG!
echo ======================================================================
for /f "tokens=*" %%m in ('powershell -NoProfile -Command "$k='!NEW_KEY!'; if ($k.Length -gt 10) { Write-Host ($k.Substring(0, 8) + '...' + $k.Substring($k.Length - 4)) } else { Write-Host '********' }"') do (
    echo  - API Key : %%m
)
echo  - Model   : !NEW_MODEL!
echo  - Thiet bi: !DEVICE_ID!
echo  - File TV : /sdcard/com.ts.launcher/gemini_config.json
echo ======================================================================
echo TV se tu dong cap nhat gia xang dau va gia vang truc tiep tu Gemini AI.
echo.
pause
