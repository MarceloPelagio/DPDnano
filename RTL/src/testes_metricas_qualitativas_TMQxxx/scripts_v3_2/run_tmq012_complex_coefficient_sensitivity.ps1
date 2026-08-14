$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ012"
$summaryPath = Join-Path $tbDir "tmq012_complex_coefficient_sensitivity_summary.txt"
$csvPath = Join-Path $tbDir "tmq012_complex_coefficient_sensitivity_map.csv"
$statsPath = Join-Path $reportDir "tmq012_complex_coefficient_sensitivity_stats.txt"
$reportPath = Join-Path $reportDir "TMQ012_final_report.md"
$svgPath = Join-Path $reportDir "tmq012_complex_safe_region.svg"
$transcriptPath = Join-Path $reportDir "TMQ012_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq012_complex_coefficient_sensitivity.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source
$culture = [System.Globalization.CultureInfo]::InvariantCulture

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

Remove-Item -LiteralPath $summaryPath -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $csvPath -ErrorAction SilentlyContinue
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

if (-not (Test-Path $csvPath)) {
    throw "Mapa CSV da simulacao nao foi gerado: $csvPath"
}

$summary = @{}
foreach ($line in Get-Content -LiteralPath $summaryPath) {
    if ($line -match "^\s*([^=]+)=(.*)$") {
        $summary[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$passFlag = [int]$summary["pass_flag"]
$totalCombos = [int]$summary["total_combos"]
$samplesPerCombo = [int]$summary["samples_per_combo"]
$testedCoeffPhasePairs = [int]$summary["tested_coeff_phase_pairs"]
$testedInputVectors = [int]$summary["tested_input_vectors"]
$safeCombos = [int]$summary["safe_combos"]
$unsafeCombos = [int]$summary["unsafe_combos"]
$safeRatioPct = [double]$summary["safe_ratio_pct"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$bestSafeC1MagQ15 = [int]$summary["best_safe_c1_mag_q15"]
$bestSafeC3MagQ15 = [int]$summary["best_safe_c3_mag_q15"]
$bestSafeC1MagReal = [double]$summary["best_safe_c1_mag_real"]
$bestSafeC3MagReal = [double]$summary["best_safe_c3_mag_real"]
$bestSafeMarginLsb = [int]$summary["best_safe_margin_lsb"]
$maxSafeAbsC1MagQ15 = [int]$summary["max_safe_abs_c1_mag_q15"]
$maxSafeAbsC3MagQ15 = [int]$summary["max_safe_abs_c3_mag_q15"]
$maxSafeAbsC1MagReal = [double]$summary["max_safe_abs_c1_mag_real"]
$maxSafeAbsC3MagReal = [double]$summary["max_safe_abs_c3_mag_real"]
$firstUnsafeC1MagQ15 = [int]$summary["first_unsafe_c1_mag_q15"]
$firstUnsafeC3MagQ15 = [int]$summary["first_unsafe_c3_mag_q15"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ012_ComplexCoefficientSensitivity",
    "total_combos=$totalCombos",
    "samples_per_combo=$samplesPerCombo",
    "tested_coeff_phase_pairs=$testedCoeffPhasePairs",
    "tested_input_vectors=$testedInputVectors",
    "safe_combos=$safeCombos",
    "unsafe_combos=$unsafeCombos",
    "safe_ratio_pct=$([string]::Format($culture,'{0:F12}', $safeRatioPct))",
    "delivery_rate_pct=$([string]::Format($culture,'{0:F6}', $deliveryRatePct))",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "best_safe_c1_mag_q15=$bestSafeC1MagQ15",
    "best_safe_c3_mag_q15=$bestSafeC3MagQ15",
    "best_safe_c1_mag_real=$([string]::Format($culture,'{0:F12}', $bestSafeC1MagReal))",
    "best_safe_c3_mag_real=$([string]::Format($culture,'{0:F12}', $bestSafeC3MagReal))",
    "best_safe_margin_lsb=$bestSafeMarginLsb",
    "max_safe_abs_c1_mag_q15=$maxSafeAbsC1MagQ15",
    "max_safe_abs_c3_mag_q15=$maxSafeAbsC3MagQ15",
    "max_safe_abs_c1_mag_real=$([string]::Format($culture,'{0:F12}', $maxSafeAbsC1MagReal))",
    "max_safe_abs_c3_mag_real=$([string]::Format($culture,'{0:F12}', $maxSafeAbsC3MagReal))",
    "first_unsafe_c1_mag_q15=$firstUnsafeC1MagQ15",
    "first_unsafe_c3_mag_q15=$firstUnsafeC3MagQ15",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format($culture,'{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$rows = Import-Csv -LiteralPath $csvPath
$gridX0 = 100
$gridY0 = 690
$cell = 14
$gridSize = [int][Math]::Sqrt($totalCombos)
if (($gridSize * $gridSize) -ne $totalCombos) {
    throw "A malha TMQ012 nao e quadrada: total_combos=$totalCombos"
}
$safeColor = "#0f766e"
$unsafeColor = "#c2410c"
$neutralColor = "#ede0cf"

$svgLines = New-Object System.Collections.Generic.List[string]
$svgLines.Add("<svg xmlns='http://www.w3.org/2000/svg' width='1420' height='860' viewBox='0 0 1420 860'>")
$svgLines.Add("<rect width='100%' height='100%' fill='#f6efe3'/>")
$svgLines.Add("<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ012 - Observed Safe Region for Complex Coefficients and Complex Input</text>")
$svgLines.Add("<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Magnitude map validated over coefficient phase sweeps and polar complex input sweeps across multiple radii and angles</text>")
$svgLines.Add("<rect x='50' y='100' width='620' height='240' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<rect x='700' y='100' width='670' height='240' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<text x='80' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Observed Safe Region Summary</text>")
$svgLines.Add("<text x='80' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>PASS Flag: $passFlag</text>")
$svgLines.Add("<text x='80' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Safe Combos: $safeCombos / $totalCombos ($([string]::Format($culture,'{0:F3}', $safeRatioPct))%)</text>")
$svgLines.Add("<text x='80' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max Safe |c1| at c3=0: $maxSafeAbsC1MagQ15 ($([string]::Format($culture,'{0:F6}', $maxSafeAbsC1MagReal)))</text>")
$svgLines.Add("<text x='80' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max Safe |c3| at c1=0: $maxSafeAbsC3MagQ15 ($([string]::Format($culture,'{0:F6}', $maxSafeAbsC3MagReal)))</text>")
$svgLines.Add("<text x='730' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Sweep Coverage</text>")
$svgLines.Add("<text x='730' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Best Safe |c1|, |c3|: $bestSafeC1MagQ15, $bestSafeC3MagQ15</text>")
$svgLines.Add("<text x='730' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Best Safe Real: $([string]::Format($culture,'{0:F6}', $bestSafeC1MagReal)), $([string]::Format($culture,'{0:F6}', $bestSafeC3MagReal))</text>")
$svgLines.Add("<text x='730' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Coeff Phase Pairs Tested: $testedCoeffPhasePairs</text>")
$svgLines.Add("<text x='730' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Input Vectors Tested: $testedInputVectors</text>")
$svgLines.Add("<rect x='50' y='380' width='1320' height='430' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<text x='80' y='420' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Observed Complex Coefficient Magnitude Safety Map</text>")
$svgLines.Add("<text x='80' y='445' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Green cells remained saturation-free for every tested coefficient phase pair and every tested input vector on the polar stimulus grid, including radius zero.</text>")

for ($i = 0; $i -lt $rows.Count; $i++) {
    $row = $rows[$i]
    $col = [int]($i % $gridSize)
    $gridRow = [int][math]::Floor($i / $gridSize)
    $x = $gridX0 + ($col * $cell)
    $y = $gridY0 - (($gridRow + 1) * $cell)
    $fill = if ([int]$row.safe_flag -eq 1) { $safeColor } else { $unsafeColor }
    $svgLines.Add("<rect x='$x' y='$y' width='$cell' height='$cell' fill='$fill' stroke='$neutralColor' stroke-width='0.35'/>")
}

$gridPixels = $gridSize * $cell
$gridTopY = $gridY0 - $gridPixels
$gridRightX = $gridX0 + $gridPixels
$svgLines.Add("<rect x='$gridX0' y='$gridTopY' width='$gridPixels' height='$gridPixels' fill='none' stroke='#5d4e41' stroke-width='1.4'/>")
$svgLines.Add("<line x1='$gridX0' y1='$gridY0' x2='$gridRightX' y2='$gridY0' stroke='#5d4e41' stroke-width='1.4'/>")
$svgLines.Add("<line x1='$gridX0' y1='$gridY0' x2='$gridX0' y2='$gridTopY' stroke='#5d4e41' stroke-width='1.4'/>")

$xMid = $gridX0 + [int]($gridPixels / 2)
$yMid = $gridY0 - [int]($gridPixels / 2)
$svgLines.Add("<text x='$xMid' y='790' font-size='16' text-anchor='middle' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>|coef1| [Q1.15]</text>")
$svgLines.Add("<text x='38' y='$yMid' font-size='16' text-anchor='middle' transform='rotate(-90 38 $yMid)' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>|coef3| [Q1.15]</text>")
$svgLines.Add("<text x='100' y='740' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>0</text>")
$xAxisMaxLabelX = $gridRightX - 48
$yAxisTopLabelY = $gridTopY + 8
$svgLines.Add("<text x='$xAxisMaxLabelX' y='740' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>+32767</text>")
$svgLines.Add("<text x='60' y='$yAxisTopLabelY' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>+32767</text>")
$svgLines.Add("<text x='60' y='694' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>0</text>")

$bestCol = [int][Math]::Round($bestSafeC1MagQ15 / 4096.0)
if ($bestCol -ge $gridSize) { $bestCol = $gridSize - 1 }
$bestRow = [int][Math]::Round($bestSafeC3MagQ15 / 4096.0)
if ($bestRow -ge $gridSize) { $bestRow = $gridSize - 1 }
$bestX = $gridX0 + ($bestCol * $cell)
$bestY = $gridY0 - (($bestRow + 1) * $cell)
$svgLines.Add("<rect x='$bestX' y='$bestY' width='$cell' height='$cell' fill='none' stroke='#111827' stroke-width='2.0'/>")
$svgLines.Add("<text x='900' y='500' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#111827'>Outlined cell: largest safe magnitude pair by simple |c1|+|c3| score</text>")
$svgLines.Add("<rect x='900' y='535' width='22' height='22' fill='$safeColor'/>")
$svgLines.Add("<text x='934' y='551' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Safe region</text>")
$svgLines.Add("<rect x='900' y='575' width='22' height='22' fill='$unsafeColor'/>")
$svgLines.Add("<text x='934' y='591' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Saturating region</text>")
$svgLines.Add("<text x='900' y='635' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Latency: $measuredLatency / $expectedLatency cycles</text>")
$svgLines.Add("<text x='900' y='665' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Delivery Rate: $([string]::Format($culture,'{0:F6}', $deliveryRatePct))%</text>")
$svgLines.Add("<text x='900' y='695' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s</text>")
$svgLines.Add("</svg>")

Set-Content -LiteralPath $svgPath -Value ($svgLines -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ012 - Observed Safe Region for Complex Coefficients and Complex Input",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ012_ComplexCoefficientSensitivity",
    "- Objective: Determine an observed safe complex coefficient magnitude region that avoids output saturation under a geometric sweep of coefficient phases and complex input polar coordinates.",
    "- Method: For each magnitude pair (|c1|, |c3|), the test sweeps 8 phases for c1, 8 phases for c3, 17 input radii including zero, and 16 input phases.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity.v",
    "",
    "## Observed Safe Region Result",
    "",
    "- PASS Flag: $passFlag",
    "- Safe Combos: $safeCombos / $totalCombos ($([string]::Format($culture,'{0:F6}', $safeRatioPct)) %)",
    "- Unsafe Combos: $unsafeCombos",
    "- Samples Per Magnitude Pair: $samplesPerCombo",
    "- Coefficient Phase Pairs Tested: $testedCoeffPhasePairs",
    "- Input Vectors Tested: $testedInputVectors",
    "- Max Safe |c1| at c3=0: $maxSafeAbsC1MagQ15 ($([string]::Format($culture,'{0:F12}', $maxSafeAbsC1MagReal)))",
    "- Max Safe |c3| at c1=0: $maxSafeAbsC3MagQ15 ($([string]::Format($culture,'{0:F12}', $maxSafeAbsC3MagReal)))",
    "- Best Safe Magnitude Pair [Q1.15]: |c1|=$bestSafeC1MagQ15, |c3|=$bestSafeC3MagQ15",
    "- Best Safe Magnitude Pair [real]: |c1|=$([string]::Format($culture,'{0:F12}', $bestSafeC1MagReal)), |c3|=$([string]::Format($culture,'{0:F12}', $bestSafeC3MagReal))",
    "- Best Safe Margin: $bestSafeMarginLsb LSB",
    "",
    "## Execution Summary",
    "",
    "- Delivery Rate: $([string]::Format($culture,'{0:F6}', $deliveryRatePct)) %",
    "- Expected Latency: $expectedLatency cycles",
    "- Measured Latency: $measuredLatency cycles",
    "- Simulation Time: $([string]::Format($culture,'{0:F0}', $simTimeNs)) ns",
    "- Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s",
    "",
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq012_complex_coefficient_sensitivity_summary.txt",
    "- Coefficient Map CSV: tb_v3_2/tmq012_complex_coefficient_sensitivity_map.csv",
    "- Stats TXT: tb_v3_2/results/TMQ012/tmq012_complex_coefficient_sensitivity_stats.txt",
    "- Safe Region SVG: tb_v3_2/results/TMQ012/tmq012_complex_safe_region.svg",
    "- Final Report: tb_v3_2/results/TMQ012/TMQ012_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ012/TMQ012_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8
