@echo off
chcp 65001 >nul
rem His.CoreHash 한 번 (창 없이 -nullrhi) — 언리얼 안 core 해시 = historia_run 해시 (TASK_거시연결 U1·U2). 언리얼 빌드 뒤 매번.
rem 쓰임: Tools\his_core_hash.bat [엔진 폴더]   (없으면 UE_ROOT → E:\Epic\UE_5.8)   · 끝 코드 0 = 같음 · 로그 Saved\Logs\his_corehash.log
setlocal
set "PROJ=%~dp0.."
for %%I in ("%PROJ%") do set "PROJ=%%~fI"
set "UE=%~1"
if "%UE%"=="" set "UE=%UE_ROOT%"
if "%UE%"=="" set "UE=E:\Epic\UE_5.8"
set "LOG=%PROJ%\Saved\Logs\his_corehash.log"
"%UE%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" "%PROJ%\Historia.uproject" -nullrhi -unattended -nosplash -nop4 -ExecCmds="Automation RunTests His.CoreHash;Quit" -log -abslog="%LOG%" >nul 2>&1
findstr /c:"Result={Success} Name={CoreHash}" "%LOG%" >nul
if errorlevel 1 (
  echo [his_core_hash] 실패 — %LOG%
  powershell -NoProfile -Command "Select-String -Encoding utf8 -Path '%LOG%' -Pattern 'LogAutomationController: (Error|.*[0-9a-f]{64})' | %% { $_.Line }"
  exit /b 1
)
powershell -NoProfile -Command "Select-String -Encoding utf8 -Path '%LOG%' -Pattern 'LogAutomationController: .*[0-9a-f]{64}' | %% { $_.Line }"
echo [his_core_hash] 같음
endlocal
