@echo off
chcp 65001 >nul
rem HistoriaCore Gen 만들기 (링크 길 ⓑ) — Historia.uproject PreBuildSteps(Win64)가 UBT 가 소스를 훑기 전에 부름.
rem UBT 는 미리 빌드 단계를 돌린 뒤 폴더 기억을 지우므로 새 Gen 파일이 첫 빌드부터 들어감. 내용이 같으면 다시 안 씀. 실패 = 끝 코드 1.
rem 손으로: Tools\his_core_gen.bat
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0his_core_gen.ps1"
exit /b %errorlevel%
