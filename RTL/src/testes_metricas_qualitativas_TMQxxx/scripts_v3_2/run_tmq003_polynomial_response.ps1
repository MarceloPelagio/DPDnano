$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ003"
$csvPath = Join-Path $tbDir "tmq003_polynomial_response_samples.csv"
$summaryPath = Join-Path $tbDir "tmq003_polynomial_response_summary.txt"
$curveCsvPath = Join-Path $reportDir "tmq003_polynomial_curves.csv"
$statsCsvPath = Join-Path $reportDir "tmq003_polynomial_response_stats.csv"
$reportPath = Join-Path $reportDir "TMQ003_final_report.md"
$svgPath = Join-Path $reportDir "tmq003_polynomial_response.svg"
$transcriptPath = Join-Path $reportDir "TMQ003_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq003_polynomial_response.do"
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

$curveTable = [System.Collections.Generic.List[object]]::new()
$stats = [System.Collections.Generic.List[object]]::new()

$sumLinear = 0.0
$sumPoly = 0.0
$sumOutput = 0.0
$maxPolyRatio = 0.0
$maxOutputMinusLinear = [double]::NegativeInfinity
$minOutputMinusLinear = [double]::PositiveInfinity

foreach ($row in $rows) {
    $input = [double]$row.input_re
    $linear = [double]$row.linear_re_q15
    $poly = [double]$row.poly_re_q15
    $output = [double]$row.output_re
    $polyRatio = if ($linear -ne 0.0) { $poly / $linear } else { 0.0 }
    $delta = $output - $linear

    $sumLinear += $linear
    $sumPoly += $poly
    $sumOutput += $output
    if ([Math]::Abs($polyRatio) -gt $maxPolyRatio) { $maxPolyRatio = [Math]::Abs($polyRatio) }
    if ($delta -gt $maxOutputMinusLinear) { $maxOutputMinusLinear = $delta }
    if ($delta -lt $minOutputMinusLinear) { $minOutputMinusLinear = $delta }

    $curveTable.Add([pscustomobject]@{
        level_idx           = [int]$row.level_idx
        input_amplitude     = [int]$row.input_re
        linear_term         = [int]$row.linear_re_q15
        polynomial_term     = [int]$row.poly_re_q15
        final_output        = [int]$row.output_re
        poly_to_linear      = [Math]::Round($polyRatio, 9)
        output_minus_linear = [int]$delta
    }) | Out-Null
}

$count = $curveTable.Count
$avgLinear = $sumLinear / $count
$avgPoly = $sumPoly / $count
$avgOutput = $sumOutput / $count

$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]
$latencyCycles = [int]$summary["measured_latency"]
$txCount = [int]$summary["vectors_tx"]
$rxCount = [int]$summary["vectors_rx"]
$passFlag = [int]$summary["pass_flag"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]

$curveTable | Export-Csv -LiteralPath $curveCsvPath -NoTypeInformation -Encoding UTF8

Add-Stat $stats "stable_points" $count
Add-Stat $stats "vectors_tx" $txCount
Add-Stat $stats "vectors_rx" $rxCount
Add-Stat $stats "delivery_rate_pct" ([string]::Format("{0:F6}", $deliveryRatePct))
Add-Stat $stats "measured_latency_cycles" $latencyCycles
Add-Stat $stats "simulation_cycles" $simCycles
Add-Stat $stats "simulation_time_ns" ([string]::Format("{0:F0}", $simTimeNs))
Add-Stat $stats "wall_clock_seconds" ([string]::Format("{0:F3}", $simWallClock.TotalSeconds))
Add-Stat $stats "average_linear_term" ([string]::Format("{0:F6}", $avgLinear))
Add-Stat $stats "average_polynomial_term" ([string]::Format("{0:F6}", $avgPoly))
Add-Stat $stats "average_final_output" ([string]::Format("{0:F6}", $avgOutput))
Add-Stat $stats "max_linear_abs" $summary["max_linear_abs"]
Add-Stat $stats "max_poly_abs" $summary["max_poly_abs"]
Add-Stat $stats "max_output_abs" $summary["max_output_abs"]
Add-Stat $stats "max_abs_poly_to_linear_ratio" ([string]::Format("{0:F9}", $maxPolyRatio))
Add-Stat $stats "max_output_minus_linear" ([string]::Format("{0:F0}", $maxOutputMinusLinear))
Add-Stat $stats "min_output_minus_linear" ([string]::Format("{0:F0}", $minOutputMinusLinear))
Add-Stat $stats "overflow_rate_pct" ([string]::Format("{0:F6}", $overflowRatePct))
Add-Stat $stats "pass_flag" $passFlag

$stats | Export-Csv -LiteralPath $statsCsvPath -NoTypeInformation -Encoding UTF8

$width = 1280.0
$height = 720.0
$left = 110.0
$right = 70.0
$top = 70.0
$bottom = 90.0
$plotW = $width - $left - $right
$plotH = $height - $top - $bottom
$xMin = [double]($curveTable | Measure-Object input_amplitude -Minimum).Minimum
$xMax = [double]($curveTable | Measure-Object input_amplitude -Maximum).Maximum
$allY = @()
$allY += $curveTable | ForEach-Object { [double]$_.linear_term }
$allY += $curveTable | ForEach-Object { [double]$_.polynomial_term }
$allY += $curveTable | ForEach-Object { [double]$_.final_output }
$yMin = ($allY | Measure-Object -Minimum).Minimum
$yMax = ($allY | Measure-Object -Maximum).Maximum

function Map-X([double]$x) {
    if ($xMax -eq $xMin) { return $left }
    return $left + (($x - $xMin) / ($xMax - $xMin)) * $plotW
}

function Map-Y([double]$y) {
    if ($yMax -eq $yMin) { return $top + $plotH / 2.0 }
    return $top + $plotH - (($y - $yMin) / ($yMax - $yMin)) * $plotH
}

$linearPoints = foreach ($entry in $curveTable) {
    "{0},{1}" -f (SvgNum (Map-X([double]$entry.input_amplitude))), (SvgNum (Map-Y([double]$entry.linear_term)))
}
$polyPoints = foreach ($entry in $curveTable) {
    "{0},{1}" -f (SvgNum (Map-X([double]$entry.input_amplitude))), (SvgNum (Map-Y([double]$entry.polynomial_term)))
}
$outputPoints = foreach ($entry in $curveTable) {
    "{0},{1}" -f (SvgNum (Map-X([double]$entry.input_amplitude))), (SvgNum (Map-Y([double]$entry.final_output)))
}

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='$(SvgNum $width)' height='$(SvgNum $height)' viewBox='0 0 $(SvgNum $width) $(SvgNum $height)'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='40' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ003 - Polynomial Response Characterization</text>",
    "<text x='40' y='66' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Linear term, polynomial term and final output versus input amplitude</text>",
    "<rect x='$(SvgNum $left)' y='$(SvgNum $top)' width='$(SvgNum $plotW)' height='$(SvgNum $plotH)' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<polyline fill='none' stroke='#2563eb' stroke-width='2.6' points='" + ($linearPoints -join " ") + "'/>",
    "<polyline fill='none' stroke='#c2410c' stroke-width='2.6' points='" + ($polyPoints -join " ") + "'/>",
    "<polyline fill='none' stroke='#0f766e' stroke-width='2.8' points='" + ($outputPoints -join " ") + "'/>",
    "<text x='$(SvgNum ($left + $plotW - 215))' y='$(SvgNum ($top + 24))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Linear</text>",
    "<line x1='$(SvgNum ($left + $plotW - 290))' y1='$(SvgNum ($top + 19))' x2='$(SvgNum ($left + $plotW - 225))' y2='$(SvgNum ($top + 19))' stroke='#2563eb' stroke-width='3'/>",
    "<text x='$(SvgNum ($left + $plotW - 215))' y='$(SvgNum ($top + 46))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Polynomial</text>",
    "<line x1='$(SvgNum ($left + $plotW - 290))' y1='$(SvgNum ($top + 41))' x2='$(SvgNum ($left + $plotW - 225))' y2='$(SvgNum ($top + 41))' stroke='#c2410c' stroke-width='3'/>",
    "<text x='$(SvgNum ($left + $plotW - 215))' y='$(SvgNum ($top + 68))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Output</text>",
    "<line x1='$(SvgNum ($left + $plotW - 290))' y1='$(SvgNum ($top + 63))' x2='$(SvgNum ($left + $plotW - 225))' y2='$(SvgNum ($top + 63))' stroke='#0f766e' stroke-width='3'/>",
    "<text x='$(SvgNum ($width / 2 - 60))' y='$(SvgNum ($height - 24))' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Input Amplitude</text>",
    "<text transform='translate(28 $(SvgNum ($top + $plotH / 2))) rotate(-90)' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Amplitude</text>"
)

for ($i = 0; $i -le 5; $i++) {
    $xTickVal = $xMin + (($xMax - $xMin) * $i / 5.0)
    $xTick = Map-X($xTickVal)
    $svg += "<line x1='$(SvgNum $xTick)' y1='$(SvgNum ($top + $plotH))' x2='$(SvgNum $xTick)' y2='$(SvgNum ($top + $plotH + 8))' stroke='#5d4e41' stroke-width='1.2'/>"
    $svg += "<text x='$(SvgNum ($xTick - 20))' y='$(SvgNum ($top + $plotH + 30))' font-size='13' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>{0:F0}</text>" -f $xTickVal
}

for ($i = 0; $i -le 5; $i++) {
    $yTickVal = $yMin + (($yMax - $yMin) * $i / 5.0)
    $yTick = Map-Y($yTickVal)
    $svg += "<line x1='$(SvgNum ($left - 8))' y1='$(SvgNum $yTick)' x2='$(SvgNum $left)' y2='$(SvgNum $yTick)' stroke='#5d4e41' stroke-width='1.2'/>"
    $svg += "<line x1='$(SvgNum $left)' y1='$(SvgNum $yTick)' x2='$(SvgNum ($left + $plotW))' y2='$(SvgNum $yTick)' stroke='#eadfd2' stroke-width='1'/>"
    $svg += "<text x='24' y='$(SvgNum ($yTick + 5))' font-size='13' font-family='Segoe UI, Arial, sans-serif' fill='#5d4e41'>{0:F0}</text>" -f $yTickVal
}

    $svg += "<text x='40' y='$(SvgNum ($height - 52))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Average Linear: $(SvgFmt '{0:F2}' $avgLinear) | Average Polynomial: $(SvgFmt '{0:F2}' $avgPoly) | Average Output: $(SvgFmt '{0:F2}' $avgOutput)</text>"
$svg += "<text x='40' y='$(SvgNum ($height - 30))' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Max |Poly/Linear|: $(SvgFmt '{0:F9}' $maxPolyRatio) | PASS: $passFlag</text>"
$svg += "</svg>"

Set-Content -LiteralPath $svgPath -Value ($svg -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ003 - Polynomial Response Characterization",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ003_PolynomialResponseCharacterization",
    "- Objective: Evidenciar como o poly_branch trabalha ao longo da variacao continua de x.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization.v",
    "- Stable amplitudes analyzed: $count",
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
    "## Response Metrics",
    "",
    "- Average Linear Term: $([string]::Format('{0:F6}', $avgLinear))",
    "- Average Polynomial Term: $([string]::Format('{0:F6}', $avgPoly))",
    "- Average Final Output: $([string]::Format('{0:F6}', $avgOutput))",
    "- Max |Linear|: $($summary['max_linear_abs'])",
    "- Max |Polynomial|: $($summary['max_poly_abs'])",
    "- Max |Output|: $($summary['max_output_abs'])",
    "- Max |Polynomial / Linear|: $([string]::Format('{0:F9}', $maxPolyRatio))",
    "- Max Output - Linear: $([string]::Format('{0:F0}', $maxOutputMinusLinear))",
    "- Min Output - Linear: $([string]::Format('{0:F0}', $minOutputMinusLinear))",
    "",
    "## Interpretation",
    "",
    "- The blue curve shows the linear branch contribution.",
    "- The orange curve shows the polynomial branch contribution.",
    "- The green curve shows the final combined output.",
    "- The relative separation between orange and blue makes the poly_branch action explicit.",
    "",
    "## Artifacts",
    "",
    "- Samples CSV: tb_v3_2/tmq003_polynomial_response_samples.csv",
    "- Curve CSV: tb_v3_2/results/TMQ003/tmq003_polynomial_curves.csv",
    "- Stats CSV: tb_v3_2/results/TMQ003/tmq003_polynomial_response_stats.csv",
    "- Plot SVG: tb_v3_2/results/TMQ003/tmq003_polynomial_response.svg",
    "- Final Report: tb_v3_2/results/TMQ003/TMQ003_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ003/TMQ003_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ003 - Polynomial Response Characterization"
Write-Host "======================================================================"
Write-Host "Samples CSV   : $csvPath"
Write-Host "Curve CSV     : $curveCsvPath"
Write-Host "Stats CSV     : $statsCsvPath"
Write-Host "Plot SVG      : $svgPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "Max |Poly|    : $($summary['max_poly_abs'])"
Write-Host "Wall Clock    : $([string]::Format('{0:F3}', $simWallClock.TotalSeconds)) s"
