$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceMd = Join-Path $scriptDir 'ARTIGO_CIENTIFICO_DPDnano_Lite_EN.md'
$targetMd = Join-Path $scriptDir 'ARTIGO_CIENTIFICO_DPDnano_Lite.md'
$outputDoc = Join-Path $scriptDir 'ARTIGO_CIENTIFICO_DPDnano_Lite_EN.docx'
$baseBuilder = Join-Path $scriptDir 'build_artigo_docx.ps1'

if(-not (Test-Path -LiteralPath $sourceMd)) { throw "English markdown file not found: $sourceMd" }
if(-not (Test-Path -LiteralPath $baseBuilder)) { throw "Base DOCX builder not found: $baseBuilder" }

$backup = $null
if(Test-Path -LiteralPath $targetMd) {
  $backup = Join-Path $env:TEMP ("ARTIGO_CIENTIFICO_DPDnano_Lite_backup_" + [guid]::NewGuid().ToString() + '.md')
  Copy-Item -LiteralPath $targetMd -Destination $backup -Force
}

try {
  Copy-Item -LiteralPath $sourceMd -Destination $targetMd -Force
  powershell -ExecutionPolicy Bypass -File $baseBuilder | Out-Null
  $generatedPtDoc = Join-Path $scriptDir 'ARTIGO_CIENTIFICO_DPDnano_Lite.docx'
  if(-not (Test-Path -LiteralPath $generatedPtDoc)) { throw 'Expected DOCX output was not generated.' }
  Copy-Item -LiteralPath $generatedPtDoc -Destination $outputDoc -Force
}
finally {
  if($backup -and (Test-Path -LiteralPath $backup)) {
    Copy-Item -LiteralPath $backup -Destination $targetMd -Force
    Remove-Item -LiteralPath $backup -Force
  }
}

Write-Output $outputDoc
