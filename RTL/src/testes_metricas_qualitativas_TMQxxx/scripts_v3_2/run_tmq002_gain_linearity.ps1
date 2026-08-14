$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ002"
$csvPath = Join-Path $tbDir "tmq002_gain_linearity_samples.csv"
$summaryPath = Join-Path $tbDir "tmq002_gain_linearity_summary.txt"
$gainCsvPath = Join-Path $reportDir "tmq002_gain_vs_input.csv"
$statsCsvPath = Join-Path $reportDir "tmq002_gain_linearity_stats.csv"
$reportPath = Join-Path $reportDir "TMQ002_final_report.md"
$svgPath = Join-Path $reportDir "tmq002_gain_vs_input.svg"
$transcriptPath = Join-Path $reportDir "TMQ002_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq002_gain_linearity.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source
$svgCulture = [System.Globalization.CultureInfo]::InvariantCulture

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

Remove-Item -LiteralPath $csvPath -ErrorAction SilentlyContinue
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

if (-not (Test-Path $csvPath)) {
    throw "CSV de amostras nao foi gerado: $csvPath"
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

$rows = Import-Csv -LiteralPath $csvPath | Where-Object { [int]$_.is_stable -eq 1 }
if ($rows.Count -eq 0) {
    throw "O CSV foi gerado, mas nao contem amostras estaveis."
}

function Add-Stat {
    param(
        [System.Collections.Generic.List[object]]$List,
        [string]$Metric,
        [object]$Value
    )
    $List.Add([pscustomobject]@{
        metric = $Metric
        value  = $Value
    }) | Out-Null
}

function SvgNum([double]$Value) {
    return [string]::Format($svgCulture, "{0:F2}", $Value)
}

function SvgFmt([string]$Pattern, [double]$Value) {
    return [string]::Format($svgCulture, $Pattern, $Value)
}

$gainTable = [System.Collections.Generic.List[object]]::new()
$stats = [System.Collections.Generic.List[object]]::new()

$sumGain = 0.0
$sumGainSq = 0.0
$sumInput = 0.0
$sumInputSq = 0.0
$sumInputGain = 0.0
$count = 0
$minGain = [double]::PositiveInfinity
$maxGain = [double]::NegativeInfinity
$maxDeviation = 0.0
$overflowStable = 0

foreach ($row in $rows) {
    $input = [double]$row.input_re
    $output = [double]$row.output_re
    $gain = if ($input -ne 0.0) { $output / $input } else { 0.0 }
    $idealGain = 0.5
    $deviation = [Math]::Abs($gain - $idealGain)

    if ($gain -lt $minGain) { $minGain = $gain }
    if ($gain -gt $maxGain) { $maxGain = $gain }
    if ($deviation -gt $maxDeviation) { $maxDeviation = $deviation }
    if ([int]$row.overflow -ne 0) { $overflowStable++ }

    $sumGain += $gain
    $sumGainSq += ($gain * $gain)
    $sumInput += $input
    $sumInputSq += ($input * $input)
    $sumInputGain += ($input * $gain)
    $count++

    $gainTable.Add([pscustomobject]@{
        level_idx        = [int]$row.level_idx
        input_amplitude  = [int]$row.input_re
        output_amplitude = [int]$row.output_re
        gain_linear      = [Math]::Round($gain, 9)
        ideal_gain       = [Math]::Round($idealGain, 9)
        abs_deviation    = [Math]::Round($deviation, 9)
    }) | Out-Null
}

$avgGain = $sumGain / $count
$variance = ($sumGainSq / $count) - ($avgGain * $avgGain)
if ($variance -lt 0.0) { $variance = 0.0 }
$stdDev = [Math]::Sqrt($variance)

$den = ($count * $sumInputSq) - ($sumInput * $sumInput)
$slope = if ($den -ne 0.0) { (($count * $sumInputGain) - ($sumInput * $sumGain)) / $den } else { 0.0 }
$intercept = ($avgGain) - ($slope * ($sumInput / $count))

$ssTot = 0.0
$ssRes = 0.0
foreach ($entry in $gainTable) {
    $x = [double]$entry.input_amplitude
    $y = [double]$entry.gain_linear
    $fit = ($slope * $x) + $intercept
    $ssTot += ($y - $avgGain) * ($y - $avgGain)
    $ssRes += ($y - $fit) * ($y - $fit)
}
$rSquared = if ($ssTot -gt 0.0) { 1.0 - ($ssRes / $ssTot) } else { 1.0 }

$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]
$latencyCycles = [int]$summary["measured_latency"]
$txCount = [int]$summary["vectors_tx"]
$rxCount = [int]$summary["vectors_rx"]
$passFlag = [int]$summary["pass_flag"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]

$gainTable | Export-Csv -LiteralPath $gainCsvPath -NoTypeInformation -Encoding UTF8

Add-Stat $stats "stable_points" $count
Add-Stat $stats "vectors_tx" $txCount
Add-Stat $stats "vectors_rx" $rxCount
Add-Stat $stats "delivery_rate_pct" ([string]::Format("{0:F6}", $deliveryRatePct))
Add-Stat $stats "measured_latency_cycles" $latencyCycles
Add-Stat $stats "simulation_cycles" $simCycles
Add-Stat $stats "simulation_time_ns" ([string]::Format("{0:F0}", $simTimeNs))
Add-Stat $stats "wall_clock_seconds" ([string]::Format("{0:F3}", $simWallClock.TotalSeconds))
Add-Stat $stats "average_gain_linear" ([string]::Format("{0:F9}", $avgGain))
Add-Stat $stats "ideal_gain_linear" "0.500000000"
Add-Stat $stats "min_gain_linear" ([string]::Format("{0:F9}", $minGain))
Add-Stat $stats "max_gain_linear" ([string]::Format("{0:F9}", $maxGain))
Add-Stat $stats "gain_stddev" ([string]::Format("{0:F12}", $stdDev))
Add-Stat $stats "max_abs_deviation_from_ideal" ([string]::Format("{0:F9}", $maxDeviation))
Add-Stat $stats "gain_fit_slope" ([string]::Format("{0:F12}", $slope))
Add-Stat $stats "gain_fit_intercept" ([string]::Format("{0:F12}", $intercept))
Add-Stat $stats "gain_fit_r_squared" ([string]::Format("{0:F12}", $rSquared))
Add-Stat $stats "overflow_stable_points" $overflowStable
Add-Stat $stats "overflow_rate_pct" ([string]::Format("{0:F6}", $overflowRatePct))
Add-Stat $stats "gain_pass_count" $summary["gain_pass_count"]
Add-Stat $stats "gain_fail_count" $summary["gain_fail_count"]
Add-Stat $stats "pass_flag" $passFlag

$stats | Export-Csv -LiteralPath $statsCsvPath -NoTypeInformation -Encoding UTF8

$width = 1280.0
$height = 720.0
$left = 110.0
$right = 60.0
$top = 70.0
$bottom = 90.0
$plotW = $width - $left - $right
$plotH = $height - $top - $bottom
$xMin = [double]($gainTable | Measure-Object input_amplitude -Minimum).Minimum
$xMax = [double]($gainTable | Measure-Object input_amplitude -Maximum).Maximum
$yMin = [Math]::Min(0.48, $minGain - 0.005)
$yMax = [Math]::Max(0.52, $maxGain + 0.005)

function Map-X([double]$x) {
    if ($xMax -eq $xMin) { return $left }
    return $left + (($x - $xMin) / ($xMax - $xMin)) * $plotW
}

function Map-Y([double]$y) {
    if ($yMax -eq $yMin) { return $top + $plotH / 2.0 }
    return $top + $plotH - (($y - $yMin) / ($yMax - $yMin)) * $plotH
}

$points = foreach ($entry in $gainTable) {
    "{0},{1}" -f (SvgNum (Map-X([double]$entry.input_amplitude))), (SvgNum (Map-Y([double]$entry.gain_linear)))
}
$pointString = ($points -join " ")
$idealY = Map-Y(0.5)

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='$(SvgNum $width)' height='$(SvgNum $height)' viewBox='0 0 $(SvgNum $width) $(SvgNum $height)'>",
    "<rect width='100%' height='100%' fill='#f7f1e6'/>",
    "<text x='40' y='40' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#3a2f22'>TMQ002 - Gain vs Input</text>",
    "<text x='40' y='66' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6b5b4d'>DPDnano-Lite Gain Linearity Characterization</text>",
    "<rect x='$(SvgNum $left)' y='$(SvgNum $top)' width='$(SvgNum $plotW)' height='$(SvgNum $plotH)' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<line x1='$(SvgNum $left)' y1='$(SvgNum $idealY)' x2='$(SvgNum ($left + $plotW))' y2='$(SvgNum $idealY)' stroke='#c0392b' stroke-width='2.5' stroke-dasharray='10 8'/>",
    "<polyline fill='none' stroke='#0f766e' stroke-width='2.5' points='$pointString'/>",
    "<text x='$(SvgNum ($left + 12))' y='$(SvgNum ($idealY - 12))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#c0392b'>Ideal Gain = 0.5</text>",
    "<text x='$(SvgNum ($left + $plotW - 160))' y='$(SvgNum ($top + 24))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Measured Gain</text>",
    "<line x1='$(SvgNum ($left + $plotW - 240))' y1='$(SvgNum ($top + 19))' x2='$(SvgNum ($left + $plotW - 175))' y2='$(SvgNum ($top + 19))' stroke='#0f766e' stroke-width='3'/>",
    "<text x='$(SvgNum ($width / 2 - 50))' y='$(SvgNum ($height - 24))' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#3a2f22'>Input Amplitude</text>",
    "<text transform='translate(28 $(SvgNum ($top + $plotH / 2))) rotate(-90)' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#3a2f22'>Gain</text>"
)

for ($i = 0; $i -le 5; $i++) {
    $xTickVal = $xMin + (($xMax - $xMin) * $i / 5.0)
    $xTick = Map-X($xTickVal)
    $svg += "<line x1='$(SvgNum $xTick)' y1='$(SvgNum ($top + $plotH))' x2='$(SvgNum $xTick)' y2='$(SvgNum ($top + $plotH + 8))' stroke='#5d4e41' stroke-width='1.2'/>"
    $svg += "<text x='$(SvgNum ($xTick - 20))' y='$(SvgNum ($top + $plotH + 30))' font-size='13' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>{0:F0}</text>" -f $xTickVal
}

for ($i = 0; $i -le 4; $i++) {
    $yTickVal = $yMin + (($yMax - $yMin) * $i / 4.0)
    $yTick = Map-Y($yTickVal)
    $svg += "<line x1='$(SvgNum ($left - 8))' y1='$(SvgNum $yTick)' x2='$(SvgNum $left)' y2='$(SvgNum $yTick)' stroke='#5d4e41' stroke-width='1.2'/>"
    $svg += "<line x1='$(SvgNum $left)' y1='$(SvgNum $yTick)' x2='$(SvgNum ($left + $plotW))' y2='$(SvgNum $yTick)' stroke='#e7dccf' stroke-width='1'/>"
    $svg += "<text x='32' y='$(SvgNum ($yTick + 5))' font-size='13' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>$(SvgFmt '{0:F4}' $yTickVal)</text>"
}

$svg += "<text x='40' y='$(SvgNum ($height - 52))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6b5b4d'>Average gain: $(SvgFmt '{0:F9}' $avgGain) | StdDev: $(SvgFmt '{0:F12}' $stdDev) | Max deviation: $(SvgFmt '{0:F9}' $maxDeviation)</text>"
$svg += "<text x='40' y='$(SvgNum ($height - 30))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6b5b4d'>Fit slope: $(SvgFmt '{0:F12}' $slope) | R²: $(SvgFmt '{0:F12}' $rSquared) | PASS: $passFlag</text>"
$svg += "</svg>"

Set-Content -LiteralPath $svgPath -Value ($svg -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ002 - Gain Linearity",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ002_GainLinearity",
    "- Question: A arquitetura preserva ganho constante?",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ002_GainLinearity.v",
    "- Hundreds of amplitudes executed: $count stable amplitudes",
    "",
    "## Execution Summary",
    "",
    "- Vectors TX: $txCount",
    "- Vectors RX: $rxCount",
    "- Delivery Rate: $([string]::Format('{0:F6}', $deliveryRatePct)) %",
    "- Measured Latency: $latencyCycles cycles",
    "- Simulation Time: $([string]::Format('{0:F0}', $simTimeNs)) ns",
    "- Wall Clock: $([string]::Format('{0:F3}', $simWallClock.TotalSeconds)) s",
    "- PASS Flag: $passFlag",
    "",
    "## Gain Metrics",
    "",
    "- Ideal Gain: 0.500000000",
    "- Average Gain: $([string]::Format('{0:F9}', $avgGain))",
    "- Minimum Gain: $([string]::Format('{0:F9}', $minGain))",
    "- Maximum Gain: $([string]::Format('{0:F9}', $maxGain))",
    "- Gain Standard Deviation: $([string]::Format('{0:F12}', $stdDev))",
    "- Max Absolute Deviation from Ideal: $([string]::Format('{0:F9}', $maxDeviation))",
    "- Linear Fit Slope: $([string]::Format('{0:F12}', $slope))",
    "- Linear Fit Intercept: $([string]::Format('{0:F12}', $intercept))",
    "- Linear Fit R-Squared: $([string]::Format('{0:F12}', $rSquared))",
    "",
    "## Overflow and Consistency",
    "",
    "- Stable Points with Overflow: $overflowStable",
    "- Overflow Rate: $([string]::Format('{0:F6}', $overflowRatePct)) %",
    "- Exact Gain Pass Count: $($summary['gain_pass_count'])",
    "- Exact Gain Fail Count: $($summary['gain_fail_count'])",
    "- Max Absolute Error RE: $($summary['max_abs_error_re'])",
    "",
    "## Interpretation",
    "",
    "- Ideal result: horizontal line in Gain vs Input.",
    "- Measured result: use the SVG and CSV to confirm whether gain remains effectively constant across amplitude sweep.",
    "",
    "## Artifacts",
    "",
    "- Samples CSV: tb_v3_2/tmq002_gain_linearity_samples.csv",
    "- Gain Table CSV: tb_v3_2/results/TMQ002/tmq002_gain_vs_input.csv",
    "- Stats CSV: tb_v3_2/results/TMQ002/tmq002_gain_linearity_stats.csv",
    "- Plot SVG: tb_v3_2/results/TMQ002/tmq002_gain_vs_input.svg",
    "- Final Report: tb_v3_2/results/TMQ002/TMQ002_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ002/TMQ002_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ002 - Gain Linearity"
Write-Host "======================================================================"
Write-Host "Samples CSV   : $csvPath"
Write-Host "Gain CSV      : $gainCsvPath"
Write-Host "Stats CSV     : $statsCsvPath"
Write-Host "Plot SVG      : $svgPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "Average Gain  : $([string]::Format('{0:F9}', $avgGain))"
Write-Host "Max Deviation : $([string]::Format('{0:F9}', $maxDeviation))"
Write-Host "Wall Clock    : $([string]::Format('{0:F3}', $simWallClock.TotalSeconds)) s"
