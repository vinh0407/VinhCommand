# VinhCommand Clean Release Package Script

Write-Host " Stopping any running VinhCommand instances..." -ForegroundColor Yellow
Stop-Process -Name vinhcommand_desktop -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Write-Host " Clearing old files in C:\VisualStudio\VinhCommand\releases..." -ForegroundColor Red
if (Test-Path "C:\VisualStudio\VinhCommand\releases") {
    Remove-Item -Path "C:\VisualStudio\VinhCommand\releases\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path "C:\VisualStudio\VinhCommand\releases" -Force
}

# Tạo các thư mục chính
New-Item -ItemType Directory -Path "C:\VisualStudio\VinhCommand\releases\Windows" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\VisualStudio\VinhCommand\releases\Android" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\VisualStudio\VinhCommand\releases\Tools" -Force | Out-Null

Write-Host " [1/4] Copying Windows Desktop build to Windows/..." -ForegroundColor Green
Copy-Item -Path "C:\VisualStudio\VinhCommand\vinhcommand_desktop\build\windows\x64\runner\Release\*" -Destination "C:\VisualStudio\VinhCommand\releases\Windows" -Recurse -Force

Write-Host " [2/4] Copying Android APK to Android/..." -ForegroundColor Green
Copy-Item -Path "C:\VisualStudio\VinhCommand\vinhcommand-android\app\build\outputs\apk\debug\app-debug.apk" -Destination "C:\VisualStudio\VinhCommand\releases\Android\VinhCommand-Android-debug.apk" -Force

Write-Host " [3/4] Generating root launcher shortcuts..." -ForegroundColor Cyan

# Nút chính 1: Chạy Desktop
@'
@echo off
title VinhCommand Desktop
echo Starting VinhCommand Desktop...
start "" "%~dp0Windows\vinhcommand_desktop.exe"
'@ | Out-File -FilePath "C:\VisualStudio\VinhCommand\releases\Run-Desktop.bat" -Encoding ascii

# Nút chính 2: Cài APK Android
@'
@echo off
title VinhCommand Android Installer
echo Installing VinhCommand Android APK via ADB...
adb devices
echo.
adb install -r "%~dp0Android\VinhCommand-Android-debug.apk"
echo.
pause
'@ | Out-File -FilePath "C:\VisualStudio\VinhCommand\releases\Install-Android.bat" -Encoding ascii

# Nút phụ trong Tools: Kiểm tra AI Agents
@'
@echo off
title Kiem Tra AI Agents
echo ========================================================
echo   KIEM TRA CAC AI AGENT DA CAI DAT TREN MAY
echo ========================================================
echo.
echo [1] Codex CLI:
if exist "%APPDATA%\npm\codex.cmd" (echo   [OK] Da tim thay tai %APPDATA%\npm\codex.cmd) else (echo   [--] Chua tim thay)
echo.
echo [2] Antigravity:
if exist "%USERPROFILE%\.gemini\antigravity\bin\agentapi.bat" (echo   [OK] Da tim thay Antigravity agentapi) else (echo   [--] Chua tim thay agentapi)
if exist "%LOCALAPPDATA%\Programs\Antigravity IDE\bin\antigravity-ide.cmd" (echo   [OK] Da tim thay Antigravity IDE) else (echo   [--] Chua tim thay IDE)
echo.
echo [3] ChatGPT Web Engine:
if exist "C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine\codex-web-gpt.cmd" (
    call "C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine\codex-web-gpt.cmd" --version
) else (
    echo   [--] Khong tim thay engine
)
echo.
echo ========================================================
pause
'@ | Out-File -FilePath "C:\VisualStudio\VinhCommand\releases\Tools\Check-AI-Agents.bat" -Encoding ascii

# Nút phụ trong Tools: Khởi chạy ChatGPT Web Engine
@'
@echo off
title ChatGPT Web Server Engine
echo Starting ChatGPT Web Server (Bun)...
cd /d "C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine"
call codex-web-gpt.cmd serve
pause
'@ | Out-File -FilePath "C:\VisualStudio\VinhCommand\releases\Tools\Start-ChatGPT-Web-Engine.bat" -Encoding ascii

Write-Host " [4/4] Creating ZIP package and Checksums..." -ForegroundColor Cyan
Compress-Archive -Path "C:\VisualStudio\VinhCommand\releases\Windows\*" -DestinationPath "C:\VisualStudio\VinhCommand\releases\VinhCommand-Windows-x64.zip" -Force

Get-FileHash "C:\VisualStudio\VinhCommand\releases\Android\VinhCommand-Android-debug.apk", "C:\VisualStudio\VinhCommand\releases\VinhCommand-Windows-x64.zip" -Algorithm SHA256 | Out-File "C:\VisualStudio\VinhCommand\releases\SHA256SUMS.txt" -Encoding utf8

Write-Host "`n Done! Releases directory is now clean and organized:" -ForegroundColor Green
Get-ChildItem "C:\VisualStudio\VinhCommand\releases"

