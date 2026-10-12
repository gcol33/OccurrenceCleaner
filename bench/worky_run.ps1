# Scheduled-task launcher on worky: runs one R script with its arguments,
# logs stdout/stderr, records the peak working set of the R process every 30 s.
# Usage: powershell -File worky_run.ps1 <name> <script.R> <args...>
param([string]$Name, [string]$Script, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$env:R_LIBS = 'C:/Users/collingg/R/library/4.6'
$env:OMP_NUM_THREADS = '1'
$dir = Join-Path $PSScriptRoot $Name
New-Item -ItemType Directory -Force $dir | Out-Null
$rs = 'C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe'
$argList = @('--no-save', (Join-Path $PSScriptRoot $Script)) + $Rest
$p = Start-Process -FilePath $rs -ArgumentList $argList -WorkingDirectory $PSScriptRoot `
  -RedirectStandardOutput "$dir\stdout.log" -RedirectStandardError "$dir\stderr.log" -PassThru -WindowStyle Hidden
Set-Content "$dir\pid.txt" $p.Id
$peak = 0
while (-not $p.HasExited) {
  try { $p.Refresh(); if ($p.PeakWorkingSet64 -gt $peak) { $peak = $p.PeakWorkingSet64 } } catch {}
  Set-Content "$dir\peak_mb.txt" ([math]::Round($peak / 1MB))
  Start-Sleep -Seconds 30
}
Set-Content "$dir\exit.txt" $p.ExitCode
