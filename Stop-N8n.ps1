$ErrorActionPreference = 'Stop'
$pidFile = Join-Path $PSScriptRoot 'run\n8n.pid'
if (!(Test-Path -LiteralPath $pidFile)) {
    if (Get-NetTCPConnection -State Listen -LocalPort 5678 -ErrorAction SilentlyContinue) { throw 'Port 5678 is occupied without a managed PID. Inspect it manually.' }
    Write-Host 'n8n is already stopped.'; return
}
$n8nProcessId = [int](Get-Content -LiteralPath $pidFile)
$process = Get-CimInstance Win32_Process -Filter "ProcessId=$n8nProcessId"
if (!$process) { Remove-Item -LiteralPath $pidFile; Write-Host 'n8n is stopped.'; return }
if ($process.CommandLine -notlike "*$PSScriptRoot\runner.cjs*") { throw 'PID does not match this n8n installation; no process was stopped.' }
Set-Content -LiteralPath (Join-Path $PSScriptRoot 'run\stop.request') -Value 'stop'
for ($attempt=0; $attempt -lt 60; $attempt++) {
    if (!(Get-Process -Id $n8nProcessId -ErrorAction SilentlyContinue)) { Write-Host 'n8n stopped gracefully.'; return }
    Start-Sleep -Seconds 1
}
throw 'Graceful stop timed out. No process was forcibly terminated. Inspect logs before backup or update.'
