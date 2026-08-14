$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ010"
$summaryPath = Join-Path $tbDir "tmq010_repeatability_summary.txt"
$statsPath = Join-Path $reportDir "tmq010_repeatability_stats.txt"
$reportPath = Join-Path $reportDir "TMQ010_final_report.md"
$svgPath = Join-Path $reportDir "tmq010_repeatability_dashboard.svg"
$transcriptPath = Join-Path $reportDir "TMQ010_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq010_repeatability.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source
$culture = [System.Globalization.CultureInfo]::InvariantCulture

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
$assaySamples = [int]$summary["assay_samples"]
$numRuns = [int]$summary["num_runs"]
$numSamples = [int]$summary["num_samples"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$mismatchCount = [int]$summary["mismatch_count"]
$mismatchReCount = [int]$summary["mismatch_re_count"]
$mismatchImCount = [int]$summary["mismatch_im_count"]
$repeatabilityPct = [double]$summary["repeatability_pct"]
$firstMismatchRun = [int]$summary["first_mismatch_run"]
$firstMismatchSample = [int]$summary["first_mismatch_sample"]
$overflowTotal = [int]$summary["overflow_total"]
$saturatedOutputCount = [int]$summary["saturated_output_count"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$xzErrors = [int]$summary["xz_errors"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ010_RepeatabilityCharacterization",
    "assay_samples=$assaySamples",
    "num_runs=$numRuns",
    "num_samples=$numSamples",
    "delivery_rate_pct=$([string]::Format($culture,'{0:F6}', $deliveryRatePct))",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "mismatch_count=$mismatchCount",
    "mismatch_re_count=$mismatchReCount",
    "mismatch_im_count=$mismatchImCount",
    "repeatability_pct=$([string]::Format($culture,'{0:F12}', $repeatabilityPct))",
    "first_mismatch_run=$firstMismatchRun",
    "first_mismatch_sample=$firstMismatchSample",
    "overflow_total=$overflowTotal",
    "saturated_output_count=$saturatedOutputCount",
    "overflow_rate_pct=$([string]::Format($culture,'{0:F6}', $overflowRatePct))",
    "xz_errors=$xzErrors",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format($culture,'{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$mismatchScale = 150.0
$comparedSamples = $numSamples - $assaySamples
$matchSamples = $comparedSamples - $mismatchCount
$matchBar = if ($comparedSamples -gt 0) { [int]([Math]::Round(($matchSamples * $mismatchScale) / $comparedSamples)) } else { 0 }
$mismatchBar = if ($comparedSamples -gt 0) { [int]([Math]::Round(($mismatchCount * $mismatchScale) / $comparedSamples)) } else { 0 }
$mismatchBar = if ($mismatchCount -eq 0 -and $comparedSamples -gt 0) { 2 } else { $mismatchBar }
$matchBarY = 650 - $matchBar
$mismatchBarY = 650 - $mismatchBar

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='1380' height='780' viewBox='0 0 1380 780'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ010 - Repeatability Under Saturation and Stress</text>",
    "<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>1000 deterministic runs of 1024 complex samples with forced saturation and bitwise comparison</text>",
    "<rect x='50' y='100' width='590' height='280' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<rect x='670' y='100' width='660' height='280' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<text x='80' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Repeatability Metrics</text>",
    "<text x='80' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>PASS Flag: $passFlag</text>",
    "<text x='80' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Assay Samples: $assaySamples</text>",
    "<text x='80' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Runs: $numRuns</text>",
    "<text x='80' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Repeatability: $([string]::Format($culture,'{0:F12}', $repeatabilityPct)) %</text>",
    "<text x='80' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Bitwise Mismatches: $mismatchCount</text>",
    "<text x='700' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Execution and Robustness</text>",
    "<text x='700' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Compared Samples: $comparedSamples</text>",
    "<text x='700' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Latency: $measuredLatency / $expectedLatency cycles</text>",
    "<text x='700' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Overflow Events: $overflowTotal</text>",
    "<text x='700' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>X/Z Errors: $xzErrors</text>",
    "<text x='700' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s</text>",
    "<text x='700' y='355' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Saturated Outputs: $saturatedOutputCount</text>",
    "<rect x='50' y='395' width='1280' height='305' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<text x='80' y='440' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Bitwise Comparison Summary</text>",
    "<line x1='100' y1='650' x2='1240' y2='650' stroke='#5d4e41' stroke-width='1.5'/>",
    "<rect x='230' y='$matchBarY' width='180' height='$matchBar' fill='#0f766e' opacity='0.88'/>",
    "<rect x='560' y='$mismatchBarY' width='180' height='$mismatchBar' fill='#c2410c' opacity='0.85'/>",
    "<text x='245' y='680' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Matching Samples</text>",
    "<text x='575' y='680' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Mismatch Samples</text>",
    "<text x='910' y='520' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Match Count: $matchSamples</text>",
    "<text x='910' y='555' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Mismatch Count: $mismatchCount</text>",
    "<text x='910' y='590' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Mismatch RE/IM: $mismatchReCount / $mismatchImCount</text>",
    "</svg>"
) -join "`r`n"

Set-Content -LiteralPath $svgPath -Value $svg -Encoding UTF8

$report = @(
    "# TMQ010 - Repeatability Under Saturation and Stress",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ010_RepeatabilityCharacterization",
    "- Objective: Repeat the same deterministic saturated assay 1000 times with 1024 samples per run and compare every output sample bit by bit against the first run.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization.v",
    "",
    "## Repeatability Result",
    "",
    "- PASS Flag: $passFlag",
    "- Assay Samples: $assaySamples",
    "- Runs: $numRuns",
    "- Saturated Outputs: $saturatedOutputCount",
    "- Compared Samples: $comparedSamples",
    "- Bitwise Mismatches: $mismatchCount",
    "- Repeatability: $([string]::Format($culture,'{0:F12}', $repeatabilityPct)) %",
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
    "- Simulation Summary: tb_v3_2/tmq010_repeatability_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ010/tmq010_repeatability_stats.txt",
    "- Repeatability SVG: tb_v3_2/results/TMQ010/tmq010_repeatability_dashboard.svg",
    "- Final Report: tb_v3_2/results/TMQ010/TMQ010_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ010/TMQ010_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ010 - Repeatability Under Saturation and Stress"
Write-Host "======================================================================"
Write-Host "Summary TXT        : $summaryPath"
Write-Host "Stats TXT          : $statsPath"
Write-Host "Repeatability SVG  : $svgPath"
Write-Host "Final Report       : $reportPath"
Write-Host "Transcript         : $transcriptPath"
Write-Host "PASS Flag          : $passFlag"
Write-Host "Repeatability [%]  : $([string]::Format($culture,'{0:F12}', $repeatabilityPct))"
Write-Host "Assay Samples / Runs: $assaySamples / $numRuns"
Write-Host "Saturated Outputs  : $saturatedOutputCount"
Write-Host "Bitwise Mismatches : $mismatchCount"
