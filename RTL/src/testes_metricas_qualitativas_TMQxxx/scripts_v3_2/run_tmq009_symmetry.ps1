$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

$tbDir = Join-Path $repoRoot "tb_v3_2"
$resultsDir = Join-Path $tbDir "results"
$reportDir = Join-Path $resultsDir "TMQ009"
$summaryPath = Join-Path $tbDir "tmq009_symmetry_summary.txt"
$statsPath = Join-Path $reportDir "tmq009_symmetry_stats.txt"
$reportPath = Join-Path $reportDir "TMQ009_final_report.md"
$svgPath = Join-Path $reportDir "tmq009_symmetry_dashboard.svg"
$transcriptPath = Join-Path $reportDir "TMQ009_modelsim_transcript.log"
$doFile = Join-Path $scriptDir "run_tmq009_symmetry.do"
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
$deliveryRatePct = [double]$summary["delivery_rate_pct"]
$expectedLatency = [int]$summary["expected_latency"]
$measuredLatency = [int]$summary["measured_latency"]
$pairCount = [int]$summary["pair_count"]
$meanErrRe = [double]$summary["mean_abs_symmetry_error_re_lsb"]
$meanErrIm = [double]$summary["mean_abs_symmetry_error_im_lsb"]
$rmsErrMag = [double]$summary["rms_symmetry_error_mag_lsb"]
$maxErrReLsb = [int]$summary["max_abs_symmetry_error_re_lsb"]
$maxErrImLsb = [int]$summary["max_abs_symmetry_error_im_lsb"]
$maxErrMagLsb = [int]$summary["max_abs_symmetry_error_mag_lsb"]
$maxErrReReal = [double]$summary["max_abs_symmetry_error_re_real"]
$maxErrImReal = [double]$summary["max_abs_symmetry_error_im_real"]
$maxErrMagReal = [double]$summary["max_abs_symmetry_error_mag_real"]
$overflowTotal = [int]$summary["overflow_total"]
$overflowRatePct = [double]$summary["overflow_rate_pct"]
$xzErrors = [int]$summary["xz_errors"]
$simCycles = [int]$summary["simulation_cycles"]
$simTimeNs = [double]$summary["simulation_time_ns"]

$stats = @(
    "test_name=TMQ009_SymmetryCharacterization",
    "delivery_rate_pct=$([string]::Format($culture,'{0:F6}', $deliveryRatePct))",
    "expected_latency=$expectedLatency",
    "measured_latency=$measuredLatency",
    "pair_count=$pairCount",
    "mean_abs_symmetry_error_re_lsb=$([string]::Format($culture,'{0:F12}', $meanErrRe))",
    "mean_abs_symmetry_error_im_lsb=$([string]::Format($culture,'{0:F12}', $meanErrIm))",
    "rms_symmetry_error_mag_lsb=$([string]::Format($culture,'{0:F12}', $rmsErrMag))",
    "max_abs_symmetry_error_re_lsb=$maxErrReLsb",
    "max_abs_symmetry_error_im_lsb=$maxErrImLsb",
    "max_abs_symmetry_error_mag_lsb=$maxErrMagLsb",
    "max_abs_symmetry_error_re_real=$([string]::Format($culture,'{0:F12}', $maxErrReReal))",
    "max_abs_symmetry_error_im_real=$([string]::Format($culture,'{0:F12}', $maxErrImReal))",
    "max_abs_symmetry_error_mag_real=$([string]::Format($culture,'{0:F12}', $maxErrMagReal))",
    "overflow_total=$overflowTotal",
    "overflow_rate_pct=$([string]::Format($culture,'{0:F6}', $overflowRatePct))",
    "xz_errors=$xzErrors",
    "simulation_cycles=$simCycles",
    "simulation_time_ns=$([string]::Format($culture,'{0:F0}', $simTimeNs))",
    "wall_clock_seconds=$([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds))",
    "pass_flag=$passFlag"
) -join "`r`n"

Set-Content -LiteralPath $statsPath -Value $stats -Encoding UTF8

$maxBar = [Math]::Max([Math]::Max($maxErrReLsb, $maxErrImLsb), $maxErrMagLsb)
if ($maxBar -le 0) { $maxBar = 1 }
$barScale = 260.0 / $maxBar
$reBar = [int]([Math]::Round($maxErrReLsb * $barScale))
$imBar = [int]([Math]::Round($maxErrImLsb * $barScale))
$magBar = [int]([Math]::Round($maxErrMagLsb * $barScale))
$reBarY = 650 - $reBar
$imBarY = 650 - $imBar
$magBarY = 650 - $magBar

$svg = @(
    "<svg xmlns='http://www.w3.org/2000/svg' width='1380' height='780' viewBox='0 0 1380 780'>",
    "<rect width='100%' height='100%' fill='#f6efe3'/>",
    "<text x='40' y='42' font-size='28' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>TMQ009 - Symmetry Characterization</text>",
    "<text x='40' y='68' font-size='15' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Complex paired excitation x and -x with vector symmetry error y(x) + y(-x)</text>",
    "<rect x='50' y='100' width='560' height='250' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<rect x='640' y='100' width='690' height='250' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<text x='80' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Symmetry Metrics</text>",
    "<text x='80' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>PASS Flag: $passFlag</text>",
    "<text x='80' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Pairs Evaluated: $pairCount</text>",
    "<text x='80' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Mean |Error| RE [LSB]: $([string]::Format($culture,'{0:F6}', $meanErrRe))</text>",
    "<text x='80' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Mean |Error| IM [LSB]: $([string]::Format($culture,'{0:F6}', $meanErrIm))</text>",
    "<text x='80' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>RMS Error MAG [LSB]: $([string]::Format($culture,'{0:F6}', $rmsErrMag))</text>",
    "<text x='670' y='145' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Execution and Robustness</text>",
    "<text x='670' y='190' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Delivery Rate: $([string]::Format($culture,'{0:F6}', $deliveryRatePct)) %</text>",
    "<text x='670' y='225' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Latency: $measuredLatency / $expectedLatency cycles</text>",
    "<text x='670' y='260' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Overflow Events: $overflowTotal</text>",
    "<text x='670' y='295' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>X/Z Errors: $xzErrors</text>",
    "<text x='670' y='330' font-size='18' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Wall Clock: $([string]::Format($culture,'{0:F3}', $simWallClock.TotalSeconds)) s</text>",
    "<rect x='50' y='390' width='1280' height='320' fill='#fffdfa' stroke='#5d4e41' stroke-width='1.5'/>",
    "<text x='80' y='430' font-size='20' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Maximum Symmetry Error Comparison</text>",
    "<line x1='90' y1='650' x2='1240' y2='650' stroke='#5d4e41' stroke-width='1.5'/>",
    "<rect x='180' y='$reBarY' width='120' height='$reBar' fill='#2563eb' opacity='0.88'/>",
    "<rect x='430' y='$imBarY' width='120' height='$imBar' fill='#c2410c' opacity='0.85'/>",
    "<rect x='680' y='$magBarY' width='120' height='$magBar' fill='#0f766e' opacity='0.85'/>",
    "<text x='175' y='680' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max RE</text>",
    "<text x='425' y='680' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max IM</text>",
    "<text x='666' y='680' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2f2419'>Max MAG</text>",
    "<text x='175' y='345' font-size='14' font-family='Segoe UI, Arial, sans-serif' fill='#6d5a49'>Ideal target: y(-x) = -y(x), therefore symmetry error approaches zero.</text>",
    "<text x='920' y='500' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#2563eb'>Max RE [real]: $([string]::Format($culture,'{0:F8}', $maxErrReReal))</text>",
    "<text x='920' y='535' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#c2410c'>Max IM [real]: $([string]::Format($culture,'{0:F8}', $maxErrImReal))</text>",
    "<text x='920' y='570' font-size='16' font-family='Segoe UI, Arial, sans-serif' fill='#0f766e'>Max MAG [real]: $([string]::Format($culture,'{0:F8}', $maxErrMagReal))</text>",
    "</svg>"
) -join "`r`n"

Set-Content -LiteralPath $svgPath -Value $svg -Encoding UTF8

$report = @(
    "# TMQ009 - Symmetry Characterization",
    "",
    "## Test Identity",
    "",
    "- Test: TMQ009_SymmetryCharacterization",
    "- Objective: Compare paired complex inputs x and -x and measure the symmetry error y(x) + y(-x).",
    "- RTL Base: rtl_v3_1 frozen",
    "- Testbench: tb_v3_2/tb_dpdnano_lite_TMQ009_SymmetryCharacterization.v",
    "",
    "## Symmetry Result",
    "",
    "- PASS Flag: $passFlag",
    "- Symmetry Pairs: $pairCount",
    "- Mean |Error| RE [LSB]: $([string]::Format($culture,'{0:F12}', $meanErrRe))",
    "- Mean |Error| IM [LSB]: $([string]::Format($culture,'{0:F12}', $meanErrIm))",
    "- RMS Error MAG [LSB]: $([string]::Format($culture,'{0:F12}', $rmsErrMag))",
    "- Max |Error| RE / IM / MAG [LSB]: $maxErrReLsb / $maxErrImLsb / $maxErrMagLsb",
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
    "- Simulation Summary: tb_v3_2/tmq009_symmetry_summary.txt",
    "- Stats TXT: tb_v3_2/results/TMQ009/tmq009_symmetry_stats.txt",
    "- Symmetry SVG: tb_v3_2/results/TMQ009/tmq009_symmetry_dashboard.svg",
    "- Final Report: tb_v3_2/results/TMQ009/TMQ009_final_report.md",
    "- ModelSim Transcript: tb_v3_2/results/TMQ009/TMQ009_modelsim_transcript.log"
) -join "`r`n"

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "TMQ009 - Symmetry Characterization"
Write-Host "======================================================================"
Write-Host "Summary TXT  : $summaryPath"
Write-Host "Stats TXT    : $statsPath"
Write-Host "Symmetry SVG : $svgPath"
Write-Host "Final Report : $reportPath"
Write-Host "Transcript   : $transcriptPath"
Write-Host "PASS Flag    : $passFlag"
Write-Host "Mean Err RE/IM [LSB] : $([string]::Format($culture,'{0:F6}', $meanErrRe)) / $([string]::Format($culture,'{0:F6}', $meanErrIm))"
Write-Host "RMS Err MAG [LSB]   : $([string]::Format($culture,'{0:F6}', $rmsErrMag))"
