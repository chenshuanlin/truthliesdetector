@echo off
REM 每日自動爬蟲批次檔
REM 用於 Windows 工作排程器

cd /d "%~dp0"

echo ========================================
echo 每日爬蟲任務開始
echo 時間: %date% %time%
echo ========================================

REM 執行 Python 腳本
python daily_auto_crawler.py

echo ========================================
echo 任務完成
echo ========================================

REM 將輸出寫入日誌
echo [%date% %time%] Daily crawler executed >> crawler_log.txt
