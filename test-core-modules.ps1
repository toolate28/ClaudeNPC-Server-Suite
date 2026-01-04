# Test Core Modules Loading
# Tests that all core modules can be loaded and their key functions work

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  CORE MODULES TEST" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @()

# Test Display.ps1
Write-Host "Testing Display.ps1..." -ForegroundColor Yellow
try {
    . ".\setup\core\Display.ps1"
    Show-Banner
    Write-Host "  ✓ Display.ps1 loaded successfully" -ForegroundColor Green
    Write-Host "  ✓ Show-Banner executed" -ForegroundColor Green
    $testResults += @{Module = "Display.ps1"; Status = "PASS"}
} catch {
    Write-Host "  ✗ Display.ps1 failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Display.ps1"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""

# Test Logger.ps1
Write-Host "Testing Logger.ps1..." -ForegroundColor Yellow
try {
    . ".\setup\core\Logger.ps1"
    $logFile = Initialize-Logger -LogPath ".\test-logs"
    Write-Log -Message "Test log entry" -Level "INFO"
    Write-Host "  ✓ Logger.ps1 loaded successfully" -ForegroundColor Green
    Write-Host "  ✓ Initialize-Logger executed" -ForegroundColor Green
    Write-Host "  ✓ Write-Log executed" -ForegroundColor Green
    Write-Host "  ✓ Log file created: $logFile" -ForegroundColor Green
    Close-Logger -Success $true
    $testResults += @{Module = "Logger.ps1"; Status = "PASS"}
} catch {
    Write-Host "  ✗ Logger.ps1 failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Logger.ps1"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""

# Test Safety.ps1
Write-Host "Testing Safety.ps1..." -ForegroundColor Yellow
try {
    . ".\setup\core\Safety.ps1"
    $disk = Test-DiskSpace -Path "C:\" -RequiredGB 1
    Write-Host "  ✓ Safety.ps1 loaded successfully" -ForegroundColor Green
    Write-Host "  ✓ Test-DiskSpace executed" -ForegroundColor Green
    Write-Host "  ✓ Disk check result: $($disk.FreeSpaceGB) GB free" -ForegroundColor Green
    $testResults += @{Module = "Safety.ps1"; Status = "PASS"}
} catch {
    Write-Host "  ✗ Safety.ps1 failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Safety.ps1"; Status = "FAIL"; Error = $_.Exception.Message}
}

Write-Host ""

# Test Config.ps1
Write-Host "Testing Config.ps1..." -ForegroundColor Yellow
try {
    . ".\setup\core\Config.ps1"
    $config = Get-DefaultConfiguration
    Write-Host "  ✓ Config.ps1 loaded successfully" -ForegroundColor Green
    Write-Host "  ✓ Get-DefaultConfiguration executed" -ForegroundColor Green
    Write-Host "  ✓ Default config has $($config.Keys.Count) settings" -ForegroundColor Green
    $testResults += @{Module = "Config.ps1"; Status = "PASS"}
} catch {
    Write-Host "  ✗ Config.ps1 failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Module = "Config.ps1"; Status = "FAIL"; Error = $_.Exception.Message}
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
    Write-Host "  $($result.Module): $($result.Status)" -ForegroundColor $color
    if ($result.Error) {
        Write-Host "    Error: $($result.Error)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Total: $($testResults.Count) | Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "✓ ALL CORE MODULES PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ SOME MODULES FAILED!" -ForegroundColor Red
    exit 1
}
