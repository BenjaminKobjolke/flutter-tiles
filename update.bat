@echo off
where fvm >nul 2>nul
if errorlevel 1 exit /b 1
fvm flutter pub upgrade
if errorlevel 1 exit /b 1
fvm flutter analyze
if errorlevel 1 exit /b 1
call tools\run_tests.bat
set TESTRESULT=%ERRORLEVEL%
exit /b %TESTRESULT%
