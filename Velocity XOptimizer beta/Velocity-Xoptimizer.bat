@echo off
:: ============================================================
::  Velocity XOptimizer - v0.1
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
echo %WHT% 1 - Limpar arquivos temporarios%RESET%
echo %WHT% 2 - Aplicativos em segundo plano do Windows sem utilidade%RESET%
echo.
echo %TB%OTIMIZACAO%RESET%
echo %WHT% 3 - Otimizador do Windows%RESET%
echo %WHT% 4 - Otimizador do Jon%RESET%
echo.
echo %TB%OUTROS%RESET%
echo %WHT% 5 - Desativar opcoes%RESET%
echo %WHT% 6 - Redes sociais%RESET%
echo %WHT% 7 - Sair%RESET%
echo.
echo %BLUELINE%
if "%WINVER%"=="10" (
    echo %WHT% by: %C2%J%C3%o%C4%n%C5%z%C6%i%C7%n%C1%h%C2%o%C3%X%C4%D%WHT%   %GREEN%v-0.1%WHT%   suporte: %GREEN%Windows 10%WHT% / Windows 11%RESET%
) else if "%WINVER%"=="11" (
    echo %WHT% by: %C2%J%C3%o%C4%n%C5%z%C6%i%C7%n%C1%h%C2%o%C3%X%C4%D%WHT%   %GREEN%v-0.1%WHT%   suporte: Windows 10 / %GREEN%Windows 11%RESET%
) else (
    echo %WHT% by: %C2%J%C3%o%C4%n%C5%z%C6%i%C7%n%C1%h%C2%o%C3%X%C4%D%WHT%   %GREEN%v-0.1%WHT%   %RED%NAO TEMOS SUPORTE PRA O SEU SISTEMA OPERACIONAL!%RESET%
)
echo %BLUELINE%
<nul set /p "=%WHT%"
choice /c 1234567 /n /m "Escolha uma opcao: "
set "MENUKEY=%errorlevel%"
<nul set /p "=%RESET%"
if "%MENUKEY%"=="7" goto SAIR
if "%MENUKEY%"=="6" goto OPCAO6
if "%MENUKEY%"=="5" goto MENU_DESATIVAR
if "%MENUKEY%"=="4" goto OPCAO4
if "%MENUKEY%"=="3" goto OPCAO3
if "%MENUKEY%"=="2" goto OPCAO2
if "%MENUKEY%"=="1" goto OPCAO1
goto MENU

:: ============================================================
::  OPCAO 1 - LIMPAR ARQUIVOS TEMPORARIOS
:: ============================================================
:OPCAO1
cls
echo %RGBLINE%
echo   %GREEN%LIMPAR ARQUIVOS TEMPORARIOS?%RESET%
echo %RGBLINE%
echo.
echo Isso vai limpar os arquivos temporarios do sistema (%%TEMP%%, C:\Windows\Temp
echo e a Lixeira). Fotos, documentos, videos e outros arquivos pessoais NAO
echo serao apagados.
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
echo.
echo Limpando arquivos temporarios, aguarde...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
call :LOG "Opcao 1 - Limpeza de arquivos temporarios e lixeira executada"
echo.
echo %GREEN%Concluido! Arquivos temporarios e lixeira foram limpos.%RESET%
pause
goto MENU

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
echo Vai desativar apps e tarefas do Windows sem utilidade que ficam
echo consumindo memoria RAM em segundo plano. Apps de seguranca (Firewall,
echo Windows Defender, Central de Seguranca) NAO serao desativados.
echo.
echo Sera desativado:
echo   - Apps em segundo plano (todos, via configuracao do Windows)
echo   - Tarefas de telemetria/diagnostico (Compatibility Appraiser,
echo     Customer Experience Improvement Program, Disk Diagnostic,
echo     Feedback, Windows Error Reporting)
echo   - Servicos: DiagTrack, dmwappushservice, RetailDemo, MapsBroker
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
call :APLICAR_OPCAO2
call :SYNC_AUTOSTART
echo.
echo %GREEN%Concluido! Apps de segundo plano sem utilidade foram desativados.%RESET%
pause
goto MENU

:APLICAR_OPCAO2
echo Aplicando otimizacoes, aguarde...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
net stop DiagTrack >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
net stop dmwappushservice >nul 2>&1
sc config RetailDemo start= disabled >nul 2>&1
net stop RetailDemo >nul 2>&1
sc config MapsBroker start= disabled >nul 2>&1
net stop MapsBroker >nul 2>&1
if not exist "%DATADIR%\opcao2.ativo" > "%DATADIR%\opcao2.ativo" echo %date% %time%
call :LOG "Opcao 2 - Apps de segundo plano desativados"
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
echo Vai ativar o Modo de Jogo do Windows e desativar recursos nativos que
echo reduzem o FPS (Game DVR, gravacao em segundo plano, etc), alem de
echo ajustar a prioridade de CPU/rede para jogos e mudar o plano de energia
echo para Alto Desempenho.
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU
call :APLICAR_OPCAO3
call :SYNC_AUTOSTART
echo.
echo %GREEN%Concluido! Modo de jogo ativado e ajustes de desempenho aplicados.%RESET%
echo Reinicie o PC para o agendamento de GPU ter efeito completo.
pause
goto MENU

:APLICAR_OPCAO3
echo Aplicando otimizacoes de jogo, aguarde...
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
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
echo Isso vai reduzir ao maximo os processos do Windows em segundo plano,
echo deixando o PC com muito mais FPS nos jogos: desativa efeitos visuais e
echo animacoes, mais servicos que so gastam RAM/CPU a toa (SysMain, Windows
echo Search, Fax, Wallet, Telefone, Compartilhamento de Midia), programas de
echo inicializacao desnecessarios (Spotify, Skype, Teams, iTunes, QuickTime,
echo Adobe, Discord, Epic Games, Origin, uTorrent, CCleaner - so o que estiver
echo realmente instalado), ajusta a prioridade de processos e rede, desliga a
echo suspensao seletiva de USB e o compartilhamento de atualizacoes (P2P), e
echo mantem a CPU sempre no maior desempenho/turbo permitido por ela (sem
echo deixar cair a frequencia a toa - isso NAO e overclock, e nao desbloqueia
echo processadores travados de fabrica: o Windows nao tem acesso a esse tipo
echo de trava, que fica no proprio chip). Tambem aplica tudo das opcoes 2 e 3.
echo.
choice /c SN /n /m "Deseja continuar? (S/N): "
if errorlevel 2 goto MENU

if not exist "%DATADIR%\opcao2.ativo" call :APLICAR_OPCAO2
if not exist "%DATADIR%\opcao3.ativo" call :APLICAR_OPCAO3

echo.
echo Aplicando otimizacoes avancadas, aguarde...
call :APLICAR_OPCAO4_EXTRA
call :SYNC_AUTOSTART
echo.
echo %GREEN%Concluido! Otimizacao maxima aplicada ao sistema.%RESET%
pause
goto MENU

:APLICAR_OPCAO4_EXTRA
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
sc config SysMain start= disabled >nul 2>&1
net stop SysMain >nul 2>&1
sc config WSearch start= disabled >nul 2>&1
net stop WSearch >nul 2>&1
sc config Fax start= disabled >nul 2>&1
net stop Fax >nul 2>&1
sc config WMPNetworkSvc start= disabled >nul 2>&1
net stop WMPNetworkSvc >nul 2>&1
sc config WalletService start= disabled >nul 2>&1
net stop WalletService >nul 2>&1
sc config PhoneSvc start= disabled >nul 2>&1
net stop PhoneSvc >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v ShowStartupPanel /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
for /f "usebackq tokens=*" %%K in (`reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "Interfaces\"`) do (
    reg add "%%K" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
)
:: -------------------- "turbo" de CPU dentro do que o hardware permite --------------------
:: Isto NAO e overclock e NAO desbloqueia processadores travados (isso e uma trava de
:: fabrica no proprio chip, fora do alcance do Windows/CMD). O que faz de verdade: impede
:: a CPU de reduzir a frequencia por economia de energia, desliga o "core parking" (nucleos
:: hibernados) e deixa o boost/turbo no modo mais agressivo permitido pelo fabricante -
:: ou seja, o processador passa mais tempo perto da frequencia maxima dele.
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7d6-a5b4-4a99-a2a1-91a5cd4a9e2c 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7d6-a5b4-4a99-a2a1-91a5cd4a9e2c 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
if not exist "%DATADIR%\opcao4.ativo" (
    del "%STARTUPBACKUP%" >nul 2>&1
    call :BACKUP_REMOVE_STARTUP HKCU Spotify
    call :BACKUP_REMOVE_STARTUP HKCU Skype
    call :BACKUP_REMOVE_STARTUP HKCU Teams
    call :BACKUP_REMOVE_STARTUP HKCU iTunesHelper
    call :BACKUP_REMOVE_STARTUP HKCU QuickTimePlayerHelper
    call :BACKUP_REMOVE_STARTUP HKCU AdobeGCInvoker-1.0
    call :BACKUP_REMOVE_STARTUP HKCU Discord
    call :BACKUP_REMOVE_STARTUP HKCU "com.squirrel.Discord.Discord"
    call :BACKUP_REMOVE_STARTUP HKCU EpicGamesLauncher
    call :BACKUP_REMOVE_STARTUP HKCU Origin
    call :BACKUP_REMOVE_STARTUP HKCU uTorrent
    call :BACKUP_REMOVE_STARTUP HKCU "CCleaner Smart Cleaning"
    call :BACKUP_REMOVE_STARTUP HKLM Spotify
    call :BACKUP_REMOVE_STARTUP HKLM Skype
    call :BACKUP_REMOVE_STARTUP HKLM Teams
    call :BACKUP_REMOVE_STARTUP HKLM iTunesHelper
    call :BACKUP_REMOVE_STARTUP HKLM QuickTimePlayerHelper
    call :BACKUP_REMOVE_STARTUP HKLM AdobeGCInvoker-1.0
    call :BACKUP_REMOVE_STARTUP HKLM Discord
    call :BACKUP_REMOVE_STARTUP HKLM EpicGamesLauncher
    call :BACKUP_REMOVE_STARTUP HKLM Origin
    call :BACKUP_REMOVE_STARTUP HKLM uTorrent
    call :BACKUP_REMOVE_STARTUP HKLM "CCleaner Smart Cleaning"
    > "%DATADIR%\opcao4.ativo" echo %date% %time%
    call :LOG "Opcao 4 - Otimizador do Jon aplicado - modo maximo desempenho"
) else (
    call :LOG "Opcao 4 - Otimizador do Jon reaplicado"
)
goto :eof

:BACKUP_REMOVE_STARTUP
reg query "%~1\Software\Microsoft\Windows\CurrentVersion\Run" /v "%~2" >nul 2>&1
if errorlevel 1 goto :eof
for /f "skip=2 tokens=1,2,*" %%a in ('reg query "%~1\Software\Microsoft\Windows\CurrentVersion\Run" /v "%~2" 2^>nul') do echo %~1^|%~2^|%%c>> "%STARTUPBACKUP%"
reg delete "%~1\Software\Microsoft\Windows\CurrentVersion\Run" /v "%~2" /f >nul 2>&1
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
echo.
echo Esse menu e apenas informativo, mostrando o perfil do dono do
echo Velocity XOptimizer. Nao ha nada para configurar por aqui.
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
set "ST2=NAO ATIVADO"
set "ST3=NAO ATIVADO"
set "ST4=NAO ATIVADO"
if exist "%DATADIR%\opcao2.ativo" set /p ST2=<"%DATADIR%\opcao2.ativo"
if exist "%DATADIR%\opcao3.ativo" set /p ST3=<"%DATADIR%\opcao3.ativo"
if exist "%DATADIR%\opcao4.ativo" set /p ST4=<"%DATADIR%\opcao4.ativo"
echo  2 - Apps de segundo plano ......... %ST2%
echo  3 - Otimizador do Windows ......... %ST3%
echo  4 - Otimizador do Jon ............. %ST4%
echo.
echo  0 - Desativar TODAS as opcoes ativas
echo  V - Voltar ao menu principal
echo.
echo (historico completo em VelocityXOptimizer_Data\log.txt)
echo.
set /p ESCOLHA="Escolha uma opcao: "
if /i "%ESCOLHA%"=="V" goto MENU
if "%ESCOLHA%"=="0" goto REVERTALL
if "%ESCOLHA%"=="2" goto REVERT2
if "%ESCOLHA%"=="3" goto REVERT3
if "%ESCOLHA%"=="4" goto REVERT4
goto MENU_DESATIVAR

:REVERTALL
if exist "%DATADIR%\opcao2.ativo" call :REVERTER_OPCAO2
if exist "%DATADIR%\opcao3.ativo" call :REVERTER_OPCAO3
if exist "%DATADIR%\opcao4.ativo" call :REVERTER_OPCAO4
call :SYNC_AUTOSTART
echo.
echo %GREEN%Todas as otimizacoes foram desativadas.%RESET%
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
    echo %GREEN%Opcao 4 desativada.%RESET%
) else (
    echo Essa opcao nao esta ativa.
)
pause
goto MENU_DESATIVAR

:REVERTER_OPCAO2
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Autochk\Proxy" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /Enable >nul 2>&1
sc config DiagTrack start= auto >nul 2>&1
net start DiagTrack >nul 2>&1
sc config dmwappushservice start= demand >nul 2>&1
net start dmwappushservice >nul 2>&1
sc config RetailDemo start= demand >nul 2>&1
sc config MapsBroker start= auto >nul 2>&1
net start MapsBroker >nul 2>&1
del "%DATADIR%\opcao2.ativo" >nul 2>&1
call :LOG "Opcao 2 - Apps de segundo plano reativados (revertido)"
goto :eof

:REVERTER_OPCAO3
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f >nul 2>&1
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
del "%DATADIR%\opcao3.ativo" >nul 2>&1
call :LOG "Opcao 3 - Otimizador do Windows revertido"
goto :eof

:REVERTER_OPCAO4
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f >nul 2>&1
sc config SysMain start= auto >nul 2>&1
net start SysMain >nul 2>&1
sc config WSearch start= auto >nul 2>&1
net start WSearch >nul 2>&1
sc config Fax start= demand >nul 2>&1
sc config WMPNetworkSvc start= demand >nul 2>&1
sc config WalletService start= demand >nul 2>&1
sc config PhoneSvc start= demand >nul 2>&1
net start PhoneSvc >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v ShowStartupPanel /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 1 /f >nul 2>&1
for /f "usebackq tokens=*" %%K in (`reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "Interfaces\"`) do (
    reg delete "%%K" /v TcpAckFrequency /f >nul 2>&1
    reg delete "%%K" /v TCPNoDelay /f >nul 2>&1
)
:: -------------------- desfazer o "turbo" de CPU (volta aos valores padrao do Windows) --------------------
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 1 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7d6-a5b4-4a99-a2a1-91a5cd4a9e2c 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7d6-a5b4-4a99-a2a1-91a5cd4a9e2c 1 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
if exist "%STARTUPBACKUP%" call :RESTAURAR_STARTUP
del "%DATADIR%\opcao4.ativo" >nul 2>&1
call :LOG "Opcao 4 - Otimizador do Jon revertido"
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
