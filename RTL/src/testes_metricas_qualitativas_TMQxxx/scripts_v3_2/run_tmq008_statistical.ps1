$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ008"
$summaryPath = Join-Path $tbDir "tmq008_statistical_summary.txt"
$statsPath = Join-Path $reportDir "tmq008_statistical_stats.txt"
$reportPath = Join-Path $reportDir "TMQ008_final_report.md"
$svgPath = Join-Path $reportDir "tmq008_statistical_dashboard.svg"
$transcriptPath = Join-Path $reportDir "TMQ008_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq008_statistical.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source

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

$passFlag = [int]$summary["pass_flag"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$overflowTotal = [int]$summary["overflow_total"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$xzErrors = [int]$summary["xz_errors"]
$meanRe = [double]$summary["mean_re"]
$meanIm = [double]$summary["mean_im"]
$varRe = [double]$summary["variance_re"]
$varIm = [double]$summary["variance_im"]
$stdRe = [double]$summary["stddev_re"]
$stdIm = [double]$summary["stddev_im"]
$minRe = [double]$summary["min_re"]
$maxRe = [double]$summary["max_re"]
$minIm = [double]$summary["min_im"]
$maxIm = [double]$summary["max_im"]
$meanMag = [double]$summary["mean_magnitude"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ008_StatisticalCharacterization",
    "delivery_rate_pct=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $deliveryRatePct))",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "overflow_total=$overflowTotal",
    "overflow_rate_pct=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $overflowRatePct))",
    "xz_errors=$xzErrors",
    "mean_re=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $meanRe))",
    "mean_im=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $meanIm))",
    "variance_re=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $varRe))",
    "variance_im=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $varIm))",
    "stddev_re=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $stdRe))",
    "stddev_im=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $stdIm))",
    "min_re=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $minRe))",
    "max_re=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $maxRe))",
    "min_im=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $minIm))",
    "max_im=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $maxIm))",
    "mean_magnitude=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $meanMag))",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$histRe = 0..7 | ForEach-Object { [int]$summary["hist_re_$_"] }
$histIm = 0..7 | ForEach-Object { [int]$summary["hist_im_$_"] }
$maxHist = ([Math]::Max(($histRe | Measure-Object -Maximum).Maximum, ($histIm | Measure-Object -Maximum).Maximum))
if ($maxHist -le 0) { $maxHist = 1 }

$barX = 90
$barYBase = 600
$barWidth = 48
$barGap = 18
$scale = 220.0 / $maxHist
$svgLines = New-Object System.Collections.Generic.List[string]
$svgLines.Add("<svg xmlns='http://www.w3.org/2000/svg' width='1400' height='820' viewBox='0 0 1400 820'>")
$svgLines.Add("<rect width='100%' height='100%' fill='#f6efe3'/>")
$svgLines.Add("<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ008 - Statistical Characterization</text>")
$svgLines.Add("<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>100000 random complex vectors with DSP-style statistical output metrics</text>")
$svgLines.Add("<rect x='50' y='100' width='560' height='240' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<rect x='640' y='100' width='710' height='240' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<text x='80' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Core Statistics</text>")
$svgLines.Add("<text x='80' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>PASS Flag: $passFlag</text>")
$svgLines.Add("<text x='80' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Mean RE: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $meanRe))</text>")
$svgLines.Add("<text x='80' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Mean IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $meanIm))</text>")
$svgLines.Add("<text x='80' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>StdDev RE: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $stdRe))</text>")
$svgLines.Add("<text x='80' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>StdDev IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $stdIm))</text>")
$svgLines.Add("<text x='670' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Range and Execution</text>")
$svgLines.Add("<text x='670' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Min/Max RE: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F4}', $minRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F4}', $maxRe))</text>")
$svgLines.Add("<text x='670' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Min/Max IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F4}', $minIm)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F4}', $maxIm))</text>")
$svgLines.Add("<text x='670' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Variance RE/IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $varRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $varIm))</text>")
$svgLines.Add("<text x='670' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Mean Magnitude: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $meanMag))</text>")
$svgLines.Add("<text x='670' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Latency: $measuredLatency / $expectedLatency cycles | X/Z: $xzErrors | Overflow: $overflowTotal</text>")
$svgLines.Add("<rect x='50' y='380' width='1300' height='380' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<text x='80' y='420' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Output Distribution Histogram</text>")
$svgLines.Add("<line x1='80' y1='600' x2='1320' y2='600' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<line x1='80' y1='600' x2='80' y2='440' stroke='#5d4e41' stroke-width='1.5'/>")

for ($i = 0; $i -lt 8; $i++) {
    $xRe = $barX + ($i * ($barWidth + $barGap) * 2)
    $xIm = $xRe + $barWidth + 8
    $hRe = [int]([Math]::Round($histRe[$i] * $scale))
    $hIm = [int]([Math]::Round($histIm[$i] * $scale))
    $yRe = $barYBase - $hRe
    $yIm = $barYBase - $hIm
    $svgLines.Add("<rect x='$xRe' y='$yRe' width='$barWidth' height='$hRe' fill='#2563eb' opacity='0.85'/>")
    $svgLines.Add("<rect x='$xIm' y='$yIm' width='$barWidth' height='$hIm' fill='#c2410c' opacity='0.80'/>")
    $labelX = $xRe - 6
    $svgLines.Add("<text x='$labelX' y='630' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>B$i</text>")
}

$svgLines.Add("<text x='1080' y='450' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Blue: RE histogram</text>")
$svgLines.Add("<text x='1080' y='480' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Orange: IM histogram</text>")
$svgLines.Add("<text x='80' y='690' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Bins span the normalized Q1.15 interval from -1.0 to +1.0 in 8 equal ranges.</text>")
$svgLines.Add("</svg>")

Set-Content -LiteralPath $svgPath -Value ($svgLines -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ008 - Statistical Characterization",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ008_StatisticalCharacterization",
    "- Objective: Characterize mean, variance, standard deviation, distribution and extrema under 100000 random complex vectors.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ008_StatisticalCharacterization.v",
    "",
    "## Statistical Result",
    "",
    "- PASS Flag: $passFlag",
    "- Mean RE / IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $meanRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $meanIm))",
    "- Variance RE / IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $varRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $varIm))",
    "- StdDev RE / IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $stdRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $stdIm))",
    "- Min RE / Max RE: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $minRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $maxRe))",
    "- Min IM / Max IM: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $minIm)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $maxIm))",
    "- Mean Magnitude: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F12}', $meanMag))",
    "",
    "## Execution Summary",
    "",
    "- Delivery Rate: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $deliveryRatePct)) %",
    "- Expected Latency: $expectedLatency cycles",
    "- Measured Latency: $measuredLatency cycles",
    "- Overflow Events: $overflowTotal",
    "- X/Z Errors: $xzErrors",
    "- Simulation Time: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F0}', $simTimeNs)) ns",
    "- Wall Clock: $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F3}', $simWallClock.TotalSeconds)) s",
    "",
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq008_statistical_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ008/tmq008_statistical_stats.txt",
    "- Statistical SVG: tb_v3_2/results/TMQ008/tmq008_statistical_dashboard.svg",
    "- Final Report: tb_v3_2/results/TMQ008/TMQ008_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ008/TMQ008_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ008 - Statistical Characterization"
Write-Host "======================================================================"
Write-Host "Summary TXT    : $summaryPath"
Write-Host "Stats TXT      : $statsPath"
Write-Host "Statistical SVG: $svgPath"
Write-Host "Final Report   : $reportPath"
Write-Host "Transcript     : $transcriptPath"
Write-Host "PASS Flag      : $passFlag"
Write-Host "Mean RE / IM   : $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $meanRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $meanIm))"
Write-Host "StdDev RE / IM : $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $stdRe)) / $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture,'{0:F6}', $stdIm))"
