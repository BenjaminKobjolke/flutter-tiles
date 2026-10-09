@echo off
where fvm >nul 2>nul
if errorlevel 1 exit /b 1
set TESTLOG=%TEMP%\_flutter_tiles_tests_output.log
fvm flutter test test/models test/utils test/store test/cubit test/widgets > "%TESTLOG%" 2>&1
set TESTRESULT=%ERRORLEVEL%
type "%TESTLOG%"
del "%TESTLOG%" >nul 2>&1
if not "%TESTRESULT%"=="0" exit /b %TESTRESULT%
if not exist example\pubspec.yaml exit /b 0
pushd example
fvm flutter test > "%TESTLOG%" 2>&1
set TESTRESULT=%ERRORLEVEL%
type "%TESTLOG%"
del "%TESTLOG%" >nul 2>&1
popd
exit /b %TESTRESULT%
