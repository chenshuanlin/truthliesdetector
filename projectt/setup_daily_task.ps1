# Windows 工作排程器設置腳本
# 設置每天自動執行爬蟲

$taskName = "TruthLiesDetector_DailyCrawler"
$scriptPath = Join-Path $PSScriptRoot "run_daily_crawler.bat"
$logPath = Join-Path $PSScriptRoot "crawler_log.txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "設置每日自動爬蟲任務" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查是否已存在任務
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "發現已存在的任務，將先移除..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 創建任務動作
$action = New-ScheduledTaskAction -Execute $scriptPath -WorkingDirectory $PSScriptRoot

# 創建觸發器 (每天早上 8:00 執行)
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00"

# 創建設定
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# 創建主體 (使用當前用戶)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest

# 註冊任務
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "每天自動執行 Truth Lies Detector 爬蟲，抓取最新新聞資料"

Write-Host ""
Write-Host "✓ 任務設置完成！" -ForegroundColor Green
Write-Host ""
Write-Host "任務名稱: $taskName" -ForegroundColor White
Write-Host "執行時間: 每天早上 8:00" -ForegroundColor White
Write-Host "執行腳本: $scriptPath" -ForegroundColor White
Write-Host "日誌位置: $logPath" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "其他操作指令:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "查看任務: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "手動執行: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "停用任務: Disable-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "啟用任務: Enable-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "移除任務: Unregister-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host ""
Write-Host "要立即測試任務嗎？(Y/N)" -ForegroundColor Yellow -NoNewline
$response = Read-Host " "

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Host "開始測試..." -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 2
    
    Write-Host ""
    Write-Host "任務已啟動，請檢查日誌檔案:" -ForegroundColor Green
    Write-Host $logPath -ForegroundColor White
}
