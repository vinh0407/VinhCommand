@echo off
title ChatGPT Web Server Engine
echo Starting ChatGPT Web Server (Bun)...
if exist "C:\VisualStudio\VinhCommand\engines\codex_chatgpt_web_engine" (
    cd /d "C:\VisualStudio\VinhCommand\engines\codex_chatgpt_web_engine"
) else (
    cd /d "C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine"
)
call codex-web-gpt.cmd serve
pause
