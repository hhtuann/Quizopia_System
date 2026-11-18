# Quizopia demo launcher (Windows PowerShell 5.1+ and PowerShell 7).
# Usage:
#   .\scripts\start-demo.ps1                      # core stack
#   .\scripts\start-demo.ps1 -Mode monitoring     # + LiveKit camera monitoring
#   .\scripts\start-demo.ps1 -Mode recording      # + monitoring + Egress recording
#   .\scripts\start-demo.ps1 -Mode monitoring -NoBuild   # skip image rebuild
[CmdletBinding()]
param(
    [ValidateSet('core', 'monitoring', 'recording')]
    [string]$Mode = 'core',
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path .env)) {
    throw ".env not found. Copy .env.example to .env and fill in the required secrets first."
}

# --- Preflight: required secrets for the selected mode ---------------------
$envLines = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*(.*)$') { $envLines[$Matches[1]] = $Matches[2].Trim() }
}
$required = @('QUIZOPIA_JWT_SECRET_BASE64', 'QUIZOPIA_DATA_ENCRYPTION_KEY_BASE64')
if ($Mode -ne 'core') { $required += @('QUIZOPIA_LIVEKIT_API_SECRET') }
foreach ($key in $required) {
    $value = ''
    if ($envLines.ContainsKey($key)) { $value = $envLines[$key] }
    if ([string]::IsNullOrWhiteSpace($value) -or $value -like '__replace*') {
        throw "Required setting $key is missing/empty in .env (see .env.example)."
    }
}

# --- Preflight: legacy standalone media stack conflicts --------------------
# Match by compose PROJECT label: the consolidated stack intentionally keeps
# the SAME container names, so a name filter would match our own containers.
try { $legacy = docker ps --filter 'label=com.docker.compose.project=quizopia-media' --format '{{.Names}}' 2>$null }
catch { $legacy = $null }
if ($legacy) {
    throw "Legacy containers still running: $($legacy -join ', '). Stop the old stack first (docs/infra/COMPOSE_MIGRATION.md): docker compose -p quizopia-media -f docker-compose.livekit.yml down"
}

# --- Preflight (Windows): Hyper-V UDP exclusions vs the ICE range ---------
if ($PSVersionTable.Platform -ne 'Unix' -and $Mode -ne 'core') {
    $start = 50100; $end = 50200
    if ($envLines.ContainsKey('LIVEKIT_RTC_PORT_START')) { $start = [int]$envLines['LIVEKIT_RTC_PORT_START'] }
    if ($envLines.ContainsKey('LIVEKIT_RTC_PORT_END')) { $end = [int]$envLines['LIVEKIT_RTC_PORT_END'] }
    $excluded = netsh interface ipv4 show excludedportrange protocol=udp |
        Select-String '^\s*(\d+)\s+(\d+)' | ForEach-Object {
            $r = $_.Matches[0]; @{ S = [int]$r.Groups[1].Value; E = [int]$r.Groups[2].Value } }
    foreach ($range in $excluded) {
        if ($range.S -le $end -and $range.E -ge $start) {
            Write-Warning "Windows UDP exclusion $($range.S)-$($range.E) overlaps ICE range $start-$end. 'docker compose up' may fail to bind. Set LIVEKIT_RTC_PORT_START/END in .env to a free range."
        }
    }
}

# --- Launch -----------------------------------------------------------------
$composeArgs = @('compose')
if ($Mode -eq 'monitoring') { $composeArgs += '--profile', 'monitoring' }
if ($Mode -eq 'recording') { $composeArgs += '--profile', 'monitoring', '--profile', 'recording' }
$composeArgs += 'up', '-d'
if (-not $NoBuild) { $composeArgs += '--build' }

Write-Host "Starting Quizopia (mode: $Mode)..." -ForegroundColor Cyan
& docker @composeArgs
if ($LASTEXITCODE -ne 0) { throw "docker compose failed with exit code $LASTEXITCODE." }

Write-Host ''
Write-Host 'Service status:' -ForegroundColor Cyan
& docker compose --profile monitoring --profile recording ps
Write-Host ''
Write-Host 'URLs:' -ForegroundColor Cyan
Write-Host '  Frontend        http://localhost:3000'
Write-Host '  Backend API     http://localhost:8080'
Write-Host '  MinIO console   http://localhost:9001'
Write-Host '  Mailpit         http://localhost:8025'
if ($Mode -ne 'core') { Write-Host '  LiveKit WS      ws://localhost:7880' }
Write-Host ''
Write-Host 'Check readiness any time with: .\scripts\status-demo.ps1'
