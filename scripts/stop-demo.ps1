# Quizopia demo stopper (Windows PowerShell 5.1+ and PowerShell 7).
# Stops all services WITHOUT deleting containers, volumes or networks.
#   .\scripts\stop-demo.ps1          # stop (docker compose stop)
#   .\scripts\stop-demo.ps1 -Down    # stop + remove containers/network
#                                    # (volumes are still KEPT; never use -v)
[CmdletBinding()]
param([switch]$Down)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

# Include every profile so profiled services (livekit/egress) stop too.
$composeArgs = @('compose', '--profile', 'monitoring', '--profile', 'recording')
if ($Down) { $composeArgs += 'down' } else { $composeArgs += 'stop' }

Write-Host "Stopping Quizopia ($($composeArgs[-1])) - persistent volumes are NOT deleted." -ForegroundColor Cyan
& docker @composeArgs
if ($LASTEXITCODE -ne 0) { throw "docker compose failed with exit code $LASTEXITCODE." }

Write-Host ''
Write-Host 'Data volumes kept:' -ForegroundColor Cyan
& docker volume ls --filter 'label=com.docker.compose.project=quizopia-system'
Write-Host ''
Write-Host 'NEVER run: docker compose down -v  (deletes PostgreSQL/Redis/MinIO data!)'
