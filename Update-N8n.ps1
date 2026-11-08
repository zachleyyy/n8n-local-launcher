param([Parameter(Mandatory=$true)][ValidatePattern('^2\.\d+\.\d+$')][string]$Version)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\n8n-env.ps1"
& "$PSScriptRoot\Backup-N8n.ps1"
Push-Location $PSScriptRoot
try {
    & "$NodeDir\node.exe" "$NodeDir\node_modules\npm\bin\npm-cli.js" install --prefix app --cache .npm-cache --save-exact "n8n@$Version" --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw 'Update failed. n8n remains stopped. Backup is preserved.' }
    $metadata = Get-Content installation.json -Raw | ConvertFrom-Json
    $metadata.n8nVersion = $Version
    $metadata | ConvertTo-Json | Set-Content installation.json
} finally { Pop-Location }
& "$PSScriptRoot\Start-N8n.ps1"
