@echo off
title ClaudeNPC Minecraft Server
color 0B

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║           ClaudeNPC Minecraft Server                     ║
echo ║                                                          ║
echo ║           Starting server...                             ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

REM Change to server directory
cd /d "%~dp0.."

REM Check if paper.jar exists
if not exist "paper.jar" (
    echo [ERROR] paper.jar not found!
    echo Please run the setup script first.
    pause
    exit /b 1
)

REM Start server with optimized JVM flags
java -Xms4G -Xmx8G ^
  -XX:+UseG1GC ^
  -XX:+ParallelRefProcEnabled ^
  -XX:MaxGCPauseMillis=200 ^
  -XX:+UnlockExperimentalVMOptions ^
  -XX:+DisableExplicitGC ^
  -XX:+AlwaysPreTouch ^
  -XX:G1HeapWastePercent=5 ^
  -XX:G1MixedGCCountTarget=4 ^
  -XX:G1MixedGCLiveThresholdPercent=90 ^
  -XX:G1RSetUpdatingPauseTimePercent=5 ^
  -XX:SurvivorRatio=32 ^
  -XX:+PerfDisableSharedMem ^
  -XX:MaxTenuringThreshold=1 ^
  -jar paper.jar nogui

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║           Server stopped.                                ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
pause
