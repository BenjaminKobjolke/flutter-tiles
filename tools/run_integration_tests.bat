@echo off
where fvm >nul 2>nul
if errorlevel 1 exit /b 1
set TESTLOG=%TEMP%\_flutter_tiles_integration_output.log
fvm flutter test test/integration > "%TESTLOG%" 2>&1
set TESTRESULT=%ERRORLEVEL%
type "%TESTLOG%"
del "%TESTLOG%" >nul 2>&1
exit /b %TESTRESULT%
