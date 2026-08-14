$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ004"
$summaryPath = Join-Path $tbDir "tmq004_quantization_error_summary.txt"
$statsPath = Join-Path $reportDir "tmq004_quantization_stats.txt"
$reportPath = Join-Path $reportDir "TMQ004_final_report.md"
$svgPath = Join-Path $reportDir "tmq004_quantization_histogram.svg"
$transcriptPath = Join-Path $reportDir "TMQ004_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq004_quantization_error.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source
$svgCulture = [System.Globalization.CultureInfo]::InvariantCulture

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

Remove-Item -LiteralPath $summaryPath -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $transcriptPath -ErrorAction SilentlyContinue

Push-Location $scriptDir
try {
    $simWallClock = Measure-Command {
        & $vsim -c -do $doFile | Tee-Object -FilePath $transcriptPath
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path $summaryPath)) {
    throw "Resumo da simulacao nao foi gerado: $summaryPath"
}

$summary = @{}
foreach ($line in Get-Content -LiteralPath $summaryPath) {
    if ($line -match "^\s*([^=]+)=(.*)$") {
        $summary[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$stablePoints = [int]$summary["stable_outputs"]
if ($stablePoints -le 0) {
    throw "A simulacao nao gerou pontos estaveis para analise."
}

function SvgNum([double]$Value) {
    return [string]::Format($svgCulture, "{0:F2}", $Value)
}

function SvgFmt([string]$Pattern, [double]$Value) {
    return [string]::Format($svgCulture, $Pattern, $Value)
}

$sumError = [double]$summary["sum_error"]
$sumErrorSq = [double]$summary["sum_error_sq"]
$meanError = $sumError / $stablePoints
$mse = $sumErrorSq / $stablePoints
$rmsError = [Math]::Sqrt($mse)
$variance = $mse - ($meanError * $meanError)
if ($variance -lt 0.0) { $variance = 0.0 }
$stdDev = [Math]::Sqrt($variance)
$maxAbsError = [double]$summary["max_abs_error_lsb"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$latencyCycles = [int]$summary["measured_latency"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]
$passFlag = [int]$summary["pass_flag"]

$histMin = [int]$summary["hist_min_bin"]
$histMax = [int]$summary["hist_max_bin"]
$histogram = [System.Collections.Generic.List[object]]::new()
$maxCount = 0
for ($bin = $histMin; $bin -le $histMax; $bin++) {
    $count = [int]$summary["hist_bin_$bin"]
    if ($count -gt $maxCount) { $maxCount = $count }
    $histogram.Add([pscustomobject]@{
        bin = $bin
        count = $count
    }) | Out-Null
}

$stats = @(
    "test_name=TMQ004_QuantizationErrorAnalysis",
    "stable_points=$stablePoints",
    "mean_error_lsb=$([string]::Format('{0:F12}', $meanError))",
    "max_error_lsb=$([string]::Format('{0:F12}', $maxAbsError))",
    "rms_error_lsb=$([string]::Format('{0:F12}', $rmsError))",
    "stddev_error_lsb=$([string]::Format('{0:F12}', $stdDev))",
    "overflow_rate_pct=$([string]::Format('{0:F6}', $overflowRatePct))",
    "delivery_rate_pct=$([string]::Format('{0:F6}', $deliveryRatePct))",
    "measured_latency_cycles=$latencyCycles",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format('{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format('{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$width = 1280.0
$height = 720.0
$left = 100.0
$right = 60.0
$top = 70.0
$bottom = 90.0
$plotW = $width - $left - $right
$plotH = $height - $top - $bottom
$barCount = $histogram.Count
$barWidth = $plotW / $barCount
$bars = [System.Collections.Generic.List[string]]::new()

for ($i = 0; $i -lt $barCount; $i++) {
    $entry = $histogram[$i]
    $barH = if ($maxCount -gt 0) { ($entry.count / $maxCount) * $plotH } else { 0.0 }
    $x = $left + ($i * $barWidth) + 2
    $y = $top + $plotH - $barH
    $w = [Math]::Max(1.0, $barWidth - 4)
    $bars.Add("<rect x='$(SvgNum $x)' y='$(SvgNum $y)' width='$(SvgNum $w)' height='$(SvgNum $barH)' fill='#0f766e'/>") | Out-Null
}

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='$(SvgNum $width)' height='$(SvgNum $height)' viewBox='0 0 $(SvgNum $width) $(SvgNum $height)'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='40' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ004 - Quantization Error Histogram</text>",
    "<text x='40' y='66' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Error E = x_ideal - x_fixed in LSB units</text>",
    "<rect x='$(SvgNum $left)' y='$(SvgNum $top)' width='$(SvgNum $plotW)' height='$(SvgNum $plotH)' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>"
)
$svg += $bars

for ($i = 0; $i -le 4; $i++) {
    $yVal = [Math]::Round($maxCount * $i / 4.0)
    $y = $top + $plotH - (($i / 4.0) * $plotH)
    $svg += "<line x1='$(SvgNum $left)' y1='$(SvgNum $y)' x2='$(SvgNum ($left + $plotW))' y2='$(SvgNum $y)' stroke='#eadfd2' stroke-width='1'/>"
    $svg += "<text x='42' y='$(SvgNum ($y + 5))' font-size='13' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>$yVal</text>"
}

for ($i = 0; $i -lt $barCount; $i += 4) {
    $entry = $histogram[$i]
    $x = $left + ($i * $barWidth) + ($barWidth / 2.0)
    $svg += "<text x='$(SvgNum ($x - 10))' y='$(SvgNum ($top + $plotH + 26))' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>$($entry.bin)</text>"
}

$svg += "<text x='$(SvgNum ($width / 2.0 - 45))' y='$(SvgNum ($height - 24))' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Error Bin [LSB]</text>"
$svg += "<text transform='translate(28 $(SvgNum ($top + $plotH / 2.0))) rotate(-90)' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Occurrences</text>"
$svg += "<text x='40' y='$(SvgNum ($height - 52))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Mean: $(SvgFmt '{0:F12}' $meanError) | RMS: $(SvgFmt '{0:F12}' $rmsError) | StdDev: $(SvgFmt '{0:F12}' $stdDev) | Max: $(SvgFmt '{0:F12}' $maxAbsError)</text>"
$svg += "<text x='40' y='$(SvgNum ($height - 30))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Stable points: $stablePoints | Overflow rate: $(SvgFmt '{0:F6}' $overflowRatePct) % | PASS: $passFlag</text>"
$svg += "</svg>"

Set-Content -LiteralPath $svgPath -Value ($svg -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ004 - Quantization Error Analysis",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ004_QuantizationErrorAnalysis",
    "- Objective: Quantify ideal versus fixed-point output error in a style typical of IEEE articles.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis.v",
    "- Stable amplitudes analyzed: $stablePoints",
    "",
    "## Error Metrics",
    "",
    "- Maximum Error [LSB]: $([string]::Format('{0:F12}', $maxAbsError))",
    "- Mean Error [LSB]: $([string]::Format('{0:F12}', $meanError))",
    "- RMS Error [LSB]: $([string]::Format('{0:F12}', $rmsError))",
    "- Standard Deviation [LSB]: $([string]::Format('{0:F12}', $stdDev))",
    "",
    "## Execution Summary",
    "",
    "- Delivery Rate: $([string]::Format('{0:F6}', $deliveryRatePct)) %",
    "- Measured Latency: $latencyCycles cycles",
    "- Simulation Time: $([string]::Format('{0:F0}', $simTimeNs)) ns",
    "- Wall Clock: $([string]::Format('{0:F3}', $simWallClock.TotalSeconds)) s",
    "- Overflow Rate: $([string]::Format('{0:F6}', $overflowRatePct)) %",
    "- PASS Flag: $passFlag",
    "",
    "## Histogram",
    "",
    "- The histogram shows the empirical distribution of quantization error in integer LSB bins.",
    "- This is the artifact typically used to characterize fixed-point behavior scientifically.",
    "",
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq004_quantization_error_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ004/tmq004_quantization_stats.txt",
    "- Histogram SVG: tb_v3_2/results/TMQ004/tmq004_quantization_histogram.svg",
    "- Final Report: tb_v3_2/results/TMQ004/TMQ004_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ004/TMQ004_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ004 - Quantization Error Analysis"
Write-Host "======================================================================"
Write-Host "Summary TXT   : $summaryPath"
Write-Host "Stats TXT     : $statsPath"
Write-Host "Histogram SVG : $svgPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "Mean Error    : $([string]::Format('{0:F12}', $meanError))"
Write-Host "RMS Error     : $([string]::Format('{0:F12}', $rmsError))"
Write-Host "StdDev Error  : $([string]::Format('{0:F12}', $stdDev))"
Write-Host "Max Abs Error : $([string]::Format('{0:F12}', $maxAbsError))"
