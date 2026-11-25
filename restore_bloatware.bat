@echo off
setlocal enabledelayedexpansion
title KHOI PHUC LAI CAC UNG DUNG GOC XIAOMI

cd /d "%~dp0"
set ADB=.\adb.exe

cls
echo ======================================================================
echo              KHOI PHUC LAI CAC UNG DUNG GOC XIAOMI
echo ======================================================================
echo.

:: 1. Kiem tra adb.exe
if not exist "%ADB%" (
    echo [LOI] Khong tim thay file adb.exe trong thu muc!
    pause
    exit /b 1
)

:: 2. Khoi dong ADB Server
echo [*] Dang khoi dong tien trinh ADB...
"%ADB%" start-server >nul 2>&1

:CHECK_DEVICE
echo [*] Dang kiem tra thiet bi ket noi...
set DEVICE_FOUND=0
set DEVICE_ID=
for /f "skip=1 tokens=1,2" %%i in ('"%ADB%" devices') do (
    if "%%j"=="device" (
        set DEVICE_FOUND=1
        set DEVICE_ID=%%i
    )
)

if "!DEVICE_FOUND!"=="1" (
    echo [OK] Da phat hien thiet bi ket noi: !DEVICE_ID!
    goto START_RESTORE
)

echo.
echo [!] Chua co thiet bi nao ket noi san qua USB hoac ADB Wi-Fi.
echo [*] Dang tu dong quet tim Smart TV trong mang noi bo (Port 5555 ADB)...
set SCAN_OUT=%TEMP%\tv_ip_found_%RANDOM%.txt
if exist "!SCAN_OUT!" del "!SCAN_OUT!" >nul 2>&1

set "SCAN_OUT=!SCAN_OUT!"
powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABuAGkAYwBzAD0AQAAoAEcAZQB0AC0AVwBtAGkATwBiAGoAZQBjAHQAIABXAGkAbgAzADIAXwBOAGUAdAB3AG8AcgBrAEEAZABhAHAAdABlAHIAQwBvAG4AZgBpAGcAdQByAGEAdABpAG8AbgAgAC0ARgBpAGwAdABlAHIAIAAnAEkAUABFAG4AYQBiAGwAZQBkAD0AVABSAFUARQAnAHwAVwBoAGUAcgBlAC0ATwBiAGoAZQBjAHQAewAkAF8ALgBEAGUAZgBhAHUAbAB0AEkAUABHAGEAdABlAHcAYQB5ACAALQBhAG4AZAAgACQAXwAuAEQAZQBmAGEAdQBsAHQASQBQAEcAYQB0AGUAdwBhAHkALgBDAG8AdQBuAHQAIAAtAGcAdAAgADAAfQApAAoAJABhAD0AJABuAHUAbABsADsAJABpAHAAPQAnACcAOwAkAGcAdwA9ACcAJwA7ACQAaQBmAD0AJwAnAAoAZgBvAHIAZQBhAGMAaAAoACQAbgAgAGkAbgAgACQAbgBpAGMAcwApAHsACgAgAGkAZgAoAFsAcwB0AHIAaQBuAGcAXQAkAG4ALgBEAGUAcwBjAHIAaQBwAHQAaQBvAG4AIAAtAG0AYQB0AGMAaAAgACcAVgBNAHcAYQByAGUAfABWAGkAcgB0AHUAYQBsAHwATABvAG8AcABiAGEAYwBrAHwAdgBFAHQAaABlAHIAbgBlAHQAfABUAEEAUAB8AFYAUABOAHwAQgBsAHUAZQB0AG8AbwB0AGgAJwApAHsAYwBvAG4AdABpAG4AdQBlAH0ACgAgACQAdgA0AD0AQAAoACQAbgAuAEkAUABBAGQAZAByAGUAcwBzAHwAVwBoAGUAcgBlAC0ATwBiAGoAZQBjAHQAewAkAF8AIAAtAG0AYQB0AGMAaAAgACcAXgBcAGQAKwBcAC4AXABkACsAXAAuAFwAZAArAFwALgBcAGQAKwAkACcAIAAtAGEAbgBkACAAJABfACAALQBuAG8AdABsAGkAawBlACAAJwAxADYAOQAuADIANQA0ACoAJwAgAC0AYQBuAGQAIAAkAF8AIAAtAG4AbwB0AGwAaQBrAGUAIAAnADEAMgA3ACoAJwB9ACkACgAgAGkAZgAoACQAdgA0AC4AQwBvAHUAbgB0ACAALQBnAHQAIAAwACkAewAkAGEAPQAkAG4AOwAkAGkAcAA9ACQAdgA0AFsAMABdADsAJABnAHcAPQAkAG4ALgBEAGUAZgBhAHUAbAB0AEkAUABHAGEAdABlAHcAYQB5AFsAMABdADsAJABpAGYAPQBbAHMAdAByAGkAbgBnAF0AJABuAC4ARABlAHMAYwByAGkAcAB0AGkAbwBuADsAYgByAGUAYQBrAH0ACgB9AAoAaQBmACgALQBuAG8AdAAgACQAYQApAHsAZgBvAHIAZQBhAGMAaAAoACQAbgAgAGkAbgAgACQAbgBpAGMAcwApAHsACgAgACQAdgA0AD0AQAAoACQAbgAuAEkAUABBAGQAZAByAGUAcwBzAHwAVwBoAGUAcgBlAC0ATwBiAGoAZQBjAHQAewAkAF8AIAAtAG0AYQB0AGMAaAAgACcAXgBcAGQAKwBcAC4AXABkACsAXAAuAFwAZAArAFwALgBcAGQAKwAkACcAfQApAAoAIABpAGYAKAAkAHYANAAuAEMAbwB1AG4AdAAgAC0AZwB0ACAAMAApAHsAJABhAD0AJABuADsAJABpAHAAPQAkAHYANABbADAAXQA7ACQAZwB3AD0AJABuAC4ARABlAGYAYQB1AGwAdABJAFAARwBhAHQAZQB3AGEAeQBbADAAXQA7ACQAaQBmAD0AWwBzAHQAcgBpAG4AZwBdACQAbgAuAEQAZQBzAGMAcgBpAHAAdABpAG8AbgA7AGIAcgBlAGEAawB9AAoAfQB9AAoAaQBmACgALQBuAG8AdAAgACQAYQAgAC0AbwByACAALQBuAG8AdAAgACQAaQBwACkAewBlAHgAaQB0AH0ACgAkAHAAPQAkAGkAcAAuAFMAdQBiAHMAdAByAGkAbgBnACgAMAAsACQAaQBwAC4ATABhAHMAdABJAG4AZABlAHgATwBmACgAJwAuACcAKQArADEAKQAKAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAiAFsAKwBdACAARABhAG4AZwAgAHEAdQBlAHQAIABTAG0AYQByAHQAIABUAFYAIAB0AHIAbwBuAGcAIABkAGEAaQAgAG0AYQBuAGcAIAAkAHsAcAB9ADEAIAAtAD4AIAAkAHsAcAB9ADIANQA0AC4ALgAuACIAIAAtAEYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACAAQwB5AGEAbgAKACQAcAA9ACQAaQBwAC4AUwB1AGIAcwB0AHIAaQBuAGcAKAAwACwAJABpAHAALgBMAGEAcwB0AEkAbgBkAGUAeABPAGYAKAAnAC4AJwApACsAMQApAAoAJABwAG8AbwBsAD0AWwByAHUAbgBzAHAAYQBjAGUAZgBhAGMAdABvAHIAeQBdADoAOgBDAHIAZQBhAHQAZQBSAHUAbgBzAHAAYQBjAGUAUABvAG8AbAAoADEALAA2ADAAKQA7ACQAcABvAG8AbAAuAE8AcABlAG4AKAApAAoAJAB0AGEAcwBrAHMAPQAxAC4ALgAyADUANAB8AEYAbwByAEUAYQBjAGgALQBPAGIAagBlAGMAdAB7AAoAIAAkAHQAPQAkAHAAKwAkAF8ACgAgACQAcABzAD0AWwBwAG8AdwBlAHIAcwBoAGUAbABsAF0AOgA6AEMAcgBlAGEAdABlACgAKQAuAEEAZABkAFMAYwByAGkAcAB0ACgAewBwAGEAcgBhAG0AKAAkAGgAKQAkAGMAPQBOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAGMAcABDAGwAaQBlAG4AdAA7ACQAYQByAD0AJABjAC4AQgBlAGcAaQBuAEMAbwBuAG4AZQBjAHQAKAAkAGgALAA1ADUANQA1ACwAJABuAHUAbABsACwAJABuAHUAbABsACkAOwBpAGYAKAAkAGEAcgAuAEEAcwB5AG4AYwBXAGEAaQB0AEgAYQBuAGQAbABlAC4AVwBhAGkAdABPAG4AZQAoADMANQAwACwAJABmAGEAbABzAGUAKQApAHsAdAByAHkAewAkAGMALgBFAG4AZABDAG8AbgBuAGUAYwB0ACgAJABhAHIAKQA7ACQAYwAuAEMAbABvAHMAZQAoACkAOwByAGUAdAB1AHIAbgAgACQAaAB9AGMAYQB0AGMAaAB7AH0AfQA7ACQAYwAuAEMAbABvAHMAZQAoACkAOwByAGUAdAB1AHIAbgAgACQAbgB1AGwAbAB9ACkALgBBAGQAZABBAHIAZwB1AG0AZQBuAHQAKAAkAHQAKQAKACAAJABwAHMALgBSAHUAbgBzAHAAYQBjAGUAUABvAG8AbAA9ACQAcABvAG8AbAA7AE4AZQB3AC0ATwBiAGoAZQBjAHQAIABQAFMATwBiAGoAZQBjAHQAIAAtAFAAcgBvAHAAZQByAHQAeQAgAEAAewBQAD0AJABwAHMAOwBBAD0AJABwAHMALgBCAGUAZwBpAG4ASQBuAHYAbwBrAGUAKAApAH0ACgB9AAoAJABmAG8AdQBuAGQAPQAnACcACgBmAG8AcgBlAGEAYwBoACgAJAB0ACAAaQBuACAAJAB0AGEAcwBrAHMAKQB7ACQAcgA9ACQAdAAuAFAALgBFAG4AZABJAG4AdgBvAGsAZQAoACQAdAAuAEEAKQA7AGkAZgAoACQAcgApAHsAVwByAGkAdABlAC0ASABvAHMAdAAgACIAPgA+AD4AIABbAFQASQBNACAAVABIAEEAWQAgAFMATQBBAFIAVAAgAFQAVgBdACAASQBQADoAIAAkAHIAIAAoAFAAbwByAHQAIAA1ADUANQA1ACAAZABhAG4AZwAgAG0AbwAhACkAIgAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABHAHIAZQBlAG4AOwBpAGYAKAAtAG4AbwB0ACAAJABmAG8AdQBuAGQAKQB7ACQAZgBvAHUAbgBkAD0AJAByAH0AfQA7ACQAdAAuAFAALgBEAGkAcwBwAG8AcwBlACgAKQB9AAoAJABwAG8AbwBsAC4AQwBsAG8AcwBlACgAKQA7ACQAcABvAG8AbAAuAEQAaQBzAHAAbwBzAGUAKAApAAoAaQBmACgAJABmAG8AdQBuAGQAIAAtAGEAbgBkACAAJABlAG4AdgA6AFMAQwBBAE4AXwBPAFUAVAApAHsAWwBTAHkAcwB0AGUAbQAuAEkATwAuAEYAaQBsAGUAXQA6ADoAVwByAGkAdABlAEEAbABsAFQAZQB4AHQAKAAkAGUAbgB2ADoAUwBDAEEATgBfAE8AVQBUACwAJABmAG8AdQBuAGQALABbAFMAeQBzAHQAZQBtAC4AVABlAHgAdAAuAEUAbgBjAG8AZABpAG4AZwBdADoAOgBBAFMAQwBJAEkAKQB9AAoA

set AUTO_IP=
if exist "!SCAN_OUT!" (
    for /f "usebackq tokens=*" %%a in ("!SCAN_OUT!") do (
        if "!AUTO_IP!"=="" set AUTO_IP=%%a
    )
    del "!SCAN_OUT!" >nul 2>&1
)

if not "!AUTO_IP!"=="" (
    set TV_IP=!AUTO_IP!
    goto AUTO_FOUND
)
goto MANUAL_IP

:AUTO_FOUND
echo.
echo ======================================================================
echo  [OK] DA TU DONG PHAT HIEN SMART TV TAI IP: !TV_IP!
echo ======================================================================
goto DO_CONNECT

:MANUAL_IP
echo.
echo [!] Quet tu dong khong tim thay TV nao dang mo cong ADB 5555.
echo.
echo ----------------------------------------------------------------------
echo  HUONG DAN BAT ADB TREN TV (DANH CHO TV MOI HOAC FACTORY RESET):
echo   1. Mo Cai dat TV (Settings) -^> Tuy chon thiet bi (Device Preferences)
echo   2. Chon Gioi thieu (About) -^> Bam lien tuc 7 lan vao "So ban dung" (Build Number)
echo      cho den khi xuat hien thong bao "Ban da la nha phat trien".
echo   3. Quay lai menu truoc -^> Chon "Tuy chon cho nha phat trien" (Developer options)
echo   4. BAT muc "Go loi USB" (USB Debugging) va "Go loi qua mang" (Wireless debugging).
echo   5. Xem IP TV tai: Cai dat -^> Mang va Internet -^> Wi-Fi dang ket noi.
echo ----------------------------------------------------------------------
echo.

set /p TV_IP=">> Nhap dia chi IP cua TV (Vi du: 192.168.18.235) hoac nhan Q de thoat: "
if /i "!TV_IP!"=="Q" exit /b 0
if "!TV_IP!"=="" (
    echo [LOI] Ban chua nhap dia chi IP!
    echo.
    goto CHECK_DEVICE
)

:DO_CONNECT
echo.
echo [*] Dang ket noi toi !TV_IP!:5555...
"%ADB%" connect !TV_IP!:5555
echo.
echo [LUU Y] Neu tren man hinh TV xuat hien hop thoai "Cho phep go loi USB?",
echo         hay tich chon "Luon cho phep tu may tinh nay" va bam "OK"!
echo.
ping -n 4 127.0.0.1 >nul

set DEVICE_FOUND=0
set DEVICE_ID=
for /f "skip=1 tokens=1,2" %%i in ('"%ADB%" devices') do (
    if "%%j"=="device" (
        set DEVICE_FOUND=1
        set DEVICE_ID=%%i
    )
)

if "!DEVICE_FOUND!"=="1" goto START_RESTORE

echo [X] Chua the xac thuc voi TV hoac TV chua chap nhan quyen ADB.
echo     Vui long kiem tra man hinh TV, tich chon cho phep go loi va thu lai.
echo.
set /p RETRY=">> Ban co muon thu ket noi lai khong? [Y/N, Mac dinh: Y]: "
if /i "!RETRY!"=="N" exit /b 1
goto CHECK_DEVICE

:START_RESTORE
echo.
echo ======================================================================
echo           BAT DAU KHOI PHUC LAI CAC UNG DUNG GOC XIAOMI
echo ======================================================================
echo.

set BLOAT_LIST=com.mitv.tvhome com.miui.tv.analytics com.xiaomi.mitv.tvpush.tvpushservice com.xiaomi.mitv.hyper.screensaver com.xiaomi.voicecontrol com.xiaomi.wakeupservice com.xiaomi.tweather com.xiaomi.mitv.calendar com.xiaomi.mitv.smartpanel com.xiaomi.mitv.healthdiagnosis com.xiaomi.mitv.karaoke.service com.xiaomi.screenrecorder com.xiaomi.mitv.shop com.mitv.toolhouse com.mitv.cloudcontrol

for %%p in (!BLOAT_LIST!) do (
    "%ADB%" shell pm enable %%p >nul 2>&1
    echo     [+] Da bat lai: %%p
)

echo.
echo ======================================================================
echo [OK] Da hoan thanh khoi phuc toan bo cac ung dung goc cua TV.
echo ======================================================================
echo.
pause
