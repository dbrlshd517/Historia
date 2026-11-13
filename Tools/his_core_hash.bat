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
rem 무거운 판은 메모리 보고 띄움(CLAUDE.md · 사람 11-12): %LOCALAPPDATA%\Hmb\hmb_run_lock.py 로 줄 섬 — 그림 없는 판 4 GB. 콘솔 창 없이(-log 안 씀 · 로그는 -abslog 파일).
set "LOCK=%LOCALAPPDATA%\Hmb\hmb_run_lock.py"
if exist "%LOCK%" (
  py "%LOCK%" run --name "Historia his_corehash" --need 4 -- "%UE%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" "%PROJ%\Historia.uproject" -nullrhi -unattended -nosplash -nop4 -ExecCmds="Automation RunTests His.CoreHash;Quit" -abslog="%LOG%" >nul 2>&1
) else (
  echo [his_core_hash] 주의: %LOCK% 없음 — 줄 안 서고 바로 띄움 ^(미시 Tools\Python\hmb_run_lock.py 를 한 번 돌리면 생김^)
  "%UE%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" "%PROJ%\Historia.uproject" -nullrhi -unattended -nosplash -nop4 -ExecCmds="Automation RunTests His.CoreHash;Quit" -abslog="%LOG%" >nul 2>&1
)
findstr /c:"Result={Success} Name={CoreHash}" "%LOG%" >nul
if errorlevel 1 (
  echo [his_core_hash] 실패 — %LOG%
  powershell -NoProfile -Command "Select-String -Encoding utf8 -Path '%LOG%' -Pattern 'LogAutomationController: (Error|.*[0-9a-f]{64})' | %% { $_.Line }"
  exit /b 1
)
powershell -NoProfile -Command "Select-String -Encoding utf8 -Path '%LOG%' -Pattern 'LogAutomationController: .*[0-9a-f]{64}' | %% { $_.Line }"
echo [his_core_hash] 같음
endlocal
