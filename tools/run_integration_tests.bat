@echo off
where fvm >nul 2>nul
if errorlevel 1 exit /b 1
fvm flutter test --timeout 30s --reporter expanded test/integration
exit /b %ERRORLEVEL%
