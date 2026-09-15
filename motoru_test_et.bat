@echo off
setlocal
set "DART=C:\Users\bilo\Documents\Codex\tools\flutter\bin\cache\dart-sdk\bin\dart.exe"
pushd "%~dp0"
"%DART%" pub get
if errorlevel 1 goto :failed
"%DART%" analyze
if errorlevel 1 goto :failed
"%DART%" test --reporter expanded
if errorlevel 1 goto :failed
echo.
echo Motor basariyla dogrulandi.
goto :end

:failed
echo.
echo Dogrulama sirasinda bir hata olustu.

:end
popd
pause
