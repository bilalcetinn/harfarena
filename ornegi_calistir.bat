@echo off
setlocal
set "DART=C:\Users\bilo\Documents\Codex\tools\flutter\bin\cache\dart-sdk\bin\dart.exe"
pushd "%~dp0"
"%DART%" pub get
if errorlevel 1 goto :failed
"%DART%" run example\main.dart
if errorlevel 1 goto :failed
goto :end

:failed
echo.
echo Ornek calistirilirken bir hata olustu.

:end
popd
pause
