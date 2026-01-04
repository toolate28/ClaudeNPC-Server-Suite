# Test syntax with details
$files = @(
    ".\setup\phases\01-Preflight.ps1",
    ".\setup\phases\04-Plugins.ps1",
    ".\scripts\Backup-Server.ps1",
    ".\scripts\Monitor-Server.ps1"
)

foreach ($file in $files) {
    Write-Host ""
    Write-Host "Testing: $file" -ForegroundColor Cyan
    Write-Host "=" * 60

    $errors = $null
    $content = Get-Content $file -Raw
    [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null

    if ($errors.Count -gt 0) {
        foreach ($err in $errors) {
            Write-Host "Line $($err.Token.StartLine): $($err.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No errors!" -ForegroundColor Green
    }
}
