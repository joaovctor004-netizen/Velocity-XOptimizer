@echo off
:: ============================================================
::  Velocity XOptimizer - v0.2
::  Otimizador de sistema para Windows 10 / 11
::  by JonzinhoXD
:: ============================================================
setlocal EnableExtensions
chcp 65001 >nul
mode con cols=100 lines=38 >nul 2>&1
title Velocity XOptimizer

:: -------------------- cores (ANSI / RGB) --------------------
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "BLUE=%ESC%[94m"
:: azul escuro / azul claro (substituem o antigo RGB: C1..C7 alternam entre os dois)
set "DB=%ESC%[38;2;40;90;225m"
set "LB=%ESC%[38;2;130;205;255m"
set "C1=%DB%"
set "C2=%LB%"
set "C3=%DB%"
set "C4=%LB%"
set "C5=%DB%"
set "C6=%LB%"
set "C7=%DB%"
set "RGBLINE=%C1%========%C2%========%C3%========%C4%========%C5%========%C6%========%C7%========%RESET%"
:: -------------------- cores do menu principal (branco / azul claro / azul escuro) --------------------
set "WHT=%ESC%[97m"
set "TB=%ESC%[38;2;70;150;255m"
set "BLUELINE=%DB%========%LB%========%DB%========%LB%========%DB%========%LB%========%DB%========%RESET%"

:: -------------------- caminhos --------------------
set "BASEDIR=%~dp0"
set "DATADIR=%BASEDIR%VelocityXOptimizer_Data"
set "LOGFILE=%DATADIR%\log.txt"
set "STARTUPBACKUP=%DATADIR%\startup_backup.txt"
set "TASKNAME=VelocityXOptimizer_AutoApply"
set "REGBK2=%DATADIR%\reg_opcao2.txt"
set "REGBK3=%DATADIR%\reg_opcao3.txt"
set "REGBK4=%DATADIR%\reg_opcao4.txt"
set "SVCBK2=%DATADIR%\servicos_opcao2.txt"
set "SVCBK4=%DATADIR%\servicos_opcao4.txt"
set "TKBK2=%DATADIR%\tarefas_opcao2.txt"
set "TKBK4=%DATADIR%\tarefas_opcao4.txt"
set "LASTACCBK=%DATADIR%\lastaccess_original.txt"
set "MOUSEFLAG=%DATADIR%\mouse_sem_aceleracao.flag"
set "HIBFLAG=%DATADIR%\hibernacao_desligada.flag"
set "XBOXFLAG=%DATADIR%\xbox_servicos_desligados.flag"
set "RB_OK=0"
set "RB_FAIL=0"
set "SV_OK=0"
set "TK_OK=0"
set "STARTUPOFF=%DATADIR%\startup_desativados.txt"
set "PLANBACKUP=%DATADIR%\plano_original.txt"
set "VPLAN=5f1c3b7e-0d1a-4c57-9a52-7e5a56a1f0b1"
set "PLANO_USE=%VPLAN%"

if not exist "%DATADIR%" mkdir "%DATADIR%" >nul 2>&1
if not exist "%LOGFILE%" type nul > "%LOGFILE%"

:: -------------------- checar/pedir admin --------------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Solicitando permissao de administrador...
    if "%~1"=="" (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    ) else (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs" >nul 2>&1
    )
    exit /b
)

:: -------------------- detectar Windows --------------------
set "OSNAME="
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul`) do set "OSNAME=%%i"
if "%OSNAME%"=="" for /f "tokens=*" %%v in ('ver') do set "OSNAME=%%v"

set "OSBUILD=0"
for /f "tokens=3" %%b in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| find "CurrentBuildNumber"') do set "OSBUILD=%%b"

set "WINVER="
set "COMPAT=0"
if %OSBUILD% GEQ 22000 (
    set "WINVER=11"
    set "COMPAT=1"
) else if %OSBUILD% GEQ 10240 (
    set "WINVER=10"
    set "COMPAT=1"
)

if "%COMPAT%"=="1" (
    set "DOT=%GREEN%*%RESET%"
) else (
    set "DOT=%RED%*%RESET%"
)

:: -------------------- modo automatico (chamado pela tarefa agendada no login) --------------------
if /i "%~1"=="/auto" goto AUTOAPPLY

goto MENU

:: ============================================================
::  MODO AUTOMATICO - reaplica otimizacoes ativas no login
:: ============================================================
:AUTOAPPLY
call :DETECT_HW
if exist "%DATADIR%\opcao2.ativo" call :APLICAR_OPCAO2
if exist "%DATADIR%\opcao3.ativo" call :APLICAR_OPCAO3
if exist "%DATADIR%\opcao4.ativo" call :APLICAR_OPCAO4_EXTRA
call :LOG "Otimizacoes ativas reaplicadas automaticamente no login (/auto)"
exit /b

:: ============================================================
::  BANNER (titulo grande / rgb)
:: ============================================================
:BANNER
echo %RGBLINE%
echo.
echo   %C1%V%C2%e%C3%l%C4%o%C5%c%C6%i%C7%t%C1%y%RESET% %C2%X%C3%O%C4%p%C5%t%C6%i%C7%m%C1%i%C2%z%C3%e%C4%r%RESET%
echo.
echo %RGBLINE%
goto :eof

:: ============================================================
::  BANNER DO MENU PRINCIPAL (titulo azul / linhas azul claro e escuro)
::  (as outras telas continuam usando o :BANNER / RGBLINE original)
::  =========================================================== 
:BANNER_MENU
echo %BLUELINE%
echo.
echo   %TB%Velocity XOptimizer%RESET%
echo.
echo %BLUELINE%
goto :eof

:: ============================================================
::  FLOR (hortensia azul claro / azul escuro) - desenhada no espaco livre
::  a direita do menu, usando posicao do cursor (ESC[linha;colunaH)
::  Ocupa as linhas 1-22 e colunas 63-98, sem encostar no texto do menu.
:: ============================================================
:FLOWER
<nul set /p "=%ESC%[1;75H%LB%(%DB%o%LB%)(%DB%@%LB%)(%DB%@%LB%)(%DB%@%LB%)"
<nul set /p "=%ESC%[2;73H%LB%(%DB%@%LB%)(%DB%o%LB%)(%DB%@%LB%)(%DB%@%LB%)%DB%(%LB%@%DB%)%LB%(%DB%*%LB%)"
<nul set /p "=%ESC%[3;69H%LB%(%DB%O%LB%)(%DB%@%LB%)(%DB%@%LB%)(%DB%@%LB%)(%DB%@%LB%)%DB%(%LB%@%DB%)%LB%(%DB%*%LB%)(%DB%@%LB%)"
<nul set /p "=%ESC%[4;70H%LB%(%DB%@%LB%)(%DB%*%LB%)(%DB%@%LB%)(%DB%@%LB%)%DB%(%LB%*%DB%)%LB%(%DB%@%LB%)%DB%(%LB%o%DB%)%LB%(%DB%O%LB%)"
<nul set /p "=%ESC%[5;69H%LB%(%DB%@%LB%)(%DB%*%LB%)(%DB%@%LB%)(%DB%@%LB%)%DB%(%LB%@%DB%)%LB%(%DB%@%LB%)%DB%(%LB%o%DB%)(%LB%*%DB%)"
<nul set /p "=%ESC%[6;67H%LB%(%DB%@%LB%)(%DB%@%LB%)(%DB%o%LB%)(%DB%@%LB%)(%DB%@%LB%)%DB%(%LB%@%DB%)%LB%(%DB%O%LB%)%DB%(%LB%o%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[7;66H%LB%(%DB%@%LB%)(%DB%@%LB%)(%DB%o%LB%)(%DB%@%LB%)%DB%(%LB%@%DB%)(%LB%@%DB%)(%LB%*%DB%)%LB%(%DB%@%LB%)%DB%(%LB%@%DB%)(%LB%o%DB%)"
<nul set /p "=%ESC%[8;67H%LB%(%DB%O%LB%)(%DB%@%LB%)(%DB%*%LB%)(%DB%@%LB%)%DB%(%LB%@%DB%)%LB%(%DB%@%LB%)%DB%(%LB%@%DB%)%LB%(%DB%@%LB%)%DB%(%LB%*%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[9;66H%LB%(%DB%@%LB%)(%DB%*%LB%)%DB%(%LB%@%DB%)(%LB%@%DB%)%LB%(%DB%*%LB%)(%DB%o%LB%)%DB%(%LB%@%DB%)(%LB%@%DB%)(%LB%@%DB%)(%LB%o%DB%)"
<nul set /p "=%ESC%[10;67H%DB%(%LB%@%DB%)%LB%(%DB%O%LB%)%DB%(%LB%o%DB%)%LB%(%DB%*%LB%)(%DB%*%LB%)(%DB%@%LB%)%DB%(%LB%*%DB%)(%LB%*%DB%)(%LB%@%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[11;66H%LB%(%DB%@%LB%)(%DB%O%LB%)(%DB%o%LB%)%DB%(%LB%@%DB%)(%LB%@%DB%)(%LB%@%DB%)(%LB%@%DB%)(%LB%@%DB%)(%LB%@%DB%)(%LB%*%DB%)"
<nul set /p "=%ESC%[12;67H%LB%(%DB%@%LB%)(%DB%@%LB%)(%DB%@%LB%)%DB%(%LB%*%DB%)(%LB%O%DB%)(%LB%*%DB%)(%LB%@%DB%)(%LB%*%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[13;69H%LB%(%DB%O%LB%)(%DB%o%LB%)%DB%(%LB%@%DB%)(%LB%@%DB%)(%LB%@%DB%)(%LB%*%DB%)(%LB%@%DB%)%LB%(%DB%o%LB%)"
<nul set /p "=%ESC%[14;70H%DB%(%LB%@%DB%)%LB%(%DB%@%LB%)(%DB%O%LB%)%DB%(%LB%@%DB%)(%LB%O%DB%)(%LB%o%DB%)(%LB%@%DB%)(%LB%O%DB%)"
<nul set /p "=%ESC%[15;69H%LB%(%DB%O%LB%)%DB%(%LB%@%DB%)(%LB%O%DB%)(%LB%@%DB%)(%LB%@%DB%)%LB%(%DB%@%LB%)%DB%(%LB%@%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[16;73H%LB%(%DB%*%LB%)%DB%(%LB%@%DB%)(%LB%o%DB%)(%LB%*%DB%)(%LB%@%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[17;75H%DB%(%LB%@%DB%)(%LB%o%DB%)(%LB%@%DB%)(%LB%@%DB%)"
<nul set /p "=%ESC%[18;80H%DB%||"
<nul set /p "=%ESC%[19;71H%DB%_.-~~~-._||_.-~~~-._"
<nul set /p "=%ESC%[20;70H%DB%'-._____.-||-._____.-'"
<nul set /p "=%ESC%[21;80H%DB%||"
<nul set /p "=%ESC%[22;80H%DB%||"
<nul set /p "=%ESC%[1;1H"
goto :eof

:: ============================================================
::  MENU PRINCIPAL
:: ============================================================
:MENU
cls
call :FLOWER
call :BANNER_MENU
echo.
echo %WHT%Usando: %OSNAME% no momento %DOT%%RESET%
echo.
echo %TB%MEMORIA RAM%RESET%
echo %WHT% 1 - Limpar temporarios e cache do sistema%RESET%
echo %WHT% 2 - Aplicativos em segundo plano do Windows sem utilidade%RESET%
echo.
echo %TB%OTIMIZACAO%RESET%
echo %WHT% 3 - Otimizador do Windows%RESET%
echo %WHT% 4 - Otimizador do Jon%RESET%
echo.
echo %TB%OUTROS%RESET%
echo %WHT% 5 - Desativar opcoes%RESET%
echo %WHT% 6 - Redes sociais%RESET%
echo %WHT% 7 - Novidades da atualizacao%RESET%
echo %WHT% 8 - Sair%RESET%
echo.
echo %BLUELINE%
if "%WINVER%"=="10" (
    echo %WHT% by: %C2%J%C3%o%C4%n%C5%z%C6%i%C7%n%C1%h%C2%o%C3%X%C4%D%WHT%   %GREEN%v-0.2%WHT%   suporte: %GREEN%Windows 10%WHT% / Windows 11%RESET%
) else if "%WINVER%"=="11" (
    echo %WHT% by: %C2%J%C3%o%C4%n%C5%z%C6%i%C7%n%C1%h%C2%o%C3%X%C4%D%WHT%   %GREEN%v-0.2%WHT%   suporte: Windows 10 / %GREEN%Windows 11%RESET%
) else (
    echo %WHT% by: %C2%J%C3%o%C4%n%C5%z%C6%i%C7%n%C1%h%C2%o%C3%X%C4%D%WHT%   %GREEN%v-0.2%WHT%   %RED%NAO TEMOS SUPORTE PRA O SEU SISTEMA OPERACIONAL!%RESET%
)
echo %BLUELINE%
<nul set /p "=%WHT%"
choice /c 12345678 /n /m "Escolha uma opcao: "
set "MENUKEY=%errorlevel%"
<nul set /p "=%RESET%"
if "%MENUKEY%"=="8" goto SAIR
if "%MENUKEY%"=="7" goto OPCAO7
if "%MENUKEY%"=="6" goto OPCAO6
if "%MENUKEY%"=="5" goto MENU_DESATIVAR
if "%MENUKEY%"=="4" goto OPCAO4
if "%MENUKEY%"=="3" goto OPCAO3
if "%MENUKEY%"=="2" goto OPCAO2
if "%MENUKEY%"=="1" goto OPCAO1
goto MENU

:: ============================================================
::  OPCAO 1 - LIMPAR TEMPORARIOS E CACHE DO SISTEMA
:: ============================================================
:OPCAO1
cls
echo %RGBLINE%
echo   %GREEN%LIMPAR TEMPORARIOS E CACHE DO SISTEMA?%RESET%
echo %RGBLINE%
echo.
echo Vai limpar (seus arquivos pessoais NAO serao tocados):
echo   - Temporarios do usuario e do Windows
echo   - Cache do Windows Update e do Delivery Optimization
echo   - Relatorios de erro, dumps de falha e logs antigos do sistema
echo   - Cache de miniaturas, de internet e da Microsoft Store
echo   - Cache dos navegadores: Chrome, Edge, Brave, Opera, Vivaldi e Firefox
echo     (senhas, cookies e historico NAO sao apagados)
echo   - Cache do Discord, Steam e Spotify (login e musicas baixadas ficam)
echo   - Lixeira e cache de DNS
echo   - Opcional, limpeza profunda: componentes antigos do Windows (WinSxS)
echo     e cache de shaders da placa de video (os jogos demoram um pouco mais
echo     para abrir na primeira vez depois)
echo   - Se existir: pasta Windows.old (instalacao antiga, libera varios GB).
echo     Essa pergunta e separada, porque nao tem volta.
echo.
echo Arquivos em uso sao ignorados, nada e forcado nem corrompido.
echo.
echo %BASEDIR%| find /i "\Temp\" >nul 2>&1
if not errorlevel 1 goto O1_TEMPBLOQ
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
set "DEEP=0"
choice /c SN /n /m "Incluir limpeza profunda? Demora alguns minutos (S/N): "
if errorlevel 2 goto O1_NAV
set "DEEP=1"
:O1_NAV
set "WINOLD=0"
if exist "%SystemDrive%\Windows.old" set "WINOLD=1"
if exist "%SystemDrive%\$Windows.~BT" set "WINOLD=1"
if exist "%SystemDrive%\$WINDOWS.~WS" set "WINOLD=1"
if not "%WINOLD%"=="1" goto O1_NAV2
echo.
echo %YELLOW%Foi encontrada uma instalacao antiga do Windows (Windows.old).%RESET%
echo Apagar libera varios GB, mas voce NAO vai mais poder voltar para a versao
echo anterior do Windows. Isso NAO pode ser desfeito.
choice /c SN /n /m "Apagar a instalacao antiga do Windows? (S/N): "
if errorlevel 2 goto O1_NAV2
set "WINOLD=2"
:O1_NAV2
call :FECHAR_NAVEGADORES
echo.
call :ESPACO_LIVRE FREE1
echo [1/8] Temporarios do usuario...
call :LIMPAR_PASTA "%TEMP%"
call :LIMPAR_PASTA "%LOCALAPPDATA%\Temp"
echo [2/8] Temporarios do Windows...
call :LIMPAR_PASTA "%SystemRoot%\Temp"
echo [3/8] Cache do Windows Update e Delivery Optimization...
set "WU_BUSY=0"
tasklist /nh /fi "imagename eq TiWorker.exe" 2>nul | find /i "TiWorker.exe" >nul 2>&1 && set "WU_BUSY=1"
if "%WU_BUSY%"=="1" goto O1_WU_OCUPADO
set "WU_WAS=0"
set "BITS_WAS=0"
set "DO_WAS=0"
sc query wuauserv | find "RUNNING" >nul 2>&1 && set "WU_WAS=1"
sc query bits | find "RUNNING" >nul 2>&1 && set "BITS_WAS=1"
sc query dosvc | find "RUNNING" >nul 2>&1 && set "DO_WAS=1"
net stop wuauserv /y >nul 2>&1
net stop bits /y >nul 2>&1
net stop dosvc /y >nul 2>&1
call :LIMPAR_PASTA "%SystemRoot%\SoftwareDistribution\Download"
call :LIMPAR_PASTA "%SystemRoot%\SoftwareDistribution\DeliveryOptimization"
call :LIMPAR_PASTA "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
call :LIMPAR_PASTA "%SystemRoot%\Logs\WindowsUpdate"
if "%WU_WAS%"=="1" net start wuauserv >nul 2>&1
if "%BITS_WAS%"=="1" net start bits >nul 2>&1
if "%DO_WAS%"=="1" net start dosvc >nul 2>&1
goto O1_PASSO4
:O1_WU_OCUPADO
echo %YELLOW%   O Windows esta instalando atualizacoes agora, este passo foi pulado.%RESET%
:O1_PASSO4
echo [4/8] Relatorios de erro, dumps de falha e logs antigos...
call :LIMPAR_PASTA "%ProgramData%\Microsoft\Windows\WER\ReportArchive"
call :LIMPAR_PASTA "%ProgramData%\Microsoft\Windows\WER\ReportQueue"
call :LIMPAR_PASTA "%ProgramData%\Microsoft\Windows\WER\Temp"
call :LIMPAR_PASTA "%LOCALAPPDATA%\CrashDumps"
call :LIMPAR_PASTA "%SystemRoot%\Minidump"
call :LIMPAR_PASTA "%SystemRoot%\LiveKernelReports"
call :LIMPAR_PASTA "%SystemRoot%\Logs\CBS"
del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
echo [5/8] Miniaturas, cache de internet e Microsoft Store...
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
call :LIMPAR_PASTA "%LOCALAPPDATA%\Microsoft\Windows\INetCache"
call :LIMPAR_PASTA "%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache"
echo [6/8] Cache dos navegadores...
call :LIMPAR_NAVEGADOR "%LOCALAPPDATA%\Google\Chrome\User Data"
call :LIMPAR_NAVEGADOR "%LOCALAPPDATA%\Microsoft\Edge\User Data"
call :LIMPAR_NAVEGADOR "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
call :LIMPAR_NAVEGADOR "%LOCALAPPDATA%\Vivaldi\User Data"
call :LIMPAR_CACHE_CHROMIUM "%LOCALAPPDATA%\Opera Software\Opera Stable"
call :LIMPAR_CACHE_CHROMIUM "%LOCALAPPDATA%\Opera Software\Opera Stable\Default"
call :LIMPAR_CACHE_CHROMIUM "%LOCALAPPDATA%\Opera Software\Opera GX Stable"
call :LIMPAR_CACHE_CHROMIUM "%LOCALAPPDATA%\Opera Software\Opera GX Stable\Default"
for /d %%P in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do call :LIMPAR_PASTA "%%~P\cache2"
echo [7/8] Cache do Discord, Steam e Spotify...
for %%D in (discord discordptb discordcanary) do (
    call :LIMPAR_PASTA "%APPDATA%\%%D\Cache"
    call :LIMPAR_PASTA "%APPDATA%\%%D\Code Cache"
    call :LIMPAR_PASTA "%APPDATA%\%%D\GPUCache"
)
call :LIMPAR_PASTA "%LOCALAPPDATA%\Steam\htmlcache"
call :LIMPAR_PASTA "%LOCALAPPDATA%\Spotify\Data"
echo [8/8] Lixeira e cache de DNS...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
ipconfig /flushdns >nul 2>&1
if "%WINOLD%"=="2" call :APAGAR_WINDOWS_OLD
if not "%DEEP%"=="1" goto O1_FIM
echo [+] Cache de shaders da placa de video...
call :LIMPAR_PASTA "%LOCALAPPDATA%\D3DSCache"
call :LIMPAR_PASTA "%LOCALAPPDATA%\NVIDIA\DXCache"
call :LIMPAR_PASTA "%LOCALAPPDATA%\NVIDIA\GLCache"
call :LIMPAR_PASTA "%LOCALAPPDATA%\AMD\DxCache"
call :LIMPAR_PASTA "%LOCALAPPDATA%\AMD\GLCache"
echo [+] Limpeza profunda de componentes do Windows, isso pode demorar...
Dism.exe /Online /Cleanup-Image /StartComponentCleanup >nul 2>&1
:O1_FIM
call :ESPACO_LIVRE FREE2
set "LIBERADO=0 MB"
set "LIVRE_AGORA="
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "$d=[int64]$env:FREE2-[int64]$env:FREE1; if($d -lt 0){$d=0}; if($d -ge 1GB){'{0:N2} GB' -f ($d/1GB)}else{'{0:N0} MB' -f ($d/1MB)}" 2^>nul`) do set "LIBERADO=%%a"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "'{0:N1} GB' -f ([int64]$env:FREE2/1GB)" 2^>nul`) do set "LIVRE_AGORA=%%a"
call :LOG "Opcao 1 - Limpeza executada - espaco liberado: %LIBERADO%"
echo.
echo %GREEN%Concluido! Espaco liberado: %LIBERADO%%RESET%
if defined LIVRE_AGORA echo Espaco livre no disco do sistema agora: %LIVRE_AGORA%
pause
goto MENU

:O1_TEMPBLOQ
echo %YELLOW%O otimizador esta rodando de dentro de uma pasta temporaria.%RESET%
echo Mova o arquivo para outra pasta, como a Area de Trabalho, e abra de novo
echo antes de limpar, senao a propria limpeza apagaria o otimizador.
pause
goto MENU

:APAGAR_WINDOWS_OLD
echo [+] Removendo a instalacao antiga do Windows, isso pode demorar...
for %%F in ("%SystemDrive%\Windows.old" "%SystemDrive%\$Windows.~BT" "%SystemDrive%\$WINDOWS.~WS") do call :APAGAR_PASTA_PROTEGIDA "%%~F"
call :LOG "Opcao 1 - Instalacao antiga do Windows (Windows.old) apagada a pedido"
goto :eof

:APAGAR_PASTA_PROTEGIDA
if not exist "%~1" goto :eof
takeown /f "%~1" /r /d y >nul 2>&1
icacls "%~1" /grant *S-1-5-32-544:F /t /c /q >nul 2>&1
rd /s /q "%~1" >nul 2>&1
goto :eof

:FECHAR_NAVEGADORES
set "NAVABERTO="
for %%B in (chrome.exe msedge.exe brave.exe opera.exe vivaldi.exe firefox.exe) do (
    tasklist /nh /fi "imagename eq %%B" 2>nul | find /i "%%B" >nul 2>&1 && set "NAVABERTO=1"
)
if not defined NAVABERTO goto :eof
echo.
echo %YELLOW%Tem navegador aberto, e o cache dele nao sai por completo assim.%RESET%
echo Fechar agora pode perder abas e textos que voce ainda nao salvou.
choice /c SN /n /m "Fechar os navegadores abertos? (S/N): "
if errorlevel 2 goto :eof
for %%B in (chrome.exe msedge.exe brave.exe opera.exe vivaldi.exe firefox.exe) do taskkill /im %%B >nul 2>&1
timeout /t 3 /nobreak >nul
for %%B in (chrome.exe msedge.exe brave.exe opera.exe vivaldi.exe firefox.exe) do taskkill /f /im %%B >nul 2>&1
goto :eof

:LIMPAR_PASTA
if "%~1"=="" goto :eof
echo "%~1"| find ":" >nul 2>&1
if errorlevel 1 goto :eof
if not exist "%~1" goto :eof
del /f /s /q "%~1\*" >nul 2>&1
for /d %%D in ("%~1\*") do rd /s /q "%%D" >nul 2>&1
goto :eof

:LIMPAR_NAVEGADOR
if not exist "%~1" goto :eof
call :LIMPAR_PASTA "%~1\GrShaderCache"
call :LIMPAR_PASTA "%~1\ShaderCache"
for /d %%P in ("%~1\Default" "%~1\Profile *") do call :LIMPAR_CACHE_CHROMIUM "%%~P"
goto :eof

:LIMPAR_CACHE_CHROMIUM
if not exist "%~1" goto :eof
call :LIMPAR_PASTA "%~1\Cache"
call :LIMPAR_PASTA "%~1\Code Cache"
call :LIMPAR_PASTA "%~1\GPUCache"
call :LIMPAR_PASTA "%~1\DawnCache"
call :LIMPAR_PASTA "%~1\Service Worker\CacheStorage"
goto :eof

:ESPACO_LIVRE
set "%~1=0"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(New-Object System.IO.DriveInfo($env:SystemDrive)).AvailableFreeSpace" 2^>nul`) do set "%~1=%%a"
goto :eof

:: ============================================================
::  OPCAO 2 - APPS EM SEGUNDO PLANO (menu)
:: ============================================================
:OPCAO2
cls
echo %RGBLINE%
echo   %GREEN%DESATIVAR APLICATIVOS EM SEGUNDO PLANO DO WINDOWS SEM UTILIDADE?%RESET%
echo %RGBLINE%
echo.
if exist "%DATADIR%\opcao2.ativo" (
    echo %YELLOW%Esta opcao ja esta ativa.%RESET%
    pause
    goto MENU
)
echo Vai desativar apps, servicos e tarefas do Windows que ficam gastando RAM,
echo CPU e internet em segundo plano sem te dar nada em troca. Apps de seguranca
echo (Firewall, Windows Defender, Central de Seguranca) e o Windows Update
echo NAO sao mexidos.
echo.
echo Sera desativado:
echo   - Apps em segundo plano (todos) e Widgets / Noticias e Interesses
echo   - Telemetria, programa de experiencia, relatorio de erros, historico de
echo     atividades, coleta de digitacao/escrita e anuncios
echo   - Sugestoes, apps promovidos e instalacao silenciosa de apps
echo   - Copilot, Recall, Cortana e pesquisa na web no menu Iniciar
echo   - Cerca de 25 tarefas agendadas de diagnostico e coleta de dados
echo     (inclui a telemetria do Office)
echo   - Servicos: DiagTrack, dmwappushservice, RetailDemo, MapsBroker,
echo     WerSvc, diagnosticshub, diagsvc, TroubleshootingSvc,
echo     NvTelemetryContainer, wisvc
echo   - Processos inuteis que ja estiverem abertos (Widgets, Seu Telefone...)
echo.
echo Tudo pode ser desfeito pela opcao 5 (os valores originais sao guardados).
echo Tarefas e servicos que ja estavam desligados no seu PC continuam assim.
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
echo.
call :CONT_ZERAR
call :PONTO_RESTAURACAO
call :APLICAR_OPCAO2
call :SYNC_AUTOSTART
echo.
echo %GREEN%Concluido! Apps e tarefas de segundo plano sem utilidade foram desativados.%RESET%
call :RESUMO
echo Reinicie o PC para algumas mudancas terem efeito completo.
pause
goto MENU

:APLICAR_OPCAO2
echo Aplicando otimizacoes de segundo plano, aguarde...
set "REGBK=%REGBK2%"
set "SVCBK=%SVCBK2%"
set "TKBK=%TKBK2%"
set "TKATIVO=%DATADIR%\opcao2.ativo"
:: ---- apps em segundo plano
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" GlobalUserDisabled REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" BackgroundAppGlobalToggle REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" LetAppsRunInBackground REG_DWORD 2
:: ---- telemetria, erros, atividades e anuncios
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" AllowTelemetry REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" DoNotShowFeedbackNotifications REG_DWORD 1
call :RB_SET "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" AllowTelemetry REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" Disabled REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" TailoredExperiencesWithDiagnosticDataEnabled REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" EnableActivityFeed REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" PublishUserActivities REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" UploadUserActivities REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" CEIPEnable REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" AITEnable REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" DisableInventory REG_DWORD 1
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" DisableUAR REG_DWORD 1
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" DisableOneSettingsDownloads REG_DWORD 1
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" LimitDiagnosticLogCollection REG_DWORD 1
call :RB_SET_EXISTE "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener" Start REG_DWORD 0
call :RB_SET_EXISTE "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger" Start REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Siuf\Rules" NumberOfSIUFInPeriod REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Input\TIPC" Enabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\InputPersonalization" RestrictImplicitInkCollection REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\InputPersonalization" RestrictImplicitTextCollection REG_DWORD 1
:: ---- sugestoes, apps promovidos e instalacao silenciosa
for %%V in (ContentDeliveryAllowed OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled SilentInstalledAppsEnabled SoftLandingEnabled SystemPaneSuggestionsEnabled RotatingLockScreenOverlayEnabled FeatureManagementEnabled SubscribedContent-88000326Enabled SubscribedContent-314563Enabled SubscribedContent-280815Enabled SubscribedContent-202914Enabled SubscribedContent-310093Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled) do call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" %%V REG_DWORD 0
:: ---- widgets, noticias, copilot, cortana e busca na web
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Dsh" AllowNewsAndInterests REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" EnableFeeds REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" ShellFeedsTaskbarViewMode REG_DWORD 2
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarDa REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarMn REG_DWORD 0
call :RB_SET "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot REG_DWORD 1
call :RB_SET "HKCU\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" AllowCortana REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot REG_DWORD 1
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis REG_DWORD 1
call :RB_SET "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ShowCopilotButton REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" IsDynamicSearchBoxEnabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" Start_TrackProgs REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ShowSyncProviderNotifications REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" Start_IrisRecommendations REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" ScoobeSystemSettingEnabled REG_DWORD 0
:: ---- tarefas agendadas
call :TAREFAS_OP2 /Disable
:: ---- servicos (o estado original de cada um e guardado para a opcao 5)
call :SVC_SET DiagTrack disabled stop
call :SVC_SET dmwappushservice disabled stop
call :SVC_SET RetailDemo disabled stop
call :SVC_SET MapsBroker disabled stop
call :SVC_SET WerSvc disabled stop
call :SVC_SET diagnosticshub.standardcollector.service disabled stop
call :SVC_SET NvTelemetryContainer disabled stop
call :SVC_SET wisvc disabled stop
call :SVC_SET diagsvc disabled stop
call :SVC_SET TroubleshootingSvc disabled stop
:: ---- processos inuteis ja abertos
for %%P in (Widgets.exe WidgetService.exe YourPhone.exe PhoneExperienceHost.exe GameBar.exe GameBarFTServer.exe SkypeApp.exe SkypeBackgroundHost.exe HxTsr.exe) do taskkill /f /im %%P >nul 2>&1
if not exist "%DATADIR%\opcao2.ativo" > "%DATADIR%\opcao2.ativo" echo %date% %time%
call :LOG "Opcao 2 - Apps, servicos e tarefas de segundo plano desativados"
goto :eof

:TAREFAS_OP2
call :TK "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" %~1
call :TK "\Microsoft\Windows\Application Experience\ProgramDataUpdater" %~1
call :TK "\Microsoft\Windows\Application Experience\StartupAppTask" %~1
call :TK "\Microsoft\Windows\Application Experience\PcaPatchDbTask" %~1
call :TK "\Microsoft\Windows\Application Experience\MareBackup" %~1
call :TK "\Microsoft\Windows\Application Experience\AitAgent" %~1
call :TK "\Microsoft\Windows\Autochk\Proxy" %~1
call :TK "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" %~1
call :TK "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" %~1
call :TK "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" %~1
call :TK "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" %~1
call :TK "\Microsoft\Windows\DiskFootprint\Diagnostics" %~1
call :TK "\Microsoft\Windows\Feedback\Siuf\DmClient" %~1
call :TK "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" %~1
call :TK "\Microsoft\Windows\Windows Error Reporting\QueueReporting" %~1
call :TK "\Microsoft\Windows\Maps\MapsToastTask" %~1
call :TK "\Microsoft\Windows\Maps\MapsUpdateTask" %~1
call :TK "\Microsoft\Windows\NetTrace\GatherNetworkInfo" %~1
call :TK "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" %~1
call :TK "\Microsoft\Windows\Device Information\Device" %~1
call :TK "\Microsoft\Windows\PI\Sqm-Tasks" %~1
call :TK "\Microsoft\Office\OfficeTelemetryAgentFallBack2016" %~1
call :TK "\Microsoft\Office\OfficeTelemetryAgentLogOn2016" %~1
goto :eof

:: ============================================================
::  OPCAO 3 - OTIMIZADOR DO WINDOWS (modo jogo nativo)
:: ============================================================
:OPCAO3
cls
echo %RGBLINE%
echo   %GREEN%OTIMIZADOR DO WINDOWS%RESET%
echo %RGBLINE%
echo.
if exist "%DATADIR%\opcao3.ativo" (
    echo %YELLOW%Esta opcao ja esta ativa.%RESET%
    pause
    goto MENU
)
echo Deixa o Windows pronto para jogos, mais FPS e menos travadas:
echo.
echo   - Modo de Jogo ligado e Game DVR / gravacao em segundo plano desligados
echo   - Barra de Jogos e botao Xbox nao interrompem mais o jogo
echo   - Prioridade de CPU, disco e GPU maior para os jogos
echo   - Limite de rede do Windows removido e agendamento de GPU por hardware
echo   - Plano de energia proprio do Velocity: Desempenho Maximo no desktop e
echo     Alto Desempenho no notebook (seu plano original volta pela opcao 5)
echo   - Plano de energia ajustado na tomada: USB sem suspensao, PCIe e disco
echo     sem economia de energia e processador sem limite minimo
echo   - Sem os avisos chatos de Teclas de Aderencia dentro dos jogos
echo   - Opcional: mouse sem aceleracao (mira igual em qualquer velocidade)
echo.
echo Um ponto de restauracao sera criado antes de aplicar.
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
choice /c SN /n /m "Desligar a aceleracao do mouse? Bom para FPS (S/N): "
if errorlevel 2 goto O3_SEMMOUSE
> "%MOUSEFLAG%" echo 1
:O3_SEMMOUSE
echo.
call :CONT_ZERAR
call :PONTO_RESTAURACAO
call :APLICAR_OPCAO3
call :SYNC_AUTOSTART
echo.
echo %GREEN%Concluido! Modo de jogo ativado e ajustes de desempenho aplicados.%RESET%
call :RESUMO
echo Reinicie o PC para o agendamento de GPU ter efeito completo.
pause
goto MENU

:APLICAR_OPCAO3
echo Aplicando otimizacoes de jogo, aguarde...
call :DETECT_HW
set "REGBK=%REGBK3%"
:: ---- modo de jogo e game dvr
call :RB_SET "HKCU\Software\Microsoft\GameBar" AllowAutoGameMode REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\GameBar" AutoGameModeEnabled REG_DWORD 1
call :RB_SET "HKCU\Software\Microsoft\GameBar" UseNexusForGameBarEnabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\GameBar" ShowStartupPanel REG_DWORD 0
call :RB_SET "HKCU\System\GameConfigStore" GameDVR_Enabled REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" AllowGameDVR REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" AppCaptureEnabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" HistoricalCaptureEnabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" AudioCaptureEnabled REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" CursorCaptureEnabled REG_DWORD 0
:: ---- prioridades multimidia (MMCSS) e rede
call :RB_SET "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" SystemResponsiveness REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" NetworkThrottlingIndex REG_DWORD 0xffffffff
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d High /f >nul 2>&1
:: ---- agendamento de GPU por hardware (ignorado se a placa nao suportar)
call :RB_SET "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" HwSchMode REG_DWORD 2
:: ---- sem popups de teclas de aderencia nos jogos
call :RB_SET "HKCU\Control Panel\Accessibility\StickyKeys" Flags REG_SZ 506
call :RB_SET "HKCU\Control Panel\Accessibility\Keyboard Response" Flags REG_SZ 122
call :RB_SET "HKCU\Control Panel\Accessibility\ToggleKeys" Flags REG_SZ 58
:: ---- plano de energia
call :ATIVAR_PLANO
call :PLANO_AJUSTES_JOGO
if exist "%MOUSEFLAG%" call :O3_MOUSE
if not exist "%DATADIR%\opcao3.ativo" > "%DATADIR%\opcao3.ativo" echo %date% %time%
call :LOG "Opcao 3 - Otimizador do Windows (modo jogo) aplicado"
goto :eof

:: ============================================================
::  OPCAO 4 - OTIMIZADOR DO JON (maximo desempenho)
:: ============================================================
:OPCAO4
cls
echo %RGBLINE%
echo   %C1%O%C2%T%C3%I%C4%M%C5%I%C6%Z%C7%A%C1%C%C2%A%C3%O%RESET%  %C4%D%C5%O%RESET%  %C6%J%C7%O%C1%N%RESET% / %C2%X%C3%O%C4%P%C5%T%C6%I%C7%M%C1%I%C2%Z%C3%E%C4%R%RESET%
echo %RGBLINE%
echo.
if exist "%DATADIR%\opcao4.ativo" (
    echo %YELLOW%Esta opcao ja esta ativa.%RESET%
    pause
    goto MENU
)
echo MODO DESEMPENHO MAXIMO: corta o maximo de processos e servicos do Windows
echo e deixa o PC focado no que voce esta usando. Tambem aplica tudo das
echo opcoes 2 e 3. Tudo e reversivel pela opcao 5.
echo.
echo   - Efeitos visuais, animacoes e transparencia desligados (modo Melhor
echo     Desempenho), sem atraso de menus e sem atraso na inicializacao
echo   - Servicos desligados: SysMain (so se o seu disco for SSD), Windows Search
echo     (a busca do menu Iniciar fica limitada), Fax, Wallet, Telefone,
echo     Compartilhamento de Midia, Registro Remoto, Realidade Mista
echo   - Servicos passados para manual: CDP, DoSvc, TrkWks, atualizadores do
echo     Google, Edge e Adobe (so rodam quando precisam)
echo   - Svchost agrupado: muito menos processos no Gerenciador de Tarefas
echo     (vale depois de reiniciar)
echo   - Edge e Chrome param de ficar rodando em segundo plano
echo     (o navegador pode mostrar "gerenciado pela sua organizacao")
echo   - Sai da inicializacao: Discord, Steam, Spotify, Teams, Skype, OneDrive,
echo     Epic, Origin, EA, Battle.net, uTorrent, Adobe, CCleaner e similares
echo     (so o que estiver instalado; voce abre na mao quando quiser)
echo   - Tarefas agendadas extras desligadas e menos escrita no disco
echo   - Prioridade de processos, rede sem atraso e sem economia de energia
echo     no processador, PCIe, USB e disco (notebook na bateria fica normal)
echo   - Power Throttling desligado (so no desktop, para nao gastar bateria)
echo   - Opcional, com pergunta antes: desligar a hibernacao e a Inicializacao
echo     Rapida, e desligar os servicos do Xbox
echo.
echo Isto NAO e overclock e nao destrava processador travado de fabrica: o
echo Windows so consegue manter a CPU perto da frequencia maxima dela.
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
set "VBS_OFF=0"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2>nul | find "0x1" >nul 2>&1
if errorlevel 1 goto O4_SEMVBS
echo.
echo %YELLOW%A Integridade de Memoria (VBS) esta ligada no seu Windows.%RESET%
echo Desligar ela pode dar mais FPS em alguns jogos, mas reduz uma protecao de
echo seguranca do sistema. Se nao tiver certeza, responda N.
choice /c SN /n /m "Desligar a Integridade de Memoria? (S/N): "
if errorlevel 2 goto O4_SEMVBS
set "VBS_OFF=1"
:O4_SEMVBS
set "HIB_OFF=0"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled 2>nul | find "0x1" >nul 2>&1
if errorlevel 1 goto O4_SEMHIB
echo.
echo %YELLOW%Hibernacao e Inicializacao Rapida estao ligadas.%RESET%
echo Desligar apaga o arquivo hiberfil.sys (libera varios GB) e faz o PC
echo desligar de verdade, o que evita bugs acumulados de driver. Em troca
echo nao da mais para hibernar, e o PC demora um pouco mais para ligar.
echo Em notebook, pense bem: sem hibernar, a bateria pode acabar no sleep.
choice /c SN /n /m "Desligar a hibernacao? (S/N): "
if errorlevel 2 goto O4_SEMHIB
set "HIB_OFF=1"
:O4_SEMHIB
echo.
echo %YELLOW%Servicos do Xbox (XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc).%RESET%
echo Desligar economiza RAM, mas QUEBRA: login no app Xbox, Game Pass, jogos da
echo Microsoft Store com conta Xbox, Minecraft Bedrock e saves na nuvem do Xbox.
echo Se voce joga so pela Steam, Epic ou jogos offline, costuma ser seguro.
choice /c SN /n /m "Desligar os servicos do Xbox? (S/N): "
if errorlevel 2 goto O4_SEMXBOX
> "%XBOXFLAG%" echo 1
:O4_SEMXBOX
echo.
call :CONT_ZERAR
call :PONTO_RESTAURACAO
if not exist "%DATADIR%\opcao2.ativo" call :APLICAR_OPCAO2
if not exist "%DATADIR%\opcao3.ativo" call :APLICAR_OPCAO3
echo.
echo Aplicando otimizacoes avancadas, aguarde...
call :APLICAR_OPCAO4_EXTRA
if "%VBS_OFF%"=="1" call :VBS_DESLIGAR
if "%HIB_OFF%"=="1" call :HIBERNACAO_DESLIGAR
call :SYNC_AUTOSTART
echo.
echo %GREEN%Concluido! Otimizacao maxima aplicada ao sistema.%RESET%
call :RESUMO
call :STARTUP_MOSTRAR
echo %YELLOW%Reinicie o PC agora para tudo ter efeito (servicos, svchost e visual).%RESET%
pause
goto MENU

:VBS_DESLIGAR
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
> "%DATADIR%\vbs_desativado.flag" echo 1
call :LOG "Opcao 4 - Integridade de Memoria (VBS) desligada a pedido"
goto :eof

:APLICAR_OPCAO4_EXTRA
call :DETECT_HW
set "REGBK=%REGBK4%"
set "SVCBK=%SVCBK4%"
set "TKBK=%TKBK4%"
set "TKATIVO=%DATADIR%\opcao4.ativo"
echo [1/7] Efeitos visuais...
call :O4_VISUAL
echo [2/7] Servicos...
call :O4_SERVICOS
echo [3/7] Prioridades do sistema...
call :O4_SISTEMA
echo [4/7] Rede...
call :O4_REDE
echo [5/7] Navegadores...
call :O4_NAVEGADORES
echo [6/7] Tarefas agendadas extras...
call :TAREFAS_OP4 /Disable
echo [7/7] Plano de energia e processador...
call :ATIVAR_PLANO
call :CPU_TURBO
for %%P in (MicrosoftEdgeUpdate.exe GoogleUpdate.exe OneDriveStandaloneUpdater.exe) do taskkill /f /im %%P >nul 2>&1
if exist "%DATADIR%\opcao4.ativo" goto O4_REAPLICADO
echo [+] Programas da inicializacao...
call :STARTUP_LISTA
> "%DATADIR%\opcao4.ativo" echo %date% %time%
call :LOG "Opcao 4 - Otimizador do Jon aplicado - modo maximo desempenho"
goto :eof
:O4_REAPLICADO
call :LOG "Opcao 4 - Otimizador do Jon reaplicado"
goto :eof

:O4_VISUAL
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting REG_DWORD 2
call :RB_SET "HKCU\Control Panel\Desktop" UserPreferencesMask REG_BINARY 9012038010000000
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency REG_DWORD 0
call :RB_SET "HKCU\Control Panel\Desktop\WindowMetrics" MinAnimate REG_SZ 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarAnimations REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ListviewAlphaSelect REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ListviewShadow REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\DWM" EnableAeroPeek REG_DWORD 0
call :RB_SET "HKCU\Software\Microsoft\Windows\DWM" AlwaysHibernateThumbnails REG_DWORD 0
call :RB_SET "HKCU\Control Panel\Desktop" DragFullWindows REG_SZ 0
call :RB_SET "HKCU\Control Panel\Desktop" MenuShowDelay REG_SZ 0
call :RB_SET "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" StartupDelayInMSec REG_DWORD 0
goto :eof

:O4_SERVICOS
:: desligados de vez
if /i "%DISKTYPE%"=="SSD" call :SVC_SET SysMain disabled stop
call :SVC_SET WSearch disabled stop
call :SVC_SET Fax disabled stop
call :SVC_SET WMPNetworkSvc disabled stop
call :SVC_SET WalletService disabled stop
call :SVC_SET PhoneSvc disabled stop
call :SVC_SET RemoteRegistry disabled stop
call :SVC_SET SharedRealitySvc disabled stop
call :SVC_SET VacSvc disabled stop
call :SVC_SET WpcMonSvc disabled stop
:: passados para manual (so rodam quando o Windows ou o app precisar)
call :SVC_SET CDPSvc demand stop
call :SVC_SET DoSvc demand stop
call :SVC_SET TrkWks demand stop
call :SVC_SET gupdate demand stop
call :SVC_SET gupdatem demand stop
call :SVC_SET edgeupdate demand stop
call :SVC_SET edgeupdatem demand stop
call :SVC_SET AdobeARMservice demand stop
call :SVC_SET AGMService demand stop
call :SVC_SET AGSService demand stop
if exist "%XBOXFLAG%" call :O4_XBOX
goto :eof

:O4_XBOX
call :SVC_SET XblAuthManager disabled stop
call :SVC_SET XblGameSave disabled stop
call :SVC_SET XboxGipSvc disabled stop
call :SVC_SET XboxNetApiSvc disabled stop
goto :eof

:HIBERNACAO_DESLIGAR
powercfg /h off >nul 2>&1
if errorlevel 1 goto :eof
> "%HIBFLAG%" echo 1
call :LOG "Opcao 4 - Hibernacao desligada a pedido"
goto :eof

:O4_SISTEMA
call :RB_SET "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" Win32PrioritySeparation REG_DWORD 38
if not "%ISLAPTOP%"=="1" call :RB_SET "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" PowerThrottlingOff REG_DWORD 1
call :RB_SET "HKLM\SYSTEM\CurrentControlSet\Control" SvcHostSplitThresholdInKB REG_DWORD 67108864
call :RB_SET "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" DODownloadMode REG_DWORD 0
call :O4_LASTACCESS
goto :eof

:O4_REDE
for /f "usebackq tokens=*" %%K in (`reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| find "{"`) do call :O4_NAGLE "%%K"
goto :eof

:O4_NAGLE
call :RB_SET "%~1" TcpAckFrequency REG_DWORD 1
call :RB_SET "%~1" TCPNoDelay REG_DWORD 1
goto :eof

:O4_NAVEGADORES
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Edge" StartupBoostEnabled REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Microsoft\Edge" BackgroundModeEnabled REG_DWORD 0
call :RB_SET "HKLM\SOFTWARE\Policies\Google\Chrome" BackgroundModeEnabled REG_DWORD 0
goto :eof

:TAREFAS_OP4
call :TK "\Microsoft\Windows\Maintenance\WinSAT" %~1
call :TK "\Microsoft\Windows\Shell\FamilySafetyMonitor" %~1
call :TK "\Microsoft\Windows\Shell\FamilySafetyRefreshTask" %~1
call :TK "\Microsoft\Windows\Location\Notifications" %~1
call :TK "\Microsoft\Windows\Location\WindowsActionDialog" %~1
call :TK "\Microsoft\Windows\RetailDemo\CleanupOfflineContent" %~1
call :TK "\Microsoft\Windows\Speech\SpeechModelDownloadTask" %~1
call :TK "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary" %~1
call :TK "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" %~1
goto :eof

:: -------------------- CPU: dentro do que o hardware permite --------------------
:: Nao e overclock. Impede a CPU de reduzir frequencia por economia, desliga o core
:: parking e deixa o boost no modo mais agressivo permitido pelo fabricante. No notebook
:: isso vale so na tomada; na bateria o processador fica em modo economico.
:CPU_TURBO
for %%M in (ac dc) do call :CPU_TURBO_SET %%M
powercfg /setactive %PLANO_USE% >nul 2>&1
goto :eof

:CPU_TURBO_SET
if /i "%~1"=="dc" if "%ISLAPTOP%"=="1" goto CPU_BATERIA
powercfg /set%~1valueindex %PLANO_USE% SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_PROCESSOR CPMINCORES 100 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_PROCESSOR PERFEPP 0 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_PROCESSOR SYSCOOLPOL 1 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_PCIEXPRESS ASPM 0 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /set%~1valueindex %PLANO_USE% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
goto :eof
:CPU_BATERIA
powercfg /setdcvalueindex %PLANO_USE% SUB_PROCESSOR PROCTHROTTLEMIN 5 >nul 2>&1
powercfg /setdcvalueindex %PLANO_USE% SUB_PROCESSOR PERFBOOSTMODE 1 >nul 2>&1
powercfg /setdcvalueindex %PLANO_USE% SUB_PROCESSOR CPMINCORES 10 >nul 2>&1
powercfg /setdcvalueindex %PLANO_USE% SUB_PROCESSOR PERFEPP 50 >nul 2>&1
goto :eof

:CPU_PADRAO_ATUAL
for %%M in (ac dc) do call :CPU_PADRAO_SET %%M
powercfg /setactive SCHEME_CURRENT >nul 2>&1
goto :eof

:CPU_PADRAO_SET
powercfg /set%~1valueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5 >nul 2>&1
powercfg /set%~1valueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /set%~1valueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 1 >nul 2>&1
powercfg /set%~1valueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 10 >nul 2>&1
powercfg /set%~1valueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP 50 >nul 2>&1
powercfg /set%~1valueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 1 >nul 2>&1
powercfg /set%~1valueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
goto :eof

:: -------------------- plano de energia proprio do Velocity --------------------
:ATIVAR_PLANO
if exist "%PLANBACKUP%" goto PLANO_CRIAR
set "PLANO_ATUAL="
for /f "tokens=3" %%g in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" /v ActivePowerScheme 2^>nul ^| find "ActivePowerScheme"') do set "PLANO_ATUAL=%%g"
if not defined PLANO_ATUAL goto PLANO_CRIAR
if /i "%PLANO_ATUAL%"=="%VPLAN%" goto PLANO_CRIAR
> "%PLANBACKUP%" echo %PLANO_ATUAL%
:PLANO_CRIAR
powercfg /list | find /i "%VPLAN%" >nul 2>&1
if not errorlevel 1 goto PLANO_SETAR
set "BASEPLAN=e9a42b02-d5df-448d-aa00-03f14749eb61"
if "%ISLAPTOP%"=="1" set "BASEPLAN=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
powercfg /duplicatescheme %BASEPLAN% %VPLAN% >nul 2>&1
if errorlevel 1 powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c %VPLAN% >nul 2>&1
powercfg /changename %VPLAN% "Velocity XOptimizer" "Plano de desempenho maximo do Velocity XOptimizer" >nul 2>&1
:PLANO_SETAR
powercfg /setactive %VPLAN% >nul 2>&1
if errorlevel 1 goto PLANO_FALLBACK
set "PLANO_USE=%VPLAN%"
goto :eof
:PLANO_FALLBACK
set "PLANO_USE=SCHEME_CURRENT"
goto :eof

:REVERTER_PLANO
if exist "%DATADIR%\opcao3.ativo" goto :eof
if exist "%DATADIR%\opcao4.ativo" goto :eof
set "TEMPLANO=0"
powercfg /list | find /i "%VPLAN%" >nul 2>&1 && set "TEMPLANO=1"
set "PLANO_ORIG=381b4222-f694-41f0-9685-ff5bb260df2e"
if exist "%PLANBACKUP%" set /p PLANO_ORIG=<"%PLANBACKUP%"
powercfg /setactive %PLANO_ORIG% >nul 2>&1
if errorlevel 1 powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
if "%TEMPLANO%"=="1" powercfg /delete %VPLAN% >nul 2>&1
if "%TEMPLANO%"=="0" call :CPU_PADRAO_ATUAL
del "%PLANBACKUP%" >nul 2>&1
goto :eof

:RECRIAR_PLANO
set "TEMPLANO=0"
powercfg /list | find /i "%VPLAN%" >nul 2>&1 && set "TEMPLANO=1"
if "%TEMPLANO%"=="0" goto RP_FALLBACK
set "PLANO_ORIG=381b4222-f694-41f0-9685-ff5bb260df2e"
if exist "%PLANBACKUP%" set /p PLANO_ORIG=<"%PLANBACKUP%"
powercfg /setactive %PLANO_ORIG% >nul 2>&1
powercfg /delete %VPLAN% >nul 2>&1
call :ATIVAR_PLANO
goto :eof
:RP_FALLBACK
call :CPU_PADRAO_ATUAL
goto :eof

:: -------------------- hardware (notebook? SSD ou HDD?) --------------------
:DETECT_HW
if defined HWDONE goto :eof
set "ISLAPTOP=0"
set "DISKTYPE=Desconhecido"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) {1} else {0}" 2^>nul`) do set "ISLAPTOP=%%a"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "try { $n=(Get-Partition -DriveLetter ($env:SystemDrive.Substring(0,1))).DiskNumber; (Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $n }).MediaType } catch { 'Desconhecido' }" 2^>nul`) do set "DISKTYPE=%%a"
set "HWDONE=1"
goto :eof

:: -------------------- ponto de restauracao --------------------
:PONTO_RESTAURACAO
echo Criando ponto de restauracao do Windows por seguranca, aguarde...
set "RPRES=falha"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "try { Checkpoint-Computer -Description 'Velocity XOptimizer' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; 'ok' } catch { 'falha' }" 2^>nul`) do set "RPRES=%%a"
if "%RPRES%"=="ok" echo %GREEN%Ponto de restauracao criado.%RESET%
if not "%RPRES%"=="ok" echo %YELLOW%Nao foi possivel criar o ponto de restauracao, a Protecao do Sistema pode estar desligada. Seguindo mesmo assim.%RESET%
goto :eof

:: -------------------- registro: aplica e guarda o valor original --------------------
:: uso: call :RB_SET "chave" valor tipo dado   (valor sem espacos no nome)
:: o valor original (ou NONE se nao existia) e guardado uma unica vez em %REGBK%
:RB_SET
set "RB_T=NONE"
set "RB_D="
for /f "tokens=2,*" %%a in ('reg query "%~1" /v "%~2" 2^>nul ^| find "REG_"') do (
    set "RB_T=%%a"
    set "RB_D=%%b"
)
findstr /b /c:"%~1|%~2|" "%REGBK%" >nul 2>&1
if not errorlevel 1 goto RB_APLICAR
>>"%REGBK%" echo %~1^|%~2^|%RB_T%^|%RB_D%
:RB_APLICAR
reg add "%~1" /v "%~2" /t %~3 /d "%~4" /f >nul 2>&1
if errorlevel 1 (set /a RB_FAIL+=1) else (set /a RB_OK+=1)
goto :eof

:RB_RESTAURAR
if not exist "%~1" goto :eof
for /f "usebackq tokens=1,2,3,* delims=|" %%a in ("%~1") do call :RB_RESTORE1 "%%a" "%%b" "%%c" "%%d"
del "%~1" >nul 2>&1
goto :eof

:RB_RESTORE1
if /i "%~3"=="NONE" goto RB_DELETAR
reg add "%~1" /v "%~2" /t %~3 /d "%~4" /f >nul 2>&1
goto :eof
:RB_DELETAR
reg delete "%~1" /v "%~2" /f >nul 2>&1
goto :eof

:: -------------------- servicos: aplica e guarda o tipo de inicio original --------------------
:: uso: call :SVC_SET nome disabled|demand [stop]
:SVC_SET
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start >nul 2>&1
if errorlevel 1 goto :eof
findstr /b /c:"%~1|" "%SVCBK%" >nul 2>&1
if not errorlevel 1 goto SVC_APLICAR
set "S_START=0x3"
set "S_DELAY=0"
for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start 2^>nul ^| find "Start"') do set "S_START=%%v"
for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v DelayedAutostart 2^>nul ^| find "DelayedAutostart"') do set "S_DELAY=%%v"
>>"%SVCBK%" echo %~1^|%S_START%^|%S_DELAY%
:SVC_APLICAR
sc config "%~1" start= %~2 >nul 2>&1
if not errorlevel 1 set /a SV_OK+=1
if /i "%~3"=="stop" net stop "%~1" /y >nul 2>&1
goto :eof

:SVC_RESTAURAR
if not exist "%~1" goto :eof
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%~1") do call :SVC_RESTORE1 "%%a" "%%b" "%%c"
del "%~1" >nul 2>&1
goto :eof

:SVC_RESTORE1
set "SV_T=demand"
if "%~2"=="0x2" set "SV_T=auto"
if "%~2"=="0x2" if "%~3"=="0x1" set "SV_T=delayed-auto"
if "%~2"=="0x4" set "SV_T=disabled"
sc config "%~1" start= %SV_T% >nul 2>&1
if "%~2"=="0x2" net start "%~1" >nul 2>&1
goto :eof

:: -------------------- inicializacao: desativa sem apagar (igual ao Gerenciador de Tarefas) --------------------
:STARTUP_LISTA
for %%R in (HKCU HKLM HKLM32) do call :STARTUP_LISTA_R %%R
goto :eof

:STARTUP_LISTA_R
for %%N in ("Spotify" "Skype" "Skype for Desktop" "Teams" "com.squirrel.Teams.Teams" "iTunesHelper" "QuickTimePlayerHelper" "AdobeGCInvoker-1.0" "AdobeAAMUpdater-1.0" "Adobe Creative Cloud" "Acrobat Assistant 8.0" "Discord" "com.squirrel.Discord.Discord" "EpicGamesLauncher" "Origin" "EADM" "Steam" "Battle.net" "GOG Galaxy" "uTorrent" "BitTorrent" "CCleaner Smart Cleaning" "CCleaner Monitoring" "OneDrive" "Dropbox" "GoogleDriveFS" "Slack" "Telegram Desktop" "WhatsApp" "Viber" "Opera Browser Assistant" "MSTeams" "Microsoft Teams" "Zoom" "ZoomMeetings" "Overwolf" "iCloudDrive") do call :STARTUP_OFF %~1 "%%~N"
call :STARTUP_OFF_PREFIX %~1 MicrosoftEdgeAutoLaunch
call :STARTUP_OFF_PREFIX %~1 GoogleChromeAutoLaunch
goto :eof

:SU_MAP
set "SU_RUN=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
set "SU_APP=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
if /i "%~1"=="HKLM" set "SU_RUN=HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
if /i "%~1"=="HKLM" set "SU_APP=HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
if /i "%~1"=="HKLM32" set "SU_RUN=HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
if /i "%~1"=="HKLM32" set "SU_APP=HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
goto :eof

:STARTUP_OFF
call :SU_MAP %~1
reg query "%SU_RUN%" /v "%~2" >nul 2>&1
if errorlevel 1 goto :eof
reg query "%SU_APP%" /v "%~2" 2>nul | findstr /r /c:"REG_BINARY    0[37]" >nul 2>&1
if not errorlevel 1 goto :eof
findstr /b /x /c:"%~1|%~2" "%STARTUPOFF%" >nul 2>&1
if not errorlevel 1 goto SU_OFF_APLICAR
>>"%STARTUPOFF%" echo %~1^|%~2
:SU_OFF_APLICAR
reg add "%SU_APP%" /v "%~2" /t REG_BINARY /d 030000000000000000000000 /f >nul 2>&1
goto :eof

:STARTUP_OFF_PREFIX
call :SU_MAP %~1
for /f "tokens=1" %%n in ('reg query "%SU_RUN%" 2^>nul ^| findstr /i /b /c:"    %~2"') do call :STARTUP_OFF %~1 "%%n"
goto :eof

:STARTUP_RESTAURAR
if not exist "%STARTUPOFF%" goto :eof
for /f "usebackq tokens=1,* delims=|" %%a in ("%STARTUPOFF%") do call :STARTUP_ON %%a "%%b"
del "%STARTUPOFF%" >nul 2>&1
goto :eof

:STARTUP_ON
call :SU_MAP %~1
reg add "%SU_APP%" /v "%~2" /t REG_BINARY /d 020000000000000000000000 /f >nul 2>&1
goto :eof

:: ============================================================
::  FUNCOES AUXILIARES DAS OPCOES 1 A 4
:: ============================================================

:: -------------------- contadores do resumo final --------------------
:CONT_ZERAR
set "RB_OK=0"
set "RB_FAIL=0"
set "SV_OK=0"
set "TK_OK=0"
goto :eof

:RESUMO
echo.
echo %TB%Resumo:%RESET%
echo   Ajustes de registro aplicados: %RB_OK%
echo   Servicos ajustados: %SV_OK%
echo   Tarefas agendadas desativadas agora: %TK_OK%
if %RB_FAIL% GTR 0 echo %YELLOW%  %RB_FAIL% ajuste(s) foram ignorados pelo Windows, normal em versoes diferentes.%RESET%
goto :eof

:: -------------------- registro: so mexe se a chave ja existir --------------------
:RB_SET_EXISTE
reg query "%~1" >nul 2>&1
if errorlevel 1 goto :eof
call :RB_SET %*
goto :eof

:: -------------------- tarefas agendadas: desativa guardando o estado original --------------------
:: uso: call :TK "\caminho\da\tarefa" /Disable   (ou /Enable)
:: so guarda e desativa a tarefa se ela estava ligada. Ao desfazer, so volta o que era seu.
:TK
if /i "%~2"=="/Enable" goto TK_LIGAR
schtasks /Query /TN "%~1" >nul 2>&1
if errorlevel 1 goto :eof
schtasks /Query /TN "%~1" /XML 2>nul | find /i "<Enabled>false</Enabled>" >nul 2>&1
if not errorlevel 1 goto :eof
if exist "%TKBK%" goto TK_GRAVAR
if exist "%TKATIVO%" goto TK_DESLIGAR
:TK_GRAVAR
findstr /x /c:"%~1" "%TKBK%" >nul 2>&1
if errorlevel 1 >>"%TKBK%" echo %~1
:TK_DESLIGAR
schtasks /Change /TN "%~1" /Disable >nul 2>&1
if not errorlevel 1 set /a TK_OK+=1
goto :eof
:TK_LIGAR
schtasks /Change /TN "%~1" /Enable >nul 2>&1
goto :eof

:TK_RESTAURAR
if not exist "%~1" goto :eof
for /f "usebackq delims=" %%T in ("%~1") do schtasks /Change /TN "%%T" /Enable >nul 2>&1
del "%~1" >nul 2>&1
goto :eof

:: -------------------- opcao 3: plano de energia e mouse --------------------
:: so mexe no plano proprio do Velocity (ele e apagado ao desfazer), nunca no seu plano
:PLANO_AJUSTES_JOGO
if /i "%PLANO_USE%"=="SCHEME_CURRENT" goto :eof
powercfg /setacvalueindex %PLANO_USE% SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setacvalueindex %PLANO_USE% SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setacvalueindex %PLANO_USE% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setacvalueindex %PLANO_USE% SUB_PCIEXPRESS ASPM 0 >nul 2>&1
powercfg /setacvalueindex %PLANO_USE% SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setactive %PLANO_USE% >nul 2>&1
goto :eof

:O3_MOUSE
call :RB_SET "HKCU\Control Panel\Mouse" MouseSpeed REG_SZ 0
call :RB_SET "HKCU\Control Panel\Mouse" MouseThreshold1 REG_SZ 0
call :RB_SET "HKCU\Control Panel\Mouse" MouseThreshold2 REG_SZ 0
rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True
goto :eof

:: -------------------- opcao 4: ultimo acesso do NTFS guarda o valor original --------------------
:O4_LASTACCESS
if exist "%LASTACCBK%" goto LA_APLICAR
if exist "%DATADIR%\opcao4.ativo" goto LA_APLICAR
set "LA_ORIG=2"
for /f "tokens=3" %%v in ('fsutil behavior query disablelastaccess 2^>nul') do set "LA_ORIG=%%v"
echo %LA_ORIG%| findstr /r /x "[0-3]" >nul 2>&1
if errorlevel 1 set "LA_ORIG=2"
> "%LASTACCBK%" echo %LA_ORIG%
:LA_APLICAR
fsutil behavior set disablelastaccess 1 >nul 2>&1
goto :eof

:O4_LASTACCESS_REV
set "LA_ORIG=2"
if exist "%LASTACCBK%" set /p LA_ORIG=<"%LASTACCBK%"
fsutil behavior set disablelastaccess %LA_ORIG% >nul 2>&1
del "%LASTACCBK%" >nul 2>&1
goto :eof

:: -------------------- opcao 4: mostra o que saiu da inicializacao --------------------
:STARTUP_MOSTRAR
if not exist "%STARTUPOFF%" goto :eof
echo.
echo %TB%Programas fora da inicializacao (voltam pela opcao 5):%RESET%
for /f "usebackq tokens=1,* delims=|" %%a in ("%STARTUPOFF%") do echo   - %%b
goto :eof

:: ============================================================
::  OPCAO 6 - REDES SOCIAIS
:: ============================================================
:OPCAO6
cls
echo %RGBLINE%
echo.
echo   %C1%R%C2%E%C3%D%C4%E%C5%S%RESET%  %C6%S%C7%O%C1%C%C2%I%C3%A%C4%I%C5%S%RESET%  %C6%D%C7%O%RESET%  %C1%D%C2%O%C3%N%C4%O%RESET%
echo.
echo %RGBLINE%
echo.
echo   %TB%TikTok: @surejonn (jonzinhoXD)%RESET%
echo   %WHT%Link: https://www.tiktok.com/@surejonn%RESET%
echo.
echo   Velocity XOptimizer v-0.2 - by JonzinhoXD
echo   Suporte: Windows 10 / Windows 11
echo.
echo   Acompanhe as novidades do Velocity XOptimizer no perfil do dono.
echo.
echo   %TB%[A]%RESET% Abrir o perfil no navegador
echo   %TB%[C]%RESET% Copiar o @ para a area de transferencia
echo   %TB%[V]%RESET% Voltar ao menu
echo.
choice /c ACV /n /m "Escolha uma opcao: "
if errorlevel 3 goto MENU
if errorlevel 2 goto O6_COPIAR
start "" "https://www.tiktok.com/@surejonn"
goto OPCAO6
:O6_COPIAR
echo @surejonn| clip
echo %GREEN%Copiado: @surejonn%RESET%
timeout /t 2 >nul
goto OPCAO6

:: ============================================================
::  OPCAO 7 - NOVIDADES DA ATUALIZACAO
:: ============================================================
:OPCAO7
cls
echo %RGBLINE%
echo   %TB%NOVIDADES DA ATUALIZACAO V-0.2%RESET%
echo %RGBLINE%
echo.
echo %TB%Opcao 1 - Limpeza%RESET%
echo   Pergunta se quer fechar os navegadores abertos para limpar tudo, limpa
echo   tambem Vivaldi, Opera GX, Discord, Steam, Spotify e Microsoft Store, e
echo   pula o Windows Update se ele estiver instalando algo. Limpeza profunda
echo   inclui cache de shaders. Pergunta a parte se apaga o Windows.old.
echo   Mostra o espaco liberado e o espaco livre.
echo.
echo %TB%Opcao 2 - Segundo plano%RESET%
echo   Mais telemetria, Recall e coleta de digitacao desligados. Ao desfazer,
echo   so volta o que estava ligado antes: tarefas que voce ja tinha desligado
echo   continuam desligadas. Mostra um resumo do que foi aplicado.
echo.
echo %TB%Opcao 3 - Otimizador do Windows%RESET%
echo   Plano de energia com USB, PCIe e disco sem economia, e opcao de desligar
echo   a aceleracao do mouse. Plano proprio do Velocity, seu plano original
echo   volta ao desativar.
echo.
echo %TB%Opcao 4 - Otimizador do Jon%RESET%
echo   Mostra o progresso e lista o que saiu da inicializacao. Power Throttling
echo   so no desktop, SysMain so desliga com SSD confirmado e o valor original
echo   do ultimo acesso do NTFS volta ao desfazer. Corrigida a economia de USB.
echo   Opcional, com pergunta: desligar hibernacao e servicos do Xbox.
echo.
echo %TB%Opcao 5 - Desativar%RESET%
echo   Mostra o que esta ativo e desde quando, abre o historico e a Restauracao
echo   do Sistema. Volta os valores ORIGINAIS do seu PC, nao valores padrao.
echo.
echo %TB%Opcao 6 - Redes sociais%RESET%
echo   Abre o perfil no navegador ou copia o @.
echo.
echo %TB%Seguranca%RESET%
echo   Ponto de restauracao do Windows antes de aplicar as opcoes 2, 3 e 4.
echo.
pause
goto MENU

:: ============================================================
::  OPCAO 5 - DESATIVAR
:: ============================================================
:MENU_DESATIVAR
cls
echo %RGBLINE%
echo   %TB%DESATIVAR OPCOES%RESET%
echo %RGBLINE%
echo.
set "ST2=%RED%desativado%RESET%"
set "ST3=%RED%desativado%RESET%"
set "ST4=%RED%desativado%RESET%"
call :ST_LER 2
call :ST_LER 3
call :ST_LER 4
echo  2 - Apps de segundo plano ......... %ST2%
echo  3 - Otimizador do Windows ......... %ST3%
echo  4 - Otimizador do Jon ............. %ST4%
echo.
echo  %TB%[2]%RESET% Desativar a opcao 2
echo  %TB%[3]%RESET% Desativar a opcao 3
echo  %TB%[4]%RESET% Desativar a opcao 4
echo  %TB%[0]%RESET% Desativar TODAS as opcoes ativas
echo  %TB%[L]%RESET% Ver o historico das ultimas acoes
echo  %TB%[R]%RESET% Abrir a Restauracao do Sistema do Windows
echo  %TB%[V]%RESET% Voltar ao menu principal
echo.
choice /c 0234LRV /n /m "Escolha uma opcao: "
if errorlevel 7 goto MENU
if errorlevel 6 goto ABRIR_RESTAURACAO
if errorlevel 5 goto VER_LOG
if errorlevel 4 goto REVERT4
if errorlevel 3 goto REVERT3
if errorlevel 2 goto REVERT2
goto REVERTALL

:ST_LER
if not exist "%DATADIR%\opcao%~1.ativo" goto :eof
set "STD="
set /p STD=<"%DATADIR%\opcao%~1.ativo"
set "ST%~1=%GREEN%ATIVO%RESET% desde %STD%"
goto :eof

:VER_LOG
cls
echo %RGBLINE%
echo   %TB%HISTORICO - ULTIMAS 25 ACOES%RESET%
echo %RGBLINE%
echo.
powershell -NoProfile -Command "Get-Content -LiteralPath '%LOGFILE%' -Tail 25"
echo.
pause
goto MENU_DESATIVAR

:ABRIR_RESTAURACAO
echo Abrindo a Restauracao do Sistema do Windows...
start "" rstrui.exe
timeout /t 2 >nul
goto MENU_DESATIVAR

:REVERTALL
if exist "%DATADIR%\opcao4.ativo" call :REVERTER_OPCAO4
if exist "%DATADIR%\opcao3.ativo" call :REVERTER_OPCAO3
if exist "%DATADIR%\opcao2.ativo" call :REVERTER_OPCAO2
call :SYNC_AUTOSTART
echo.
echo %GREEN%Todas as otimizacoes foram desativadas e os valores originais voltaram.%RESET%
echo Reinicie o PC para tudo voltar ao normal.
pause
goto MENU_DESATIVAR

:REVERT2
if exist "%DATADIR%\opcao2.ativo" (
    call :REVERTER_OPCAO2
    call :SYNC_AUTOSTART
    echo %GREEN%Opcao 2 desativada.%RESET%
) else (
    echo Essa opcao nao esta ativa.
)
pause
goto MENU_DESATIVAR

:REVERT3
if exist "%DATADIR%\opcao3.ativo" (
    call :REVERTER_OPCAO3
    call :SYNC_AUTOSTART
    echo %GREEN%Opcao 3 desativada.%RESET%
) else (
    echo Essa opcao nao esta ativa.
)
pause
goto MENU_DESATIVAR

:REVERT4
if exist "%DATADIR%\opcao4.ativo" (
    call :REVERTER_OPCAO4
    call :SYNC_AUTOSTART
    echo %GREEN%Opcao 4 desativada. Reinicie o PC para concluir.%RESET%
) else (
    echo Essa opcao nao esta ativa.
)
pause
goto MENU_DESATIVAR

:REVERTER_OPCAO2
if not exist "%REGBK2%" call :LEGADO_OP2
call :RB_RESTAURAR "%REGBK2%"
if exist "%TKBK2%" (call :TK_RESTAURAR "%TKBK2%") else (call :TAREFAS_OP2 /Enable)
if not exist "%SVCBK2%" call :SVC_PADRAO_OP2
call :SVC_RESTAURAR "%SVCBK2%"
del "%DATADIR%\opcao2.ativo" >nul 2>&1
call :LOG "Opcao 2 - Apps de segundo plano reativados (revertido)"
goto :eof

:REVERTER_OPCAO3
if not exist "%REGBK3%" call :LEGADO_OP3
call :RB_RESTAURAR "%REGBK3%"
if exist "%MOUSEFLAG%" rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True
del "%MOUSEFLAG%" >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d Medium /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d Normal /f >nul 2>&1
del "%DATADIR%\opcao3.ativo" >nul 2>&1
call :REVERTER_PLANO
call :LOG "Opcao 3 - Otimizador do Windows revertido"
goto :eof

:REVERTER_OPCAO4
if not exist "%REGBK4%" call :LEGADO_OP4
call :RB_RESTAURAR "%REGBK4%"
call :O4_LASTACCESS_REV
if exist "%TKBK4%" (call :TK_RESTAURAR "%TKBK4%") else (call :TAREFAS_OP4 /Enable)
if not exist "%SVCBK4%" call :SVC_PADRAO_OP4
call :SVC_RESTAURAR "%SVCBK4%"
call :STARTUP_RESTAURAR
if exist "%STARTUPBACKUP%" call :RESTAURAR_STARTUP
if exist "%DATADIR%\vbs_desativado.flag" reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
del "%DATADIR%\vbs_desativado.flag" >nul 2>&1
if exist "%HIBFLAG%" powercfg /h on >nul 2>&1
del "%HIBFLAG%" >nul 2>&1
del "%XBOXFLAG%" >nul 2>&1
del "%DATADIR%\opcao4.ativo" >nul 2>&1
if exist "%DATADIR%\opcao3.ativo" call :RECRIAR_PLANO
if not exist "%DATADIR%\opcao3.ativo" call :REVERTER_PLANO
call :LOG "Opcao 4 - Otimizador do Jon revertido"
goto :eof

:: -------------------- compatibilidade com quem aplicou a v-0.1 --------------------
:LEGADO_OP2
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
goto :eof

:LEGADO_OP3
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f >nul 2>&1
goto :eof

:LEGADO_OP4
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v ShowStartupPanel /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /f >nul 2>&1
for /f "usebackq tokens=*" %%K in (`reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| find "{"`) do call :LEGADO_NAGLE "%%K"
goto :eof

:LEGADO_NAGLE
reg delete "%~1" /v TcpAckFrequency /f >nul 2>&1
reg delete "%~1" /v TCPNoDelay /f >nul 2>&1
goto :eof

:SVC_PADRAO_OP2
sc config DiagTrack start= auto >nul 2>&1
net start DiagTrack >nul 2>&1
sc config dmwappushservice start= demand >nul 2>&1
sc config RetailDemo start= demand >nul 2>&1
sc config MapsBroker start= delayed-auto >nul 2>&1
net start MapsBroker >nul 2>&1
goto :eof

:SVC_PADRAO_OP4
sc config SysMain start= auto >nul 2>&1
net start SysMain >nul 2>&1
sc config WSearch start= delayed-auto >nul 2>&1
net start WSearch >nul 2>&1
sc config Fax start= demand >nul 2>&1
sc config WMPNetworkSvc start= demand >nul 2>&1
sc config WalletService start= demand >nul 2>&1
sc config PhoneSvc start= demand >nul 2>&1
goto :eof

:RESTAURAR_STARTUP
for /f "usebackq tokens=1,2,* delims=|" %%a in ("%STARTUPBACKUP%") do reg add "%%a\Software\Microsoft\Windows\CurrentVersion\Run" /v "%%b" /t REG_SZ /d "%%c" /f >nul 2>&1
del "%STARTUPBACKUP%" >nul 2>&1
goto :eof

:: ============================================================
::  SINCRONIZAR TAREFA DE INICIALIZACAO (login)
:: ============================================================
:SYNC_AUTOSTART
if exist "%DATADIR%\opcao2.ativo" goto SYNC_CREATE
if exist "%DATADIR%\opcao3.ativo" goto SYNC_CREATE
if exist "%DATADIR%\opcao4.ativo" goto SYNC_CREATE
schtasks /Delete /TN "%TASKNAME%" /F >nul 2>&1
goto :eof
:SYNC_CREATE
schtasks /Create /TN "%TASKNAME%" /TR "\"%~f0\" /auto" /SC ONLOGON /RL HIGHEST /F >nul 2>&1
goto :eof

:: ============================================================
::  LOG
:: ============================================================
:LOG
echo [%date% %time%] %~1>> "%LOGFILE%"
goto :eof

:: ============================================================
::  SAIR
:: ============================================================
:SAIR
call :SYNC_AUTOSTART
cls
echo.
echo Obrigado por usar o Velocity XOptimizer!
set "ANYACTIVE=0"
if exist "%DATADIR%\opcao2.ativo" set "ANYACTIVE=1"
if exist "%DATADIR%\opcao3.ativo" set "ANYACTIVE=1"
if exist "%DATADIR%\opcao4.ativo" set "ANYACTIVE=1"
if "%ANYACTIVE%"=="1" (
    echo.
    echo As otimizacoes ativas serao reaplicadas automaticamente a cada
    echo login no Windows, garantindo que continuem valendo.
)
echo.
timeout /t 2 >nul
exit /b
