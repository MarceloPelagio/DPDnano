$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ007"
$summaryPath = Join-Path $tbDir "tmq007_stability_summary.txt"
$statsPath = Join-Path $reportDir "tmq007_stability_stats.txt"
$reportPath = Join-Path $reportDir "TMQ007_final_report.md"
$svgPath = Join-Path $reportDir "tmq007_stability_dashboard.svg"
$transcriptPath = Join-Path $reportDir "TMQ007_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq007_stability.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source
$culture = [System.Globalization.CultureInfo]::InvariantCulture

function SvgFmt([double]$value, [string]$format) {
    return [string]::Format($culture, "{0:$format}", $value)
}

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

$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$overflowTotal = [int]$summary["overflow_total"]
$xzErrors = [int]$summary["xz_errors"]
$logicalNaNErrors = [int]$summary["logical_nan_errors"]
$glitchErrors = [int]$summary["glitch_errors"]
$stallErrors = [int]$summary["stall_errors"]
$oscillationFlags = [int]$summary["oscillation_flags"]
$maxSameOutputRun = [int]$summary["max_same_output_run"]
$passFlag = [int]$summary["pass_flag"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ007_StabilityTest",
    "delivery_rate_pct=$(SvgFmt $deliveryRatePct 'F6')",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "overflow_total=$overflowTotal",
    "overflow_rate_pct=$(SvgFmt $overflowRatePct 'F6')",
    "xz_errors=$xzErrors",
    "logical_nan_errors=$logicalNaNErrors",
    "glitch_errors=$glitchErrors",
    "stall_errors=$stallErrors",
    "oscillation_flags=$oscillationFlags",
    "max_same_output_run=$maxSameOutputRun",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$(SvgFmt $simTimeNs 'F0')",
    "wall_clock_seconds=$(SvgFmt $simWallClock.TotalSeconds 'F3')",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='1280' height='720' viewBox='0 0 1280 720'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ007 - Stability Test</text>",
    "<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>100000 random complex samples with stability and robustness checks</text>",
    "<rect x='60' y='110' width='1160' height='470' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<text x='110' y='170' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>PASS Flag</text>",
    "<text x='320' y='170' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$passFlag</text>",
    "<text x='110' y='230' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Expected Latency</text>",
    "<text x='320' y='230' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$expectedLatency</text>",
    "<text x='110' y='270' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Measured Latency</text>",
    "<text x='320' y='270' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$measuredLatency</text>",
    "<text x='110' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Overflow Events</text>",
    "<text x='320' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$overflowTotal</text>",
    "<text x='110' y='370' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>X/Z Errors</text>",
    "<text x='320' y='370' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$xzErrors</text>",
    "<text x='110' y='410' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Logical NaN Errors</text>",
    "<text x='320' y='410' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$logicalNaNErrors</text>",
    "<text x='110' y='450' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Glitch Errors</text>",
    "<text x='320' y='450' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$glitchErrors</text>",
    "<text x='110' y='490' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Stall Errors</text>",
    "<text x='320' y='490' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$stallErrors</text>",
    "<text x='110' y='530' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Oscillation Flags</text>",
    "<text x='320' y='530' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$oscillationFlags</text>",
    "<text x='700' y='230' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Delivery Rate [%]</text>",
    "<text x='970' y='230' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $deliveryRatePct 'F6')</text>",
    "<text x='700' y='270' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Overflow Rate [%]</text>",
    "<text x='970' y='270' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $overflowRatePct 'F6')</text>",
    "<text x='700' y='310' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Max Same Output Run</text>",
    "<text x='970' y='310' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$maxSameOutputRun</text>",
    "<text x='700' y='350' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Simulation Cycles</text>",
    "<text x='970' y='350' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$simCycles</text>",
    "<text x='700' y='390' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Simulation Time [ns]</text>",
    "<text x='970' y='390' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $simTimeNs 'F0')</text>",
    "<text x='700' y='430' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Wall Clock [s]</text>",
    "<text x='970' y='430' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $simWallClock.TotalSeconds 'F3')</text>",
    "<text x='60' y='640' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Target result: PASS with 0 critical errors. Current PASS flag: $passFlag</text>",
    "</svg>"
) -join "`r`n"

Set-Content -LiteralPath $svgPath -Value $svg -Encoding UTF8

$report = @(
    "# TMQ007 - Stability Test",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ007_StabilityTest",
    "- Objective: Stress the frozen RTL with 100000 random complex samples and detect overflow, stalls, oscillations, X/Z, logical NaN conditions and glitches.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ007_StabilityTest.v",
    "",
    "## Stability Result",
    "",
    "- PASS Flag: $passFlag",
    "- Overflow Events: $overflowTotal",
    "- X/Z Errors: $xzErrors",
    "- Logical NaN Errors: $logicalNaNErrors",
    "- Glitch Errors: $glitchErrors",
    "- Stall Errors: $stallErrors",
    "- Oscillation Flags: $oscillationFlags",
    "",
    "## Execution Summary",
    "",
    "- Delivery Rate: $(SvgFmt $deliveryRatePct 'F6') %",
    "- Expected Latency: $expectedLatency cycles",
    "- Measured Latency: $measuredLatency cycles",
    "- Overflow Rate: $(SvgFmt $overflowRatePct 'F6') %",
    "- Max Same Output Run: $maxSameOutputRun",
    "- Simulation Time: $(SvgFmt $simTimeNs 'F0') ns",
    "- Wall Clock: $(SvgFmt $simWallClock.TotalSeconds 'F3') s",
    "",
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq007_stability_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ007/tmq007_stability_stats.txt",
    "- Stability SVG: tb_v3_2/results/TMQ007/tmq007_stability_dashboard.svg",
    "- Final Report: tb_v3_2/results/TMQ007/TMQ007_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ007/TMQ007_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ007 - Stability Test"
Write-Host "======================================================================"
Write-Host "Summary TXT   : $summaryPath"
Write-Host "Stats TXT     : $statsPath"
Write-Host "Stability SVG : $svgPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "Errors        : X/Z=$xzErrors  NaN=$logicalNaNErrors  Glitch=$glitchErrors  Stall=$stallErrors  Osc=$oscillationFlags"
