@echo off
setlocal
set "FLUTTER=C:\Users\bilo\Documents\Codex\tools\flutter\bin\flutter.bat"
set "APPDIR=C:\Users\bilo\Desktop\turkish_word_engine\mobile_app"

echo Kelime Analiz Android APK olusturuluyor...
cd /d "%APPDIR%"
call "%FLUTTER%" pub get
if errorlevel 1 goto :error
call "%FLUTTER%" analyze
if errorlevel 1 goto :error
call "%FLUTTER%" test
if errorlevel 1 goto :error
call "%FLUTTER%" build apk --release
if errorlevel 1 goto :error

echo.
echo APK hazir:
echo %APPDIR%\build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0

:error
echo.
echo APK olusturulamadi. Yukaridaki hata mesajini Codex'e goster.
pause
exit /b 1
