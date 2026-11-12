@echo off
chcp 65001 >nul
rem 거시 core 미리 빌드 (TASK_거시연결 U0 ⓐ) — headless 짝 폴더 소스를 CMake(MSVC, Release = /MD — 언리얼 CRT 와 같음)로 빌드해
rem 정적 라이브러리를 ThirdParty\historia_core\lib\Win64\ (git 밖)에 복사. headless 폴더에는 아무것도 쓰지 않음(빌드 폴더 = Intermediate\HisCore\build).
rem 쓰임: Tools\his_core_lib.bat [headless 폴더]   (없으면 HISTORIA_HEADLESS → 짝 폴더 ..\Playheadless{꼬리})
setlocal EnableDelayedExpansion
set "PROJ=%~dp0.."
for %%I in ("%PROJ%") do set "PROJ=%%~fI"
for %%I in ("%PROJ%") do set "PNAME=%%~nxI"
set "SUB=!PNAME:Historia=!"
set "HL=%~1"
if "%HL%"=="" set "HL=%HISTORIA_HEADLESS%"
if "%HL%"=="" set "HL=%PROJ%\..\Playheadless%SUB%"
for %%I in ("%HL%") do set "HL=%%~fI"
if not exist "%HL%\playheadless\core.hpp" ( echo [his_core_lib] headless 폴더가 아님: %HL% & exit /b 1 )

rem VS 에 딸린 cmake (생성기 Visual Studio 18 2026 을 아는 것)
set "CMAKE=cmake"
for /f "usebackq delims=" %%V in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath`) do set "VSDIR=%%V"
if exist "%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "CMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

set "BLD=%PROJ%\Intermediate\HisCore\build"
set "OUT=%PROJ%\ThirdParty\historia_core\lib\Win64"
echo [his_core_lib] headless = %HL%
echo [his_core_lib] build    = %BLD%
if not exist "%BLD%\CMakeCache.txt" (
  "%CMAKE%" -S "%HL%" -B "%BLD%" -A x64 -DHISTORIA_BUILD_APP=OFF -DHISTORIA_BUILD_TESTS=OFF -DHISTORIA_BUILD_NAVLAB=OFF || exit /b 1
)
"%CMAKE%" --build "%BLD%" --config Release --target historia_run -j || exit /b 1

if not exist "%OUT%" mkdir "%OUT%"
for %%L in (playheadless\Release\historia_core.lib Startsetting\Release\historia_setting.lib Startsetting\Release\historia_bakelib.lib Startsetting\Release\historia_tools.lib _deps\yyjson-build\Release\yyjson.lib _deps\miniz-build\Release\miniz.lib) do (
  copy /y "%BLD%\%%L" "%OUT%\" >nul || ( echo [his_core_lib] 복사 실패 %%L & exit /b 1 )
)
rem 이 lib 를 만든 headless 커밋 — 언리얼 쪽이 어느 core 인지 알게
git -C "%HL%" rev-parse HEAD > "%OUT%\headless_commit.txt"
git -C "%HL%" status --porcelain >> "%OUT%\headless_commit.txt"
echo [his_core_lib] 끝 → %OUT%
endlocal
