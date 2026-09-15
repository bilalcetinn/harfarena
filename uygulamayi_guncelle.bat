@echo off
setlocal
set "FLUTTER=C:\Users\bilo\Documents\Codex\tools\flutter\bin\flutter.bat"
set "APPDIR=C:\Users\bilo\Desktop\turkish_word_engine\windows_app"
set "TARGET=C:\Users\bilo\Desktop\Kelime Analiz"

echo Kelime Analiz uygulamasi guncelleniyor...
cd /d "%APPDIR%"
call "%FLUTTER%" pub get
if errorlevel 1 goto :error
call "%FLUTTER%" build windows --release
if errorlevel 1 goto :error

if not exist "%TARGET%" mkdir "%TARGET%"
xcopy /E /I /Y "%APPDIR%\build\windows\x64\runner\Release\*" "%TARGET%\" >nul
if errorlevel 1 goto :error

echo.
echo Guncelleme tamamlandi.
pause
exit /b 0

:error
echo.
echo Guncelleme tamamlanamadi. Yukaridaki hata mesajini Codex'e goster.
pause
exit /b 1
