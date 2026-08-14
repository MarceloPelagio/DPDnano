$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = $PSScriptRoot
$sourceMd = Join-Path $baseDir 'Capitulo_8_Conclusoes_DPDnano_Lite.md'
$templateDoc = Join-Path $baseDir 'Capitulo_7_Completo_DPDnano_Lite.docx'
$outputDoc = Join-Path $baseDir 'Capitulo_8_Conclusoes_DPDnano_Lite.docx'

function New-Element($xml, [string]$name) {
  $xml.CreateElement('w', $name, 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
}

function Add-Attr($node, [string]$name, [string]$value) {
  $attr = $node.OwnerDocument.CreateAttribute('w', $name, 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
  $attr.Value = $value
  [void]$node.Attributes.Append($attr)
}

function New-RunNode($xml, [string]$text, [switch]$Bold, [switch]$Italic) {
  $r = New-Element $xml 'r'
  if($Bold -or $Italic) {
    $rPr = New-Element $xml 'rPr'
    if($Bold) { [void]$rPr.AppendChild((New-Element $xml 'b')) }
    if($Italic) { [void]$rPr.AppendChild((New-Element $xml 'i')) }
    [void]$r.AppendChild($rPr)
  }
  $t = New-Element $xml 't'
  $space = $xml.CreateAttribute('xml', 'space', 'http://www.w3.org/XML/1998/namespace')
  $space.Value = 'preserve'
  [void]$t.Attributes.Append($space)
  $t.InnerText = $text
  [void]$r.AppendChild($t)
  $r
}

function Add-RunsFromInlineMarkdown($xml, $paragraph, [string]$text) {
  $segments = [regex]::Split($text, '(\*\*[^*]+\*\*|\*[^*]+\*)')
  foreach($seg in $segments) {
    if([string]::IsNullOrEmpty($seg)) { continue }
    if($seg -match '^\*\*([^*]+)\*\*$') {
      [void]$paragraph.AppendChild((New-RunNode $xml $matches[1] -Bold))
    } elseif($seg -match '^\*([^*]+)\*$') {
      [void]$paragraph.AppendChild((New-RunNode $xml $matches[1] -Italic))
    } else {
      [void]$paragraph.AppendChild((New-RunNode $xml $seg))
    }
  }
}

function New-ParagraphNode($xml, [string]$text, [string]$kind) {
  $p = New-Element $xml 'p'
  $pPr = New-Element $xml 'pPr'
  switch($kind) {
    'Title' {
      $pStyle = New-Element $xml 'pStyle'; Add-Attr $pStyle 'val' 'Heading1'
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'center'
      $spacing = New-Element $xml 'spacing'; Add-Attr $spacing 'before' '0'; Add-Attr $spacing 'after' '240'
      [void]$pPr.AppendChild($pStyle); [void]$pPr.AppendChild($jc); [void]$pPr.AppendChild($spacing)
      [void]$p.AppendChild($pPr)
      [void]$p.AppendChild((New-RunNode $xml $text -Bold))
    }
    'Heading1' {
      $pStyle = New-Element $xml 'pStyle'; Add-Attr $pStyle 'val' 'Heading1'
      [void]$pPr.AppendChild($pStyle); [void]$p.AppendChild($pPr)
      Add-RunsFromInlineMarkdown $xml $p $text
    }
    'Heading2' {
      $pStyle = New-Element $xml 'pStyle'; Add-Attr $pStyle 'val' 'Heading2'
      [void]$pPr.AppendChild($pStyle); [void]$p.AppendChild($pPr)
      Add-RunsFromInlineMarkdown $xml $p $text
    }
    default {
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'both'
      [void]$pPr.AppendChild($jc); [void]$p.AppendChild($pPr)
      Add-RunsFromInlineMarkdown $xml $p $text
    }
  }
  $p
}

function Split-MarkdownRow([string]$line) {
  $trimmed = $line.Trim()
  if($trimmed.StartsWith('|')) { $trimmed = $trimmed.Substring(1) }
  if($trimmed.EndsWith('|')) { $trimmed = $trimmed.Substring(0, $trimmed.Length - 1) }
  $cells = New-Object System.Collections.Generic.List[string]
  $current = New-Object System.Text.StringBuilder
  foreach($ch in $trimmed.ToCharArray()) {
    if($ch -eq '|') {
      $cells.Add($current.ToString().Trim())
      [void]$current.Clear()
    } else {
      [void]$current.Append($ch)
    }
  }
  $cells.Add($current.ToString().Trim())
  @($cells)
}

function New-TableCell($xml, [string]$text, [switch]$Header) {
  $tc = New-Element $xml 'tc'
  $tcPr = New-Element $xml 'tcPr'
  $tcW = New-Element $xml 'tcW'
  Add-Attr $tcW 'w' '0'
  Add-Attr $tcW 'type' 'auto'
  [void]$tcPr.AppendChild($tcW)
  [void]$tc.AppendChild($tcPr)
  $p = New-Element $xml 'p'
  $pPr = New-Element $xml 'pPr'
  $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'both'
  [void]$pPr.AppendChild($jc); [void]$p.AppendChild($pPr)
  if($Header) {
    [void]$p.AppendChild((New-RunNode $xml $text -Bold))
  } else {
    Add-RunsFromInlineMarkdown $xml $p $text
  }
  [void]$tc.AppendChild($p)
  $tc
}

function New-TableNode($xml, $rows) {
  $tbl = New-Element $xml 'tbl'
  $tblPr = New-Element $xml 'tblPr'
  $tblStyle = New-Element $xml 'tblStyle'; Add-Attr $tblStyle 'val' 'TableGrid'
  $tblW = New-Element $xml 'tblW'; Add-Attr $tblW 'w' '5000'; Add-Attr $tblW 'type' 'pct'
  $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'center'
  [void]$tblPr.AppendChild($tblStyle); [void]$tblPr.AppendChild($tblW); [void]$tblPr.AppendChild($jc)
  [void]$tbl.AppendChild($tblPr)
  $maxCols = ($rows | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
  $tblGrid = New-Element $xml 'tblGrid'
  for($i=0; $i -lt $maxCols; $i++) {
    $gridCol = New-Element $xml 'gridCol'
    Add-Attr $gridCol 'w' ([string][int](9000 / [Math]::Max($maxCols, 1)))
    [void]$tblGrid.AppendChild($gridCol)
  }
  [void]$tbl.AppendChild($tblGrid)
  for($r=0; $r -lt $rows.Count; $r++) {
    $tr = New-Element $xml 'tr'
    foreach($cell in $rows[$r]) {
      [void]$tr.AppendChild((New-TableCell $xml $cell -Header:($r -eq 0)))
    }
    [void]$tbl.AppendChild($tr)
  }
  $tbl
}

if(-not (Test-Path -LiteralPath $sourceMd)) { throw "Markdown nao encontrado: $sourceMd" }
if(-not (Test-Path -LiteralPath $templateDoc)) { throw "Template DOCX nao encontrado: $templateDoc" }

$lines = Get-Content -LiteralPath $sourceMd -Encoding UTF8
$content = New-Object System.Collections.ArrayList

for($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i].TrimEnd()
  $trim = $line.Trim()
  if($trim.Length -eq 0) { continue }

  if($trim -match '^\|') {
    $tableRows = New-Object System.Collections.ArrayList
    while($i -lt $lines.Count) {
      $current = $lines[$i].Trim()
      if($current -notmatch '^\|') { break }
      if($current -match '^\|(?:\s*[-:]+\s*\|)+\s*$') { $i++; continue }
      [void]$tableRows.Add((Split-MarkdownRow $current))
      $i++
    }
    $i--
    if($tableRows.Count -gt 0) {
      [void]$content.Add([pscustomobject]@{ Type='Table'; Rows=@($tableRows) })
    }
    continue
  }

  if($trim -match '^# (.+)$') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Title'; Text=$matches[1].Trim() })
  } elseif($trim -match '^## (.+)$') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Heading1'; Text=$matches[1].Trim() })
  } elseif($trim -match '^### (.+)$') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Heading2'; Text=$matches[1].Trim() })
  } else {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Body'; Text=$trim })
  }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cap8_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
try {
  Copy-Item -LiteralPath $templateDoc -Destination $outputDoc -Force
  $zipPath = Join-Path $tempRoot 'cap8.zip'
  Copy-Item -LiteralPath $outputDoc -Destination $zipPath -Force
  $extractDir = Join-Path $tempRoot 'unzipped'
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractDir)

  $docXmlPath = Join-Path $extractDir 'word\document.xml'
  [xml]$docXml = Get-Content -LiteralPath $docXmlPath -Raw -Encoding UTF8
  $ns = New-Object System.Xml.XmlNamespaceManager($docXml.NameTable)
  $ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
  $body = $docXml.SelectSingleNode('//w:body', $ns)
  $sectPr = $body.SelectSingleNode('w:sectPr', $ns)

  $toRemove = @()
  foreach($child in @($body.ChildNodes)) {
    if($sectPr -and $child -eq $sectPr) { continue }
    $toRemove += $child
  }
  foreach($child in $toRemove) {
    [void]$body.RemoveChild($child)
  }

  foreach($item in $content) {
    if($item.Type -eq 'Paragraph') {
      [void]$body.InsertBefore((New-ParagraphNode $docXml $item.Text $item.Kind), $sectPr)
    } elseif($item.Type -eq 'Table') {
      [void]$body.InsertBefore((New-TableNode $docXml $item.Rows), $sectPr)
    }
  }

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($docXmlPath, $docXml.OuterXml, $utf8NoBom)

  Remove-Item -LiteralPath $zipPath -Force
  [System.IO.Compression.ZipFile]::CreateFromDirectory($extractDir, $zipPath)
  Copy-Item -LiteralPath $zipPath -Destination $outputDoc -Force
  Write-Output $outputDoc
}
finally {
  if(Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
