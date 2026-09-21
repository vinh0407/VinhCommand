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
