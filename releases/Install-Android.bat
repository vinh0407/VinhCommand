@echo off
title VinhCommand Android Installer
echo Installing VinhCommand Android APK via ADB...
adb devices
echo.
adb install -r "%~dp0Android\VinhCommand-Android-debug.apk"
echo.
pause
