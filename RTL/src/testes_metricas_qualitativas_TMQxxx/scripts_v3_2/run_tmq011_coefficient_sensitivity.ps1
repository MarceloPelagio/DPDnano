$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ011"
$summaryPath = Join-Path $tbDir "tmq011_coefficient_sensitivity_summary.txt"
$csvPath = Join-Path $tbDir "tmq011_coefficient_sensitivity_map.csv"
$statsPath = Join-Path $reportDir "tmq011_coefficient_sensitivity_stats.txt"
$reportPath = Join-Path $reportDir "TMQ011_final_report.md"
$svgPath = Join-Path $reportDir "tmq011_safe_region.svg"
$transcriptPath = Join-Path $reportDir "TMQ011_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq011_coefficient_sensitivity.do"
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
$safeCombos = [int]$summary["safe_combos"]
$unsafeCombos = [int]$summary["unsafe_combos"]
$safeRatioPct = [double]$summary["safe_ratio_pct"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$bestSafeC1Q15 = [int]$summary["best_safe_c1_q15"]
$bestSafeC3Q15 = [int]$summary["best_safe_c3_q15"]
$bestSafeC1Real = [double]$summary["best_safe_c1_real"]
$bestSafeC3Real = [double]$summary["best_safe_c3_real"]
$bestSafeMarginLsb = [int]$summary["best_safe_margin_lsb"]
$maxSafeAbsC1Q15 = [int]$summary["max_safe_abs_c1_q15"]
$maxSafeAbsC3Q15 = [int]$summary["max_safe_abs_c3_q15"]
$maxSafeAbsC1Real = [double]$summary["max_safe_abs_c1_real"]
$maxSafeAbsC3Real = [double]$summary["max_safe_abs_c3_real"]
$firstUnsafeC1Q15 = [int]$summary["first_unsafe_c1_q15"]
$firstUnsafeC3Q15 = [int]$summary["first_unsafe_c3_q15"]
$firstUnsafeSeen = [int]$summary["first_unsafe_seen"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ011_CoefficientSensitivity",
    "total_combos=$totalCombos",
    "safe_combos=$safeCombos",
    "unsafe_combos=$unsafeCombos",
    "safe_ratio_pct=$([string]::Format($culture,'{0:F12}', $safeRatioPct))",
    "delivery_rate_pct=$([string]::Format($culture,'{0:F6}', $deliveryRatePct))",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "best_safe_c1_q15=$bestSafeC1Q15",
    "best_safe_c3_q15=$bestSafeC3Q15",
    "best_safe_c1_real=$([string]::Format($culture,'{0:F12}', $bestSafeC1Real))",
    "best_safe_c3_real=$([string]::Format($culture,'{0:F12}', $bestSafeC3Real))",
    "best_safe_margin_lsb=$bestSafeMarginLsb",
    "max_safe_abs_c1_q15=$maxSafeAbsC1Q15",
    "max_safe_abs_c3_q15=$maxSafeAbsC3Q15",
    "max_safe_abs_c1_real=$([string]::Format($culture,'{0:F12}', $maxSafeAbsC1Real))",
    "max_safe_abs_c3_real=$([string]::Format($culture,'{0:F12}', $maxSafeAbsC3Real))",
    "first_unsafe_c1_q15=$firstUnsafeC1Q15",
    "first_unsafe_c3_q15=$firstUnsafeC3Q15",
    "first_unsafe_seen=$firstUnsafeSeen",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format($culture,'{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$rows = Import-Csv -LiteralPath $csvPath
$gridX0 = 100
$gridY0 = 690
$cell = 12
$gridSize = 65
$safeColor = "#0f766e"
$unsafeColor = "#c2410c"
$neutralColor = "#ede0cf"

$svgLines = New-Object System.Collections.Generic.List[string]
$svgLines.Add("<svg xmlns='http://www.w3.org/2000/svg' width='1420' height='860' viewBox='0 0 1420 860'>")
$svgLines.Add("<rect width='100%' height='100%' fill='#f6efe3'/>")
$svgLines.Add("<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ011 - Safe Coefficient Region Without Saturation</text>")
$svgLines.Add("<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Real-valued coefficient sweep on c1 and c3 with full signed Q1.15 real input sweep from -32768 to +32767</text>")
$svgLines.Add("<rect x='50' y='100' width='620' height='240' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<rect x='700' y='100' width='670' height='240' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<text x='80' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Safe Region Summary</text>")
$svgLines.Add("<text x='80' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>PASS Flag: $passFlag</text>")
$svgLines.Add("<text x='80' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Safe Combos: $safeCombos / $totalCombos ($([string]::Format($culture,'{0:F3}', $safeRatioPct))%)</text>")
$svgLines.Add("<text x='80' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max Safe |c1| at c3=0: $maxSafeAbsC1Q15 ($([string]::Format($culture,'{0:F6}', $maxSafeAbsC1Real)))</text>")
$svgLines.Add("<text x='80' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max Safe |c3| at c1=0: $maxSafeAbsC3Q15 ($([string]::Format($culture,'{0:F6}', $maxSafeAbsC3Real)))</text>")
$svgLines.Add("<text x='730' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Reference Combos</text>")
$svgLines.Add("<text x='730' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Best Safe Combo: c1=$bestSafeC1Q15, c3=$bestSafeC3Q15</text>")
$svgLines.Add("<text x='730' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Best Safe Real: c1=$([string]::Format($culture,'{0:F6}', $bestSafeC1Real)), c3=$([string]::Format($culture,'{0:F6}', $bestSafeC3Real))</text>")
$svgLines.Add("<text x='730' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Best Safe Margin: $bestSafeMarginLsb LSB</text>")
$svgLines.Add("<text x='730' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>First Unsafe Combo: c1=$firstUnsafeC1Q15, c3=$firstUnsafeC3Q15</text>")
$svgLines.Add("<rect x='50' y='380' width='1320' height='430' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svgLines.Add("<text x='80' y='420' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Coefficient Safety Map</text>")
$svgLines.Add("<text x='80' y='445' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Green cells are coefficient pairs with zero output saturation over the full signed input sweep. Red cells saturate at least once.</text>")

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
$svgLines.Add("<text x='$xMid' y='790' font-size='16' text-anchor='middle' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>coef1_re [Q1.15]</text>")
$svgLines.Add("<text x='38' y='$yMid' font-size='16' text-anchor='middle' transform='rotate(-90 38 $yMid)' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>coef3_re [Q1.15]</text>")

$svgLines.Add("<text x='100' y='740' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>-32768</text>")
$xAxisMaxLabelX = $gridRightX - 40
$yAxisTopLabelY = $gridTopY + 8
$svgLines.Add("<text x='$xAxisMaxLabelX' y='740' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>+32767</text>")
$svgLines.Add("<text x='52' y='$yAxisTopLabelY' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>+32767</text>")
$svgLines.Add("<text x='52' y='694' font-size='12' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>-32768</text>")

$bestCol = [int][math]::Round(($bestSafeC1Q15 + 32768) / 1024.0)
if ($bestSafeC1Q15 -eq 32767) { $bestCol = 64 }
$bestRow = [int][math]::Round(($bestSafeC3Q15 + 32768) / 1024.0)
if ($bestSafeC3Q15 -eq 32767) { $bestRow = 64 }
$bestX = $gridX0 + ($bestCol * $cell)
$bestY = $gridY0 - (($bestRow + 1) * $cell)
$svgLines.Add("<rect x='$bestX' y='$bestY' width='$cell' height='$cell' fill='none' stroke='#111827' stroke-width='2.0'/>")
$svgLines.Add("<text x='980' y='470' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#111827'>Outlined cell: best safe coefficient pair</text>")
$svgLines.Add("<rect x='980' y='505' width='22' height='22' fill='$safeColor'/>")
$svgLines.Add("<text x='1014' y='521' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Safe region</text>")
$svgLines.Add("<rect x='980' y='545' width='22' height='22' fill='$unsafeColor'/>")
$svgLines.Add("<text x='1014' y='561' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Saturating region</text>")
$svgLines.Add("<text x='980' y='610' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Latency: $measuredLatency / $expectedLatency cycles</text>")
$svgLines.Add("<text x='980' y='640' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Delivery Rate: $([string]::Format($culture,'{0:F6}', $deliveryRatePct))%</text>")
$svgLines.Add("<text x='980' y='670' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s</text>")
$svgLines.Add("</svg>")

Set-Content -LiteralPath $svgPath -Value ($svgLines -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ011 - Safe Coefficient Region Without Saturation",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ011_CoefficientSensitivity",
    "- Objective: Determine the real-valued coefficient region on c1 and c3 that avoids output saturation for a full signed Q1.15 input sweep from -32768 to +32767.",
    "- Assumption: coef1_im = 0, coef3_im = 0 and din_im = 0, isolating the canonical real cubic law y = c1*x + c3*x^3.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ011_CoefficientSensitivity.v",
    "",
    "## Safe Region Result",
    "",
    "- PASS Flag: $passFlag",
    "- Safe Combos: $safeCombos / $totalCombos ($([string]::Format($culture,'{0:F6}', $safeRatioPct)) %)",
    "- Unsafe Combos: $unsafeCombos",
    "- Max Safe |c1| at c3=0: $maxSafeAbsC1Q15 ($([string]::Format($culture,'{0:F12}', $maxSafeAbsC1Real)))",
    "- Max Safe |c3| at c1=0: $maxSafeAbsC3Q15 ($([string]::Format($culture,'{0:F12}', $maxSafeAbsC3Real)))",
    "- Best Safe Combo [Q1.15]: c1=$bestSafeC1Q15, c3=$bestSafeC3Q15",
    "- Best Safe Combo [real]: c1=$([string]::Format($culture,'{0:F12}', $bestSafeC1Real)), c3=$([string]::Format($culture,'{0:F12}', $bestSafeC3Real))",
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
    "- Simulation Summary: tb_v3_2/tmq011_coefficient_sensitivity_summary.txt",
    "- Coefficient Map CSV: tb_v3_2/tmq011_coefficient_sensitivity_map.csv",
    "- Stats TXT: tb_v3_2/results/TMQ011/tmq011_coefficient_sensitivity_stats.txt",
    "- Safe Region SVG: tb_v3_2/results/TMQ011/tmq011_safe_region.svg",
    "- Final Report: tb_v3_2/results/TMQ011/TMQ011_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ011/TMQ011_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ011 - Safe Coefficient Region Without Saturation"
Write-Host "======================================================================"
Write-Host "Summary TXT      : $summaryPath"
Write-Host "Coefficient CSV  : $csvPath"
Write-Host "Stats TXT        : $statsPath"
Write-Host "Safe Region SVG  : $svgPath"
Write-Host "Final Report     : $reportPath"
Write-Host "Transcript       : $transcriptPath"
Write-Host "PASS Flag        : $passFlag"
Write-Host "Safe Combos      : $safeCombos / $totalCombos"
Write-Host "Max Safe |c1|    : $maxSafeAbsC1Q15 ($([string]::Format($culture,'{0:F6}', $maxSafeAbsC1Real)))"
Write-Host "Max Safe |c3|    : $maxSafeAbsC3Q15 ($([string]::Format($culture,'{0:F6}', $maxSafeAbsC3Real)))"
