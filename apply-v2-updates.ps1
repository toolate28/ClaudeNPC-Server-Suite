# Quick Version Update Script for v2.0.0
# Updates all documentation files to reflect v2.0.0 status

$files = @(
    "START_HERE.md",
    "README.md",
    "PROJECT_STATE.md",
    "PROJECT_OVERVIEW.md",
    "CLAUDE_INSTANCE_GUIDE.md",
    "NEXT_INSTANCE_GUIDE.md",
    "INDEX.md",
    "DEPLOYMENT_GUIDE.md"
)

Write-Host "Updating documentation to v2.0.0..."

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $updated = $false

        # Update version numbers
        if ($content -match "Version.*?1\.0\.0|v1\.0\.0") {
            $content = $content -replace "Version 1\.0\.0", "Version 2.0.0"
            $content = $content -replace "v1\.0\.0", "v2.0.0"
            $updated = $true
        }

        # Update status descriptions
        $content = $content -replace "Core complete, phases ready for implementation", "100% Complete - Production Ready"
        $content = $content -replace "phases need implementation \(but templates provided\)", "all phases fully implemented"

        if ($updated) {
            $content | Set-Content $file -NoNewline
            Write-Host "[UPDATED] $file"
        } else {
            Write-Host "[SKIP] $file (no changes needed)"
        }
    }
}

Write-Host ""
Write-Host "Update complete!" -ForegroundColor Green
