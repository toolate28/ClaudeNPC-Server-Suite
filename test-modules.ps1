# Test Module Loading - Comprehensive Test
# Tests that all modules can be imported and their key functions work

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  MODULE IMPORT TEST" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @()
$modulePath = ".\setup\core"

# Test Display Module
Write-Host "Testing Display Module..." -ForegroundColor Yellow
try {
    Import-Module "$modulePath\Display.psd1" -Force -Global -ErrorAction Stop
    Show-Banner
    Write-Host "  [OK] Display module imported successfully" -ForegroundColor Green
    Write-Host "  [OK] Show-Banner function executed" -ForegroundColor Green
    $testResults += @{Module = "Display"; Status = "PASS"}
} catch {
    Write-Host "  [FAIL] Display module failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Display"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""

# Test Logger Module
Write-Host "Testing Logger Module..." -ForegroundColor Yellow
try {
    Import-Module "$modulePath\Logger.psd1" -Force -Global -ErrorAction Stop
    $logFile = Initialize-Logger -LogPath ".\test-logs"
    Write-Log -Message "Test log entry" -Level "INFO"
    Write-Host "  [OK] Logger module imported successfully" -ForegroundColor Green
    Write-Host "  [OK] Initialize-Logger function executed" -ForegroundColor Green
    Write-Host "  [OK] Write-Log function executed" -ForegroundColor Green
    Write-Host "  [OK] Log file created: $logFile" -ForegroundColor Green
    Close-Logger -Success $true
    $testResults += @{Module = "Logger"; Status = "PASS"}
} catch {
    Write-Host "  [FAIL] Logger module failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Logger"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""

# Test Safety Module
Write-Host "Testing Safety Module..." -ForegroundColor Yellow
try {
    Import-Module "$modulePath\Safety.psd1" -Force -Global -ErrorAction Stop
    $disk = Test-DiskSpace -Path "C:\" -RequiredGB 1
    Write-Host "  [OK] Safety module imported successfully" -ForegroundColor Green
    Write-Host "  [OK] Test-DiskSpace function executed" -ForegroundColor Green
    Write-Host "  [OK] Disk check result: $($disk.FreeSpaceGB) GB free" -ForegroundColor Green
    $testResults += @{Module = "Safety"; Status = "PASS"}
} catch {
    Write-Host "  [FAIL] Safety module failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Safety"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""

# Test Config Module
Write-Host "Testing Config Module..." -ForegroundColor Yellow
try {
    Import-Module "$modulePath\Config.psd1" -Force -Global -ErrorAction Stop
    $config = Get-DefaultConfiguration
    Write-Host "  [OK] Config module imported successfully" -ForegroundColor Green
    Write-Host "  [OK] Get-DefaultConfiguration function executed" -ForegroundColor Green
    Write-Host "  [OK] Default config has $($config.Keys.Count) settings" -ForegroundColor Green
    $testResults += @{Module = "Config"; Status = "PASS"}
} catch {
    Write-Host "  [FAIL] Config module failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Config"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count

foreach ($result in $testResults) {
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    $status = if ($result.Status -eq "PASS") { "[OK]" } else { "[FAIL]" }
    Write-Host "  $status $($result.Module) Module" -ForegroundColor $color
    if ($result.Error) {
        Write-Host "        Error: $($result.Error)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Total: $($testResults.Count) | Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "[OK] ALL MODULES PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Module system is working properly!" -ForegroundColor Cyan
    Write-Host "Ready for full Setup.ps1 testing." -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "[FAIL] SOME MODULES FAILED!" -ForegroundColor Red
    exit 1
}
