@echo off
where fvm >nul 2>nul
if errorlevel 1 exit /b 1
fvm flutter test --timeout 30s --reporter expanded test/models test/utils test/store test/cubit test/widgets
set TESTRESULT=%ERRORLEVEL%
if not "%TESTRESULT%"=="0" exit /b %TESTRESULT%
if not exist example\pubspec.yaml exit /b 0
pushd example
fvm flutter test --timeout 30s --reporter expanded
set TESTRESULT=%ERRORLEVEL%
popd
exit /b %TESTRESULT%
