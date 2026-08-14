$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ005"
$summaryPath = Join-Path $tbDir "tmq005_numerical_precision_summary.txt"
$statsPath = Join-Path $reportDir "tmq005_numerical_precision_stats.txt"
$reportPath = Join-Path $reportDir "TMQ005_final_report.md"
$svgPath = Join-Path $reportDir "tmq005_numerical_precision_bars.svg"
$transcriptPath = Join-Path $reportDir "TMQ005_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq005_numerical_precision.do"
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

$rmsErrorRe = [Math]::Sqrt(([double]$summary["sum_error_sq_re"]) / $stablePoints)
$rmsErrorIm = [Math]::Sqrt(([double]$summary["sum_error_sq_im"]) / $stablePoints)
$rmsErrorMag = [Math]::Sqrt(([double]$summary["sum_error_sq_mag"]) / $stablePoints)
$maxErrorRe = [double]$summary["max_abs_error_re_lsb"]
$maxErrorIm = [double]$summary["max_abs_error_im_lsb"]
$maxErrorMag = [double]$summary["max_abs_error_mag_lsb"]
$percentErrorRmsMag = [double]$summary["percent_error_rms_mag"]
$percentErrorMaxMag = [double]$summary["percent_error_max_mag"]
$saturationPoints = [int]$summary["saturation_points"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$latencyCycles = [int]$summary["measured_latency"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]
$passFlag = [int]$summary["pass_flag"]
$maxErrorSource = [int]$summary["max_error_source"]

$sourceLabel = "pipeline_or_fixed_point"
if ($maxErrorSource -eq 2) { $sourceLabel = "rounding_or_clip" }
elseif ($maxErrorSource -eq 3) { $sourceLabel = "saturation_or_overflow" }

$stats = @(
    "test_name=TMQ005_NumericalPrecision",
    "stable_points=$stablePoints",
    "rms_error_re_lsb=$([string]::Format('{0:F12}', $rmsErrorRe))",
    "rms_error_im_lsb=$([string]::Format('{0:F12}', $rmsErrorIm))",
    "rms_error_mag_lsb=$([string]::Format('{0:F12}', $rmsErrorMag))",
    "max_error_re_lsb=$([string]::Format('{0:F12}', $maxErrorRe))",
    "max_error_im_lsb=$([string]::Format('{0:F12}', $maxErrorIm))",
    "max_error_mag_lsb=$([string]::Format('{0:F12}', $maxErrorMag))",
    "percent_error_rms_mag=$([string]::Format('{0:F12}', $percentErrorRmsMag))",
    "percent_error_max_mag=$([string]::Format('{0:F12}', $percentErrorMaxMag))",
    "saturation_points=$saturationPoints",
    "max_error_source=$sourceLabel",
    "overflow_rate_pct=$([string]::Format('{0:F6}', $overflowRatePct))",
    "delivery_rate_pct=$([string]::Format('{0:F6}', $deliveryRatePct))",
    "measured_latency_cycles=$latencyCycles",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format('{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format('{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$metrics = @(
    @{ label = "RMS RE [LSB]"; value = $rmsErrorRe; color = "#0f766e" },
    @{ label = "RMS IM [LSB]"; value = $rmsErrorIm; color = "#2563eb" },
    @{ label = "RMS MAG [LSB]"; value = $rmsErrorMag; color = "#7c3aed" },
    @{ label = "MAX MAG [LSB]"; value = $maxErrorMag; color = "#c2410c" },
    @{ label = "RMS MAG [%]"; value = $percentErrorRmsMag; color = "#b45309" },
    @{ label = "MAX MAG [%]"; value = $percentErrorMaxMag; color = "#dc2626" }
)

$maxMetric = (($metrics | ForEach-Object { [double]$_.value }) | Measure-Object -Maximum).Maximum
if ($maxMetric -le 0.0) { $maxMetric = 1.0 }

$width = 1280.0
$height = 720.0
$left = 120.0
$right = 80.0
$top = 80.0
$bottom = 110.0
$plotW = $width - $left - $right
$plotH = $height - $top - $bottom
$barWidth = 108.0
$spacing = 58.0
$startX = $left + 30.0

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='$(SvgNum $width)' height='$(SvgNum $height)' viewBox='0 0 $(SvgNum $width) $(SvgNum $height)'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='40' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ005 - Numerical Precision</text>",
    "<text x='40' y='66' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Complex-IQ numerical precision with non-zero real and imaginary polynomial coefficients</text>",
    "<rect x='$(SvgNum $left)' y='$(SvgNum $top)' width='$(SvgNum $plotW)' height='$(SvgNum $plotH)' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>"
)

for ($i = 0; $i -lt $metrics.Count; $i++) {
    $m = $metrics[$i]
    $x = $startX + ($i * ($barWidth + $spacing))
    $barH = ($m.value / $maxMetric) * ($plotH - 40.0)
    $y = $top + $plotH - $barH
    $svg += "<rect x='$(SvgNum $x)' y='$(SvgNum $y)' width='$(SvgNum $barWidth)' height='$(SvgNum $barH)' fill='$($m.color)'/>"
    $svg += "<text x='$(SvgNum ($x - 6))' y='$(SvgNum ($top + $plotH + 28))' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>$($m.label)</text>"
    $svg += "<text x='$(SvgNum ($x + 6))' y='$(SvgNum ($y - 10))' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt '{0:F6}' ([double]$m.value))</text>"
}

for ($i = 0; $i -le 4; $i++) {
    $tickVal = $maxMetric * $i / 4.0
    $y = $top + $plotH - (($i / 4.0) * ($plotH - 40.0))
    $svg += "<line x1='$(SvgNum $left)' y1='$(SvgNum $y)' x2='$(SvgNum ($left + $plotW))' y2='$(SvgNum $y)' stroke='#eadfd2' stroke-width='1'/>"
    $svg += "<text x='42' y='$(SvgNum ($y + 5))' font-size='13' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>$(SvgFmt '{0:F4}' $tickVal)</text>"
}

$svg += "<text transform='translate(28 $(SvgNum ($top + $plotH / 2.0))) rotate(-90)' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Metric Value</text>"
$svg += "<text x='40' y='$(SvgNum ($height - 52))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Saturation points: $saturationPoints | Max error source: $sourceLabel | Overflow rate: $(SvgFmt '{0:F6}' $overflowRatePct) %</text>"
$svg += "<text x='40' y='$(SvgNum ($height - 30))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Stable points: $stablePoints | Latency: $latencyCycles cycles | PASS: $passFlag</text>"
$svg += "</svg>"

Set-Content -LiteralPath $svgPath -Value ($svg -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ005 - Numerical Precision",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ005_NumericalPrecision",
    "- Objective: Evaluate numerical error introduced by fixed-point arithmetic, rounding, saturation and pipeline accumulation under fully complex polynomial excitation.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ005_NumericalPrecision.v",
    "- Stable amplitudes analyzed: $stablePoints",
    "",
    "## Precision Metrics",
    "",
    "- RMS Error RE [LSB]: $([string]::Format('{0:F12}', $rmsErrorRe))",
    "- RMS Error IM [LSB]: $([string]::Format('{0:F12}', $rmsErrorIm))",
    "- RMS Error MAG [LSB]: $([string]::Format('{0:F12}', $rmsErrorMag))",
    "- Maximum Error RE [LSB]: $([string]::Format('{0:F12}', $maxErrorRe))",
    "- Maximum Error IM [LSB]: $([string]::Format('{0:F12}', $maxErrorIm))",
    "- Maximum Error MAG [LSB]: $([string]::Format('{0:F12}', $maxErrorMag))",
    "- RMS Error MAG [%]: $([string]::Format('{0:F12}', $percentErrorRmsMag))",
    "- Maximum Error MAG [%]: $([string]::Format('{0:F12}', $percentErrorMaxMag))",
    "- Saturation Points: $saturationPoints",
    "- Max Error Source: $sourceLabel",
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
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq005_numerical_precision_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ005/tmq005_numerical_precision_stats.txt",
    "- Precision SVG: tb_v3_2/results/TMQ005/tmq005_numerical_precision_bars.svg",
    "- Final Report: tb_v3_2/results/TMQ005/TMQ005_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ005/TMQ005_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ005 - Numerical Precision"
Write-Host "======================================================================"
Write-Host "Summary TXT   : $summaryPath"
Write-Host "Stats TXT     : $statsPath"
Write-Host "Precision SVG : $svgPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "RMS Error RE  : $([string]::Format('{0:F12}', $rmsErrorRe))"
Write-Host "RMS Error IM  : $([string]::Format('{0:F12}', $rmsErrorIm))"
Write-Host "RMS Error MAG : $([string]::Format('{0:F12}', $rmsErrorMag))"
Write-Host "Max Error MAG : $([string]::Format('{0:F12}', $maxErrorMag))"
Write-Host "RMS Error %   : $([string]::Format('{0:F12}', $percentErrorRmsMag))"
Write-Host "Max Error %   : $([string]::Format('{0:F12}', $percentErrorMaxMag))"
