# daily-start.ps1 — поднять Docker (если не запущен), затем Postgres + LocalStack + app, и проверить API
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Docker {
  Write-Host "🐳 Проверяю Docker Desktop..." -ForegroundColor Cyan
  try { docker info | Out-Null; return } catch {}
  $dockerExe = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
  if (-not (Test-Path $dockerExe)) { throw "Docker Desktop не найден: $dockerExe" }
  Write-Host "▶️  Стартую Docker Desktop..." -ForegroundColor Yellow
  Start-Process $dockerExe | Out-Null
  $max = 120
  for ($i=1; $i -le $max; $i++) {
    try { docker info | Out-Null; Write-Host "✅ Docker готов." -ForegroundColor Green; return } catch {}
    Start-Sleep -Seconds 1
    if ($i % 10 -eq 0) { Write-Host "…жду Docker ($i/$max сек)" -ForegroundColor DarkGray }
  }
  throw "Docker Desktop так и не запустился за $max секунд."
}

function Wait-ServiceHealthy([string]$service, [int]$timeoutSec=120) {
  Write-Host "⏳ Жду, пока $service станет healthy..." -ForegroundColor Cyan
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
    try {
      $itemsJson = docker compose ps --format json
      if (-not $itemsJson) { Start-Sleep 1; continue }
      $items = $itemsJson | ConvertFrom-Json
      $svc = $items | Where-Object { $_.Service -eq $service }
      if ($null -ne $svc) {
        if ($svc.Health -eq "healthy" -or ($svc.Status -match "healthy")) {
          Write-Host "✅ $service healthy." -ForegroundColor Green
          return
        }
      }
    } catch { Start-Sleep 1 }
    Start-Sleep 1
  }
  throw "$service не стал healthy за $timeoutSec сек."
}

function Invoke-WithRetry([scriptblock]$Block, [int]$retries=8, [int]$delaySec=2) {
  for ($i=1; $i -le $retries; $i++) {
    try { return & $Block } catch {
      if ($i -eq $retries) { throw }
      Write-Host ("…повтор попытки {0}/{1}: {2}" -f $i,$retries,$_.Exception.Message) -ForegroundColor DarkYellow
      Start-Sleep -Seconds $delaySec
    }
  }
}

function Curl-Json([string]$url, [int]$retries=12, [int]$delaySec=2) {
  Invoke-WithRetry {
    $out = & curl.exe -sS $url
    if ($LASTEXITCODE -ne 0 -or -not $out) { throw "curl exit=$LASTEXITCODE" }
    return $out
  } -retries $retries -delaySec $delaySec
}

# 1) Docker
Ensure-Docker

# 2) Инфра
Write-Host "📦 Поднимаю Postgres + LocalStack..." -ForegroundColor Cyan
docker compose up -d postgres localstack
Wait-ServiceHealthy -service "postgres" -timeoutSec 120

# 3) App
Write-Host "🚀 Запускаю приложение..." -ForegroundColor Cyan
docker compose up -d app

# 4) Ожидаем порт 8080 и проверяем API (через curl.exe)
Write-Host "🔎 Проверяю API..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
Invoke-WithRetry {
  if (-not (Test-NetConnection -ComputerName localhost -Port 8080).TcpTestSucceeded) {
    throw "8080 ещё не слушается"
  }
} -retries 30 -delaySec 1

$hello = Curl-Json "http://localhost:8080/api/hello"
Write-Host "GET /api/hello → $hello" -ForegroundColor Green

$notes = Curl-Json "http://localhost:8080/api/notes"
Write-Host "GET /api/notes → $notes" -ForegroundColor Green
