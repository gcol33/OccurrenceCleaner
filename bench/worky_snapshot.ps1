# Runs gbif_snapshot_run.R over the whole 2026-10-01 GBIF snapshot on worky.
# Usage: powershell -File worky_snapshot.ps1 <name> <max files> <workers> <reference>
#   reference: OccurrenceCleaner or CoordinateCleaner.
# Logs of an earlier start of the same name are kept in <name>\segmentN.
param([string]$Name, [string]$MaxFiles, [string]$Workers, [string]$Reference)
$root = $PSScriptRoot
$dir = "$root\$Name"
if (Test-Path "$dir\stderr.log") {
  $k = 1
  while (Test-Path "$dir\segment$k") { $k++ }
  New-Item -ItemType Directory "$dir\segment$k" | Out-Null
  Move-Item "$dir\*.log", "$dir\*.txt" "$dir\segment$k"
}
$snap = 'C:/Users/collingg/research/gbif_snapshot/2026-10-01/occurrence.parquet'
& powershell -NoProfile -ExecutionPolicy Bypass -File "$root\worky_run.ps1" $Name gbif_snapshot_run.R $snap "C:/Users/collingg/occ_snapcc/$Name/out" $MaxFiles $Reference 0 $Workers
Set-Content "$root\$Name.FINISHED" (Get-Date -Format s)
