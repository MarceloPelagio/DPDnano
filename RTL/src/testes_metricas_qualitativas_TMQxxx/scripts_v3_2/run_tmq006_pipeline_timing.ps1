$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ006"
$summaryPath = Join-Path $tbDir "tmq006_pipeline_timing_summary.txt"
$statsPath = Join-Path $reportDir "tmq006_pipeline_timing_stats.txt"
$reportPath = Join-Path $reportDir "TMQ006_final_report.md"
$svgPath = Join-Path $reportDir "tmq006_pipeline_timing_table.svg"
$transcriptPath = Join-Path $reportDir "TMQ006_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq006_pipeline_timing.do"
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

$latencyMin = [int]$summary["latency_min"]
$latencyMax = [int]$summary["latency_max"]
$latencyAvg = [double]$summary["latency_avg"]
$inputGapMin = [int]$summary["input_gap_min"]
$inputGapMax = [int]$summary["input_gap_max"]
$inputGapAvg = [double]$summary["input_gap_avg"]
$outputGapMin = [int]$summary["output_gap_min"]
$outputGapMax = [int]$summary["output_gap_max"]
$outputGapAvg = [double]$summary["output_gap_avg"]
$throughputPerCycle = [double]$summary["throughput_vectors_per_cycle"]
$throughputPerUs = [double]$summary["throughput_vectors_per_us"]
$throughputPerSecond = [double]$summary["throughput_vectors_per_second"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$passFlag = [int]$summary["pass_flag"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ006_PipelineTimingCharacterization",
    "latency_min=$latencyMin",
    "latency_max=$latencyMax",
    "latency_avg=$(SvgFmt $latencyAvg 'F12')",
    "input_gap_min=$inputGapMin",
    "input_gap_max=$inputGapMax",
    "input_gap_avg=$(SvgFmt $inputGapAvg 'F12')",
    "output_gap_min=$outputGapMin",
    "output_gap_max=$outputGapMax",
    "output_gap_avg=$(SvgFmt $outputGapAvg 'F12')",
    "throughput_vectors_per_cycle=$(SvgFmt $throughputPerCycle 'F12')",
    "throughput_vectors_per_us=$(SvgFmt $throughputPerUs 'F12')",
    "throughput_vectors_per_second=$(SvgFmt $throughputPerSecond 'F3')",
    "delivery_rate_pct=$(SvgFmt $deliveryRatePct 'F6')",
    "overflow_rate_pct=$(SvgFmt $overflowRatePct 'F6')",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$(SvgFmt $simTimeNs 'F0')",
    "wall_clock_seconds=$(SvgFmt $simWallClock.TotalSeconds 'F3')",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='1280' height='720' viewBox='0 0 1280 720'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ006 - Pipeline Timing Characterization</text>",
    "<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Latency, valid intervals and throughput summary</text>",
    "<rect x='60' y='110' width='1160' height='420' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<text x='110' y='160' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Metric</text>",
    "<text x='520' y='160' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Min</text>",
    "<text x='720' y='160' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max</text>",
    "<text x='920' y='160' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Average</text>",
    "<line x1='80' y1='178' x2='1200' y2='178' stroke='#d8c9b7' stroke-width='2'/>",
    "<text x='110' y='240' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Latency [cycles]</text>",
    "<text x='520' y='240' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$latencyMin</text>",
    "<text x='720' y='240' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$latencyMax</text>",
    "<text x='920' y='240' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $latencyAvg 'F6')</text>",
    "<text x='110' y='320' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Input Valid Gap [cycles]</text>",
    "<text x='520' y='320' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$inputGapMin</text>",
    "<text x='720' y='320' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$inputGapMax</text>",
    "<text x='920' y='320' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $inputGapAvg 'F6')</text>",
    "<text x='110' y='400' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Output Valid Gap [cycles]</text>",
    "<text x='520' y='400' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$outputGapMin</text>",
    "<text x='720' y='400' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$outputGapMax</text>",
    "<text x='920' y='400' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>$(SvgFmt $outputGapAvg 'F6')</text>",
    "<text x='110' y='500' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Throughput</text>",
    "<text x='360' y='500' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Vectors/Cycle: $(SvgFmt $throughputPerCycle 'F9')</text>",
    "<text x='360' y='532' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Vectors/us: $(SvgFmt $throughputPerUs 'F6')</text>",
    "<text x='360' y='564' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Vectors/s: $(SvgFmt $throughputPerSecond 'F3')</text>",
    "<text x='60' y='640' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Delivery Rate: $(SvgFmt $deliveryRatePct 'F6') % | Overflow Rate: $(SvgFmt $overflowRatePct 'F6') % | PASS: $passFlag</text>",
    "</svg>"
) -join "`r`n"

Set-Content -LiteralPath $svgPath -Value $svg -Encoding UTF8

$report = @(
    "# TMQ006 - Pipeline Timing Characterization",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ006_PipelineTimingCharacterization",
    "- Objective: Measure latency, jitter between valid events and throughput under complex-IQ high-level stimulus.",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization.v",
    "",
    "## Timing Table",
    "",
    "- Latency: Min = $latencyMin, Max = $latencyMax, Average = $(SvgFmt $latencyAvg 'F6') cycles",
    "- Input Valid Gap: Min = $inputGapMin, Max = $inputGapMax, Average = $(SvgFmt $inputGapAvg 'F6') cycles",
    "- Output Valid Gap: Min = $outputGapMin, Max = $outputGapMax, Average = $(SvgFmt $outputGapAvg 'F6') cycles",
    "",
    "## Throughput",
    "",
    "- Vectors/Cycle: $(SvgFmt $throughputPerCycle 'F9')",
    "- Vectors/us: $(SvgFmt $throughputPerUs 'F6')",
    "- Vectors/s: $(SvgFmt $throughputPerSecond 'F3')",
    "",
    "## Execution Summary",
    "",
    "- Delivery Rate: $(SvgFmt $deliveryRatePct 'F6') %",
    "- Overflow Rate: $(SvgFmt $overflowRatePct 'F6') %",
    "- Simulation Time: $(SvgFmt $simTimeNs 'F0') ns",
    "- Wall Clock: $(SvgFmt $simWallClock.TotalSeconds 'F3') s",
    "- PASS Flag: $passFlag",
    "",
    "## Artifacts",
    "",
    "- Simulation Summary: tb_v3_2/tmq006_pipeline_timing_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ006/tmq006_pipeline_timing_stats.txt",
    "- Timing SVG: tb_v3_2/results/TMQ006/tmq006_pipeline_timing_table.svg",
    "- Final Report: tb_v3_2/results/TMQ006/TMQ006_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ006/TMQ006_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ006 - Pipeline Timing Characterization"
Write-Host "======================================================================"
Write-Host "Summary TXT   : $summaryPath"
Write-Host "Stats TXT     : $statsPath"
Write-Host "Timing SVG    : $svgPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "Latency Avg   : $(SvgFmt $latencyAvg 'F6')"
Write-Host "Throughput/us : $(SvgFmt $throughputPerUs 'F6')"
