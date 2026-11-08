. "$PSScriptRoot\n8n-env.ps1"
$existing = Get-NetTCPConnection -State Listen -LocalPort 5678 -ErrorAction SilentlyContinue
if ($existing) {
    $owned = Get-CimInstance Win32_Process -Filter "ProcessId=$($existing[0].OwningProcess)"
    if ($owned.CommandLine -like "*$PSScriptRoot\runner.cjs*") {
        Write-Host 'n8n is already running: http://localhost:5678'
        return
    }
    throw 'Port 5678 is occupied by another process. It has been left untouched.'
}
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\run","$PSScriptRoot\logs" | Out-Null
$process = Start-Process -FilePath "$NodeDir\node.exe" -ArgumentList @(('"' + "$PSScriptRoot\runner.cjs" + '"')) -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -RedirectStandardOutput "$PSScriptRoot\logs\n8n.log" -RedirectStandardError "$PSScriptRoot\logs\n8n-error.log" -PassThru
for ($attempt = 0; $attempt -lt 90; $attempt++) {
    if ($process.HasExited) { throw 'n8n exited. See logs\n8n.log and logs\n8n-error.log.' }
    try {
        $health = Invoke-WebRequest 'http://127.0.0.1:5678/healthz/readiness' -UseBasicParsing -TimeoutSec 2
        if ($health.StatusCode -eq 200) { Write-Host 'n8n is ready: http://localhost:5678'; return }
    } catch {}
    Start-Sleep -Seconds 1
}
throw 'Startup timed out; inspect logs before retrying.'
