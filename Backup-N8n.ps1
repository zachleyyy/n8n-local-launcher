$ErrorActionPreference = 'Stop'
& "$PSScriptRoot\Stop-N8n.ps1"
if (Get-NetTCPConnection -State Listen -LocalPort 5678 -ErrorAction SilentlyContinue) { throw 'Backup requires n8n to be stopped.' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$destination = Join-Path $PSScriptRoot "backups\n8n-$stamp.zip"
$stage = Join-Path $PSScriptRoot "backups\stage-$stamp"
New-Item -ItemType Directory -Path "$stage\app" -Force | Out-Null
foreach ($relative in @('data','installation.json','n8n-env.ps1','runner.cjs','workflows','Start-N8n.ps1','Stop-N8n.ps1','Backup-N8n.ps1','Update-N8n.ps1','README.md')) {
    $source = Join-Path $PSScriptRoot $relative
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $stage -Recurse -Force }
}
foreach ($relative in @('package.json','package-lock.json')) {
    $source = Join-Path $PSScriptRoot "app\$relative"
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination "$stage\app" -Force }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $destination)
$resolvedStage = [System.IO.Path]::GetFullPath($stage)
$backupRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'backups')) + '\'
if (!$resolvedStage.StartsWith($backupRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected staging path; cleanup cancelled.' }
Remove-Item -LiteralPath $resolvedStage -Recurse -Force
Write-Host "Backup saved: $destination"
Write-Host 'Backup contains the database and encryption key. Protect it. n8n remains stopped; run Start-N8n.ps1.'
