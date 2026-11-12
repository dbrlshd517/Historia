@echo off
chcp 65001 >nul
rem 거시 core 준비 (TASK_거시연결 U2 — 링크 길 ⓑ, 사람 11-12): Config\HisCore.json headless_dir(고정 worktree)를 CMake(MSVC Release)로 빌드해
rem   - historia_run.exe = 해시 기준 (His.CoreHash 가 돌려 견줌)
rem   - (CMake 가 받는 FetchContent 바깥 소스는 historia_run 빌드에만 씀 — 언리얼 ⓑ 는 ThirdParty\HisDeps 를 컴파일)
rem   - gamedata_core.json 이 없으면 historia_import 로 만듦(--no-log --no-view — headless 의 추적 파일은 안 건드림)
rem 빌드 폴더 = Intermediate\HisCore\build (headless 폴더엔 out\gamedata_*.json 말고 아무것도 안 씀). headless 커밋은 HisCore.json headless_commit 과 견줌.
rem 쓰임: Tools\his_core_build.bat
setlocal EnableDelayedExpansion
set "PROJ=%~dp0.."
for %%I in ("%PROJ%") do set "PROJ=%%~fI"
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "$j = Get-Content -Raw -Encoding utf8 '%PROJ%\Config\HisCore.json' | ConvertFrom-Json; $j.headless_dir + '|' + $j.headless_commit"`) do set "CFG=%%D"
for /f "tokens=1,2 delims=|" %%A in ("!CFG!") do ( set "HLREL=%%A" & set "PIN=%%B" )
set "HL=%HISTORIA_HEADLESS%"
if "%HL%"=="" ( pushd "%PROJ%" & for %%I in ("!HLREL!") do set "HL=%%~fI" & popd )
if not exist "%HL%\playheadless\core.hpp" ( echo [his_core_build] headless 폴더가 아님: %HL% & exit /b 1 )
for /f "usebackq delims=" %%C in (`git -C "%HL%" rev-parse HEAD`) do set "NOW=%%C"
echo [his_core_build] headless = %HL%
echo [his_core_build] 커밋     = %NOW%
if /i not "%NOW%"=="%PIN%" echo [his_core_build] 주의: HisCore.json headless_commit = %PIN% 와 다름

set "CMAKE=cmake"
for /f "usebackq delims=" %%V in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath`) do set "VSDIR=%%V"
if exist "%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "CMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

set "BLD=%PROJ%\Intermediate\HisCore\build"
"%CMAKE%" -S "%HL%" -B "%BLD%" -A x64 -DHISTORIA_BUILD_APP=OFF -DHISTORIA_BUILD_TESTS=OFF -DHISTORIA_BUILD_NAVLAB=OFF || exit /b 1
"%CMAKE%" --build "%BLD%" --config Release --target historia_run historia_import -- /m || exit /b 1

if not exist "%HL%\Startsetting\out\gamedata_core.json" (
  echo [his_core_build] gamedata_core.json 만들기 ^(엑셀 → historia_import^)
  "%BLD%\Startsetting\Release\historia_import.exe" --root "%HL%" --all --no-log --no-view || exit /b 1
)
echo [his_core_build] 끝 — 다음: 언리얼 빌드 → Tools\his_core_hash.bat
endlocal
