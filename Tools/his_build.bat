@echo off
chcp 65001 >nul
rem 언리얼 에디터 빌드 + His.CoreHash (TASK_거시연결 U2). 빌드 → 해시 시험까지 한 줄.
rem ⓑ 의 Gen 은 Historia.uproject PreBuildSteps(Tools\his_core_gen.bat)가 UBT 소스 훑기 전에 만든다 — 빌드는 한 번.
rem 쓰임: Tools\his_build.bat [엔진 폴더]   (없으면 UE_ROOT → E:\Epic\UE_5.8) · 에디터가 열려 있으면 닫고
setlocal
set "PROJ=%~dp0.."
for %%I in ("%PROJ%") do set "PROJ=%%~fI"
set "UE=%~1"
if "%UE%"=="" set "UE=%UE_ROOT%"
if "%UE%"=="" set "UE=E:\Epic\UE_5.8"
set "B=call "%UE%\Engine\Build\BatchFiles\Build.bat" HistoriaEditor Win64 Development -Project="%PROJ%\Historia.uproject" -WaitMutex"
%B% || ( echo [his_build] 빌드 실패 & exit /b 1 )
call "%~dp0his_core_hash.bat" "%UE%"
endlocal & exit /b %errorlevel%
