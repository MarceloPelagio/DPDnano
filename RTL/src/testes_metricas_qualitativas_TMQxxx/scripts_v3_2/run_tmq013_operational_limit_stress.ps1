$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ013"
$summaryPath = Join-Path $tbDir "tmq013_operational_limit_stress_summary.txt"
$csvPath = Join-Path $tbDir "tmq013_operational_limit_stress_samples.csv"
$statsPath = Join-Path $reportDir "tmq013_operational_limit_stress_stats.txt"
$reportPath = Join-Path $reportDir "TMQ013_final_report.md"
$svgPath = Join-Path $reportDir "tmq013_operational_limit_dashboard.svg"
$transcriptPath = Join-Path $reportDir "TMQ013_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq013_operational_limit_stress.do"
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
    throw "CSV da simulacao nao foi gerado: $csvPath"
}

$summary = @{}
foreach ($line in Get-Content -LiteralPath $summaryPath) {
    if ($line -match "^\s*([^=]+)=(.*)$") {
        $summary[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$passFlag = [int]$summary["pass_flag"]
$numLevels = [int]$summary["num_levels"]
$samplesPerLevel = [int]$summary["samples_per_level"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$overflowTotal = [int]$summary["overflow_total"]
$saturatedOutputCount = [int]$summary["saturated_output_count"]
$safeOutputCount = [int]$summary["safe_output_count"]
$safeRatioPct = [double]$summary["safe_ratio_pct"]
$saturationRatioPct = [double]$summary["saturation_ratio_pct"]
$persistentRatioPct = [double]$summary["persistent_ratio_pct"]
$firstSaturationSeen = [int]$summary["first_saturation_seen"]
$firstSaturationLevel = [int]$summary["first_saturation_level"]
$firstSaturationSample = [int]$summary["first_saturation_sample"]
$firstSaturationAmplitudeReal = [double]$summary["first_saturation_amplitude_real"]
$firstPersistentSeen = [int]$summary["first_persistent_seen"]
$firstPersistentLevel = [int]$summary["first_persistent_level"]
$firstPersistentSample = [int]$summary["first_persistent_sample"]
$maxPersistentRunLen = [int]$summary["max_persistent_run_len"]
$longestSafeRunBeforeSat = [int]$summary["longest_safe_run_before_sat"]
$worstSafeLevel = [int]$summary["worst_safe_level"]
$worstSafeAmpQ15 = [int]$summary["worst_safe_amp_q15"]
$worstSafeAmplitudeReal = [double]$summary["worst_safe_amplitude_real"]
$worstSafeMarginLsb = [int]$summary["worst_safe_margin_lsb"]
$xzErrors = [int]$summary["xz_errors"]
$stressScore = [double]$summary["stress_score"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ013_OperationalLimitStressTest",
    "num_levels=$numLevels",
    "samples_per_level=$samplesPerLevel",
    "delivery_rate_pct=$([string]::Format($culture,'{0:F6}', $deliveryRatePct))",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "overflow_total=$overflowTotal",
    "saturated_output_count=$saturatedOutputCount",
    "safe_output_count=$safeOutputCount",
    "safe_ratio_pct=$([string]::Format($culture,'{0:F12}', $safeRatioPct))",
    "saturation_ratio_pct=$([string]::Format($culture,'{0:F12}', $saturationRatioPct))",
    "persistent_ratio_pct=$([string]::Format($culture,'{0:F12}', $persistentRatioPct))",
    "first_saturation_seen=$firstSaturationSeen",
    "first_saturation_level=$firstSaturationLevel",
    "first_saturation_sample=$firstSaturationSample",
    "first_saturation_amplitude_real=$([string]::Format($culture,'{0:F12}', $firstSaturationAmplitudeReal))",
    "first_persistent_seen=$firstPersistentSeen",
    "first_persistent_level=$firstPersistentLevel",
    "first_persistent_sample=$firstPersistentSample",
    "max_persistent_run_len=$maxPersistentRunLen",
    "longest_safe_run_before_sat=$longestSafeRunBeforeSat",
    "worst_safe_level=$worstSafeLevel",
    "worst_safe_amp_q15=$worstSafeAmpQ15",
    "worst_safe_amplitude_real=$([string]::Format($culture,'{0:F12}', $worstSafeAmplitudeReal))",
    "worst_safe_margin_lsb=$worstSafeMarginLsb",
    "xz_errors=$xzErrors",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format($culture,'{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$rows = Import-Csv -LiteralPath $csvPath
$plotRows = $rows | Where-Object { $_.level_idx -match '^\d+$' }
$maxSat = ($plotRows | Measure-Object -Property saturated_outputs -Maximum).Maximum
if (-not $maxSat -or $maxSat -lt 1) { $maxSat = 1 }
$plotHeight = 260.0
$plotWidth = 900
$barGap = 4
$barWidth = [int][Math]::Floor(($plotWidth - (($plotRows.Count - 1) * $barGap)) / [double]$plotRows.Count)
if ($barWidth -lt 8) { $barWidth = 8 }
$scale = $plotHeight / [double]$maxSat
$baseX = 90
$baseY = 710
$axisEndX = 1010
$legendX = 1080

$svg = New-Object System.Collections.Generic.List[string]
$svg.Add("<svg xmlns='http://www.w3.org/2000/svg' width='1480' height='860' viewBox='0 0 1480 860'>")
$svg.Add("<rect width='100%' height='100%' fill='#f6efe3'/>")
$svg.Add("<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ013 - Operational Limit Stress Test</text>")
$svg.Add("<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Long-sequence boundary stress with near-limit coefficients, progressive amplitude escalation and persistent saturation detection</text>")
$svg.Add("<rect x='50' y='100' width='620' height='250' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svg.Add("<rect x='700' y='100' width='730' height='250' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svg.Add("<text x='80' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Boundary Reading</text>")
$svg.Add("<text x='80' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>PASS Flag: $passFlag</text>")
$svg.Add("<text x='80' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>First saturation starts at level $firstSaturationLevel</text>")
$svg.Add("<text x='80' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Persistent saturation starts at level $firstPersistentLevel</text>")
$svg.Add("<text x='80' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Last safe operating level: $worstSafeLevel</text>")
$svg.Add("<text x='80' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Last safe amplitude [real]: $([string]::Format($culture,'{0:F6}', $worstSafeAmplitudeReal))</text>")
$svg.Add("<text x='730' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Execution and Persistence</text>")
$svg.Add("<text x='730' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Safe outputs: $safeOutputCount ($([string]::Format($culture,'{0:F3}', $safeRatioPct)) %)</text>")
$svg.Add("<text x='730' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Saturated outputs: $saturatedOutputCount ($([string]::Format($culture,'{0:F3}', $saturationRatioPct)) %)</text>")
$svg.Add("<text x='730' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Longest persistent saturation run: $maxPersistentRunLen</text>")
$svg.Add("<text x='730' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Latency: $measuredLatency / $expectedLatency cycles | X/Z: $xzErrors</text>")
$svg.Add("<text x='730' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s</text>")
$svg.Add("<rect x='50' y='390' width='1380' height='410' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>")
$svg.Add("<text x='80' y='430' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Saturation Growth by Stress Level</text>")
$svg.Add("<line x1='80' y1='$baseY' x2='$axisEndX' y2='$baseY' stroke='#5d4e41' stroke-width='1.5'/>")

for ($i = 0; $i -lt $plotRows.Count; $i++) {
    $row = $plotRows[$i]
    $sat = [int]$row.saturated_outputs
    $h = [int][Math]::Round($sat * $scale)
    $x = $baseX + ($i * ($barWidth + $barGap))
    $y = $baseY - $h
    $fill = if ($sat -gt 0) { "#c2410c" } else { "#0f766e" }
    $svg.Add("<rect x='$x' y='$y' width='$barWidth' height='$h' fill='$fill' opacity='0.85'/>")
    if (($i % 4) -eq 0) {
        $svg.Add("<text x='$x' y='735' font-size='10' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$i</text>")
    }
}

$svg.Add("<text x='$legendX' y='470' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Green: no saturation at that level</text>")
$svg.Add("<text x='$legendX' y='500' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Orange: at least one saturated output</text>")
$svg.Add("<text x='$legendX' y='530' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>First saturation amplitude [real]: $([string]::Format($culture,'{0:F6}', $firstSaturationAmplitudeReal))</text>")
$svg.Add("<text x='$legendX' y='560' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Last safe margin: $worstSafeMarginLsb LSB</text>")
$svg.Add("<text x='$legendX' y='590' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Longest safe run before saturation: $longestSafeRunBeforeSat</text>")
$svg.Add("<text x='$legendX' y='620' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Persistent ratio: $([string]::Format($culture,'{0:F6}', $persistentRatioPct)) %</text>")
$svg.Add("</svg>")

Set-Content -LiteralPath $svgPath -Value ($svg -join "`r`n") -Encoding UTF8

$report = @(
    "# TMQ013 - Operational Limit Stress Test",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ013_OperationalLimitStressTest",
    "- Objective: Stress the architecture near its operational boundary and observe the transition from safe operation to persistent saturation under long complex sequences.",
    "- Method: Progressive amplitude levels, near-limit complex coefficients and long deterministic sequences with saturation persistence tracking.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest.v",
    "",
    "## Stress Result",
    "",
    "- PASS Flag: $passFlag",
    "- Safe Outputs: $safeOutputCount ($([string]::Format($culture,'{0:F12}', $safeRatioPct)) %)",
    "- Saturated Outputs: $saturatedOutputCount ($([string]::Format($culture,'{0:F12}', $saturationRatioPct)) %)",
    "- First Saturation Level / Sample: $firstSaturationLevel / $firstSaturationSample",
    "- First Persistent Saturation Level / Sample: $firstPersistentLevel / $firstPersistentSample",
    "- First Saturation Amplitude [real]: $([string]::Format($culture,'{0:F12}', $firstSaturationAmplitudeReal))",
    "- Last Safe Level / Amplitude [real]: $worstSafeLevel / $([string]::Format($culture,'{0:F12}', $worstSafeAmplitudeReal))",
    "- Last Safe Margin: $worstSafeMarginLsb LSB",
    "- Longest Persistent Saturation Run: $maxPersistentRunLen",
    "- Longest Safe Run Before Saturation: $longestSafeRunBeforeSat",
    "",
    "## Execution Summary",
    "",
    "- Delivery Rate: $([string]::Format($culture,'{0:F6}', $deliveryRatePct)) %",
    "- Expected Latency: $expectedLatency cycles",
    "- Measured Latency: $measuredLatency cycles",
    "- Overflow Events: $overflowTotal",
    "- X/Z Errors: $xzErrors",
    "- Simulation Time: $([string]::Format($culture,'{0:F0}', $simTimeNs)) ns",
    "- Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s",
    "",
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq013_operational_limit_stress_summary.txt",
    "- Level CSV: tb_v3_2/tmq013_operational_limit_stress_samples.csv",
    "- Stats TXT: tb_v3_2/results/TMQ013/tmq013_operational_limit_stress_stats.txt",
    "- Stress SVG: tb_v3_2/results/TMQ013/tmq013_operational_limit_dashboard.svg",
    "- Final Report: tb_v3_2/results/TMQ013/TMQ013_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ013/TMQ013_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ013 - Operational Limit Stress Test"
Write-Host "======================================================================"
Write-Host "Summary TXT    : $summaryPath"
Write-Host "Level CSV      : $csvPath"
Write-Host "Stats TXT      : $statsPath"
Write-Host "Stress SVG     : $svgPath"
Write-Host "Final Report   : $reportPath"
Write-Host "Transcript     : $transcriptPath"
Write-Host "PASS Flag      : $passFlag"
Write-Host "Safe Outputs          : $safeOutputCount ($([string]::Format($culture,'{0:F3}', $safeRatioPct))%)"
Write-Host "Saturated Outputs     : $saturatedOutputCount ($([string]::Format($culture,'{0:F3}', $saturationRatioPct))%)"
Write-Host "First Saturation Level: $firstSaturationLevel"
Write-Host "First Persistent Level: $firstPersistentLevel"
Write-Host "Last Safe Level       : $worstSafeLevel"
