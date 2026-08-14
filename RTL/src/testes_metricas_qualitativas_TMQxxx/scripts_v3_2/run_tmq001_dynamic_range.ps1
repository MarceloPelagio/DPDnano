$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ001"
$csvPath = Join-Path $tbDir "tmq001_dynamic_range_samples.csv"
$summaryPath = Join-Path $tbDir "tmq001_dynamic_range_summary.txt"
$statsCsvPath = Join-Path $reportDir "tmq001_dynamic_range_stats.csv"
$reportPath = Join-Path $reportDir "TMQ001_final_report.md"
$transcriptPath = Join-Path $reportDir "TMQ001_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq001_dynamic_range.do"
$vsim = (Get-Command vsim.exe -ErrorAction Stop).Source

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
    throw "CSV de amostras não foi gerado: $csvPath"
}

if (-not (Test-Path $summaryPath)) {
    throw "Resumo da simulação não foi gerado: $summaryPath"
}

$summary = @{}
foreach ($line in Get-Content -LiteralPath $summaryPath) {
    if ($line -match "^\s*([^=]+)=(.*)$") {
        $summary[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$rows = Import-Csv -LiteralPath $csvPath
if ($rows.Count -eq 0) {
    throw "O CSV foi gerado, mas não contém amostras."
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

$stats = [System.Collections.Generic.List[object]]::new()

$inputRe = [double[]]($rows | ForEach-Object { [double]$_.input_re })
$inputIm = [double[]]($rows | ForEach-Object { [double]$_.input_im })
$outputRe = [double[]]($rows | ForEach-Object { [double]$_.output_re })
$outputIm = [double[]]($rows | ForEach-Object { [double]$_.output_im })
$overflow = [int[]]($rows | ForEach-Object { [int]$_.overflow })
$overflowRe = [int[]]($rows | ForEach-Object { [int]$_.overflow_re })
$overflowIm = [int[]]($rows | ForEach-Object { [int]$_.overflow_im })

$sampleCount = $rows.Count
$sumInPower = 0.0
$sumOutPower = 0.0
$sumInMag = 0.0
$sumOutMag = 0.0
$sumGainLinear = 0.0
$gainSamples = 0
$peakInMag = 0.0
$peakOutMag = 0.0
$peakInRe = 0.0
$peakInIm = 0.0
$peakOutRe = 0.0
$peakOutIm = 0.0
$nonZeroOut = 0
$nonZeroIn = 0
$maxAbsErrorRe = 0.0
$maxAbsErrorIm = 0.0
$sumAbsErrorRe = 0.0
$sumAbsErrorIm = 0.0
$zeroOutputVectors = 0

for ($i = 0; $i -lt $sampleCount; $i++) {
    $inRe = $inputRe[$i]
    $inIm = $inputIm[$i]
    $outRe = $outputRe[$i]
    $outIm = $outputIm[$i]

    $inMag = [Math]::Sqrt(($inRe * $inRe) + ($inIm * $inIm))
    $outMag = [Math]::Sqrt(($outRe * $outRe) + ($outIm * $outIm))

    $sumInPower += ($inRe * $inRe) + ($inIm * $inIm)
    $sumOutPower += ($outRe * $outRe) + ($outIm * $outIm)
    $sumInMag += $inMag
    $sumOutMag += $outMag

    if ($inMag -gt $peakInMag) { $peakInMag = $inMag }
    if ($outMag -gt $peakOutMag) { $peakOutMag = $outMag }
    if ([Math]::Abs($inRe) -gt $peakInRe) { $peakInRe = [Math]::Abs($inRe) }
    if ([Math]::Abs($inIm) -gt $peakInIm) { $peakInIm = [Math]::Abs($inIm) }
    if ([Math]::Abs($outRe) -gt $peakOutRe) { $peakOutRe = [Math]::Abs($outRe) }
    if ([Math]::Abs($outIm) -gt $peakOutIm) { $peakOutIm = [Math]::Abs($outIm) }

    if ($outRe -eq 0 -and $outIm -eq 0) { $zeroOutputVectors++ }
    if ($inMag -gt 0.0) { $nonZeroIn++ }
    if ($outMag -gt 0.0) { $nonZeroOut++ }

    if ($inMag -gt 0.0) {
        $sumGainLinear += ($outMag / $inMag)
        $gainSamples++
    }

    $absErrorRe = [Math]::Abs($outRe - $inRe)
    $absErrorIm = [Math]::Abs($outIm - $inIm)
    $sumAbsErrorRe += $absErrorRe
    $sumAbsErrorIm += $absErrorIm
    if ($absErrorRe -gt $maxAbsErrorRe) { $maxAbsErrorRe = $absErrorRe }
    if ($absErrorIm -gt $maxAbsErrorIm) { $maxAbsErrorIm = $absErrorIm }
}

$avgInMag = $sumInMag / $sampleCount
$avgOutMag = $sumOutMag / $sampleCount
$rmsIn = [Math]::Sqrt($sumInPower / $sampleCount)
$rmsOut = [Math]::Sqrt($sumOutPower / $sampleCount)
$crestIn = if ($rmsIn -gt 0.0) { $peakInMag / $rmsIn } else { 0.0 }
$crestOut = if ($rmsOut -gt 0.0) { $peakOutMag / $rmsOut } else { 0.0 }
$dynamicRangeInDb = if ($avgInMag -gt 0.0) { 20.0 * [Math]::Log10($peakInMag / $avgInMag) } else { 0.0 }
$dynamicRangeOutDb = if ($avgOutMag -gt 0.0) { 20.0 * [Math]::Log10($peakOutMag / $avgOutMag) } else { 0.0 }
$avgGainLinear = if ($gainSamples -gt 0) { $sumGainLinear / $gainSamples } else { 0.0 }
$avgGainDb = if ($avgGainLinear -gt 0.0) { 20.0 * [Math]::Log10($avgGainLinear) } else { 0.0 }
$overflowCount = ($overflow | Measure-Object -Sum).Sum
$overflowReCount = ($overflowRe | Measure-Object -Sum).Sum
$overflowImCount = ($overflowIm | Measure-Object -Sum).Sum
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]
$latencyCycles = [int]$summary["measured_latency"]
$txCount = [int]$summary["vectors_tx"]
$rxCount = [int]$summary["vectors_rx"]
$passFlag = [int]$summary["pass_flag"]
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$vectorsPerUs = if ($simTimeNs -gt 0.0) { $rxCount / ($simTimeNs / 1000.0) } else { 0.0 }
$vectorsPerSecond = if ($simTimeNs -gt 0.0) { $rxCount / ($simTimeNs / 1e9) } else { 0.0 }

Add-Stat $stats "sample_count" $sampleCount
Add-Stat $stats "vectors_tx" $txCount
Add-Stat $stats "vectors_rx" $rxCount
Add-Stat $stats "delivery_rate_pct" ([string]::Format("{0:F6}", $deliveryRatePct))
Add-Stat $stats "measured_latency_cycles" $latencyCycles
Add-Stat $stats "simulation_cycles" $simCycles
Add-Stat $stats "simulation_time_ns" ([string]::Format("{0:F0}", $simTimeNs))
Add-Stat $stats "wall_clock_seconds" ([string]::Format("{0:F3}", $simWallClock.TotalSeconds))
Add-Stat $stats "vectors_per_microsecond" ([string]::Format("{0:F6}", $vectorsPerUs))
Add-Stat $stats "vectors_per_second" ([string]::Format("{0:F3}", $vectorsPerSecond))
Add-Stat $stats "input_peak_re_abs" ([string]::Format("{0:F3}", $peakInRe))
Add-Stat $stats "input_peak_im_abs" ([string]::Format("{0:F3}", $peakInIm))
Add-Stat $stats "output_peak_re_abs" ([string]::Format("{0:F3}", $peakOutRe))
Add-Stat $stats "output_peak_im_abs" ([string]::Format("{0:F3}", $peakOutIm))
Add-Stat $stats "input_peak_magnitude" ([string]::Format("{0:F6}", $peakInMag))
Add-Stat $stats "output_peak_magnitude" ([string]::Format("{0:F6}", $peakOutMag))
Add-Stat $stats "input_average_magnitude" ([string]::Format("{0:F6}", $avgInMag))
Add-Stat $stats "output_average_magnitude" ([string]::Format("{0:F6}", $avgOutMag))
Add-Stat $stats "input_rms" ([string]::Format("{0:F6}", $rmsIn))
Add-Stat $stats "output_rms" ([string]::Format("{0:F6}", $rmsOut))
Add-Stat $stats "input_crest_factor" ([string]::Format("{0:F6}", $crestIn))
Add-Stat $stats "output_crest_factor" ([string]::Format("{0:F6}", $crestOut))
Add-Stat $stats "input_dynamic_range_db" ([string]::Format("{0:F6}", $dynamicRangeInDb))
Add-Stat $stats "output_dynamic_range_db" ([string]::Format("{0:F6}", $dynamicRangeOutDb))
Add-Stat $stats "average_gain_linear" ([string]::Format("{0:F6}", $avgGainLinear))
Add-Stat $stats "average_gain_db" ([string]::Format("{0:F6}", $avgGainDb))
Add-Stat $stats "overflow_count" $overflowCount
Add-Stat $stats "overflow_re_count" $overflowReCount
Add-Stat $stats "overflow_im_count" $overflowImCount
Add-Stat $stats "overflow_rate_pct" ([string]::Format("{0:F6}", $overflowRatePct))
Add-Stat $stats "zero_output_vectors" $zeroOutputVectors
Add-Stat $stats "nonzero_input_vectors" $nonZeroIn
Add-Stat $stats "nonzero_output_vectors" $nonZeroOut
Add-Stat $stats "average_abs_error_re" ([string]::Format("{0:F6}", ($sumAbsErrorRe / $sampleCount)))
Add-Stat $stats "average_abs_error_im" ([string]::Format("{0:F6}", ($sumAbsErrorIm / $sampleCount)))
Add-Stat $stats "max_abs_error_re" ([string]::Format("{0:F6}", $maxAbsErrorRe))
Add-Stat $stats "max_abs_error_im" ([string]::Format("{0:F6}", $maxAbsErrorIm))
Add-Stat $stats "max_overflow_burst" $summary["max_overflow_burst"]
Add-Stat $stats "input_zero_vectors" $summary["input_zero_vectors"]
Add-Stat $stats "input_fullscale_vectors" $summary["input_fullscale_vectors"]
Add-Stat $stats "pass_flag" $passFlag

$stats | Export-Csv -LiteralPath $statsCsvPath -NoTypeInformation -Encoding UTF8

$report = @(
    "# TMQ001 - Dynamic Range Characterization",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ001_DynamicRangeCharacterization",
    "- Description: Dynamic Range Characterization",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization.v",
    "- Samples: $sampleCount",
    "",
    "## Execution Summary",
    "",
    "- Vectors TX: $txCount",
    "- Vectors RX: $rxCount",
    "- Delivery Rate: $([string]::Format('{0:F6}', $deliveryRatePct)) %",
    "- PASS Flag: $passFlag",
    "- Measured Latency: $latencyCycles cycles",
    "- Simulation Cycles: $simCycles",
    "- Simulation Time: $([string]::Format('{0:F0}', $simTimeNs)) ns",
    "- Wall Clock: $([string]::Format('{0:F3}', $simWallClock.TotalSeconds)) s",
    "- Throughput: $([string]::Format('{0:F6}', $vectorsPerUs)) vectors/us",
    "",
    "## Dynamic Range Metrics",
    "",
    "- Input Peak Magnitude: $([string]::Format('{0:F6}', $peakInMag))",
    "- Output Peak Magnitude: $([string]::Format('{0:F6}', $peakOutMag))",
    "- Input Average Magnitude: $([string]::Format('{0:F6}', $avgInMag))",
    "- Output Average Magnitude: $([string]::Format('{0:F6}', $avgOutMag))",
    "- Input RMS: $([string]::Format('{0:F6}', $rmsIn))",
    "- Output RMS: $([string]::Format('{0:F6}', $rmsOut))",
    "- Input Crest Factor: $([string]::Format('{0:F6}', $crestIn))",
    "- Output Crest Factor: $([string]::Format('{0:F6}', $crestOut))",
    "- Input Dynamic Range: $([string]::Format('{0:F6}', $dynamicRangeInDb)) dB",
    "- Output Dynamic Range: $([string]::Format('{0:F6}', $dynamicRangeOutDb)) dB",
    "- Average Gain: $([string]::Format('{0:F6}', $avgGainLinear)) linear / $([string]::Format('{0:F6}', $avgGainDb)) dB",
    "",
    "## Overflow and Error Metrics",
    "",
    "- Overflow Count: $overflowCount",
    "- Overflow RE Count: $overflowReCount",
    "- Overflow IM Count: $overflowImCount",
    "- Overflow Rate: $([string]::Format('{0:F6}', $overflowRatePct)) %",
    "- Max Overflow Burst: $($summary['max_overflow_burst'])",
    "- Average Absolute Error RE: $([string]::Format('{0:F6}', ($sumAbsErrorRe / $sampleCount)))",
    "- Average Absolute Error IM: $([string]::Format('{0:F6}', ($sumAbsErrorIm / $sampleCount)))",
    "- Max Absolute Error RE: $([string]::Format('{0:F6}', $maxAbsErrorRe))",
    "- Max Absolute Error IM: $([string]::Format('{0:F6}', $maxAbsErrorIm))",
    "",
    "## Stimulus Coverage",
    "",
    "- Zero-Level Input Vectors: $($summary['input_zero_vectors'])",
    "- Full-Scale Input Vectors: $($summary['input_fullscale_vectors'])",
    "- Non-Zero Input Vectors: $nonZeroIn",
    "- Non-Zero Output Vectors: $nonZeroOut",
    "- Zero Output Vectors: $zeroOutputVectors",
    "",
    "## Artifacts",
    "",
    "- Samples CSV: tb_v3_2/tmq001_dynamic_range_samples.csv",
    "- Simulation Summary: tb_v3_2/tmq001_dynamic_range_summary.txt",
    "- Stats CSV: tb_v3_2/results/TMQ001/tmq001_dynamic_range_stats.csv",
    "- ModelSim Transcript: tb_v3_2/results/TMQ001/TMQ001_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ001 - Dynamic Range Characterization"
Write-Host "======================================================================"
Write-Host "Samples CSV   : $csvPath"
Write-Host "Summary TXT   : $summaryPath"
Write-Host "Stats CSV     : $statsCsvPath"
Write-Host "Final Report  : $reportPath"
Write-Host "Transcript    : $transcriptPath"
Write-Host "PASS Flag     : $passFlag"
Write-Host "Latency       : $latencyCycles cycles"
Write-Host "Overflow Rate : $([string]::Format("{0:F6}", $overflowRatePct)) %"
Write-Host "Wall Clock    : $([string]::Format("{0:F3}", $simWallClock.TotalSeconds)) s"
