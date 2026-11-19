# Quizopia demo status (Windows PowerShell 5.1+ and PowerShell 7).
# Shows container status, probes key endpoints, prints useful URLs and hints.
#   .\scripts\status-demo.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host '=== Quizopia containers (all profiles) ===' -ForegroundColor Cyan
& docker compose --profile monitoring --profile recording ps
if ($LASTEXITCODE -ne 0) { Write-Warning 'docker compose ps failed - is Docker Desktop running?' }

function Test-Url([string]$Name, [string]$Url) {
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        Write-Host ("  [UP]   {0,-18} {1}  (HTTP {2})" -f $Name, $Url, $resp.StatusCode)
    } catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        if ($code) { Write-Host ("  [UP]   {0,-18} {1}  (HTTP {2})" -f $Name, $Url, $code) }
        else { Write-Host ("  [DOWN] {0,-18} {1}" -f $Name, $Url) -ForegroundColor Yellow }
    }
}

Write-Host ''
Write-Host '=== Endpoint probes ===' -ForegroundColor Cyan
Test-Url 'Frontend'      'http://localhost:3000'
Test-Url 'Backend API'   'http://localhost:8080/actuator/health'
Test-Url 'LiveKit SFU'   'http://localhost:7880'
Test-Url 'MinIO'         'http://localhost:9000/minio/health/live'
Test-Url 'Mailpit'       'http://localhost:8025'

Write-Host ''
Write-Host '=== Useful URLs ===' -ForegroundColor Cyan
Write-Host '  Frontend        http://localhost:3000'
Write-Host '  Backend API     http://localhost:8080'
Write-Host '  MinIO console   http://localhost:9001'
Write-Host '  Mailpit         http://localhost:8025'
Write-Host '  LiveKit WS      ws://localhost:7880   (browsers; needs --profile monitoring)'

Write-Host ''
Write-Host '=== Current mode (.env) ===' -ForegroundColor Cyan
$livekitEnabled = (Select-String -Path .env -Pattern '^QUIZOPIA_LIVEKIT_ENABLED=(.*)$' -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Matches[0].Groups[1].Value }) -join ''
Write-Host "  QUIZOPIA_LIVEKIT_ENABLED = '$livekitEnabled'  (backend camera path; set true for monitoring demos)"

Write-Host ''
Write-Host 'Hints: .\scripts\start-demo.ps1 -Mode monitoring | recording ; .\scripts\stop-demo.ps1'
