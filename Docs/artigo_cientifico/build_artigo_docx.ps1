$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = $PSScriptRoot
$sourceMd = Join-Path $baseDir 'ARTIGO_CIENTIFICO_DPDnano_Lite.md'
$templateDoc = Join-Path $baseDir '..\0-TCC DPDnano documentos\WORDs\Capitulo_1_Completo_DPDnano_Lite.docx'
$outputDoc = Join-Path $baseDir 'ARTIGO_CIENTIFICO_DPDnano_Lite.docx'
$figDir = Join-Path $baseDir '..\0-TCC DPDnano documentos\figuras_capitulo_6_png'

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
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'center'
      $spacing = New-Element $xml 'spacing'; Add-Attr $spacing 'before' '0'; Add-Attr $spacing 'after' '240'
      [void]$pPr.AppendChild($jc); [void]$pPr.AppendChild($spacing); [void]$p.AppendChild($pPr)
      $r = New-Element $xml 'r'
      $rPr = New-Element $xml 'rPr'
      [void]$rPr.AppendChild((New-Element $xml 'b'))
      $sz = New-Element $xml 'sz'; Add-Attr $sz 'val' '30'
      $szCs = New-Element $xml 'szCs'; Add-Attr $szCs 'val' '30'
      [void]$rPr.AppendChild($sz); [void]$rPr.AppendChild($szCs); [void]$r.AppendChild($rPr)
      $t = New-Element $xml 't'
      $space = $xml.CreateAttribute('xml', 'space', 'http://www.w3.org/XML/1998/namespace')
      $space.Value = 'preserve'
      [void]$t.Attributes.Append($space)
      $t.InnerText = $text
      [void]$r.AppendChild($t)
      [void]$p.AppendChild($r)
    }
    'Subtitle' {
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'center'
      $spacing = New-Element $xml 'spacing'; Add-Attr $spacing 'before' '0'; Add-Attr $spacing 'after' '120'
      [void]$pPr.AppendChild($jc); [void]$pPr.AppendChild($spacing); [void]$p.AppendChild($pPr)
      Add-RunsFromInlineMarkdown $xml $p $text
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
    'Caption' {
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'center'
      $spacing = New-Element $xml 'spacing'; Add-Attr $spacing 'before' '80'; Add-Attr $spacing 'after' '80'
      [void]$pPr.AppendChild($jc); [void]$pPr.AppendChild($spacing); [void]$p.AppendChild($pPr)
      Add-RunsFromInlineMarkdown $xml $p $text
    }
    'List' {
      $ind = New-Element $xml 'ind'; Add-Attr $ind 'left' '720'; Add-Attr $ind 'hanging' '360'
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'both'
      [void]$pPr.AppendChild($ind); [void]$pPr.AppendChild($jc); [void]$p.AppendChild($pPr)
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
  $inCode = $false
  foreach($ch in $trimmed.ToCharArray()) {
    if($ch -eq '`') {
      $inCode = -not $inCode
      [void]$current.Append($ch)
      continue
    }
    if(($ch -eq '|') -and (-not $inCode)) {
      $cells.Add($current.ToString().Trim())
      [void]$current.Clear()
      continue
    }
    [void]$current.Append($ch)
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
      $tc = New-TableCell $xml $cell -Header:($r -eq 0)
      [void]$tr.AppendChild($tc)
    }
    [void]$tbl.AppendChild($tr)
  }
  $tbl
}

function New-ImageParagraphNode($xml, $relId, $name, $cx, $cy, $docPrId) {
  $frag = @"
<w:p xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
     xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
     xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
     xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
     xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:pPr><w:jc w:val="center"/><w:spacing w:before="120" w:after="60"/></w:pPr>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="$cx" cy="$cy"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="$docPrId" name="$name"/>
        <wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>
        <a:graphic>
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic>
              <pic:nvPicPr>
                <pic:cNvPr id="0" name="$name"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="$relId"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
"@
  $tmpDoc = New-Object System.Xml.XmlDocument
  $tmpDoc.LoadXml($frag)
  $xml.ImportNode($tmpDoc.DocumentElement, $true)
}

function Add-ImageRelationship([xml]$relsXml, [string]$target) {
  $nsUri = 'http://schemas.openxmlformats.org/package/2006/relationships'
  $ids = @($relsXml.Relationships.Relationship | ForEach-Object { $_.Id })
  $n = 900
  do { $rid = "rId_art_img_$n"; $n++ } while($ids -contains $rid)
  $rel = $relsXml.CreateElement('Relationship', $nsUri)
  $rel.SetAttribute('Id', $rid)
  $rel.SetAttribute('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image')
  $rel.SetAttribute('Target', $target)
  [void]$relsXml.Relationships.AppendChild($rel)
  $rid
}

if(-not (Test-Path -LiteralPath $sourceMd)) { throw "Arquivo markdown nao encontrado: $sourceMd" }
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

  if($trim -match '^# ') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Title'; Text=$trim.Substring(2).Trim() })
    continue
  }
  if($trim -match '^\*\*Autores:\*\*' -or $trim -match '^\*\*Instituição:\*\*' -or $trim -match '^\*\*Curso:\*\*' -or $trim -match '^\*\*E-mail:\*\*') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Subtitle'; Text=($trim -replace '\s{2,}$','') })
    continue
  }
  if($trim -match '^## ') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Heading1'; Text=$trim.Substring(3).Trim() })
    continue
  }
  if($trim -match '^### ') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Heading2'; Text=$trim.Substring(4).Trim() })
    continue
  }
  if($trim -match '^\d+\. ') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='List'; Text=$trim })
    continue
  }
  [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Body'; Text=$trim })
}

if(Test-Path -LiteralPath $outputDoc) { Remove-Item -LiteralPath $outputDoc -Force }
Copy-Item -LiteralPath $templateDoc -Destination $outputDoc -Force

$tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($outputDoc, $tmp)

$docXmlPath = Join-Path $tmp 'word/document.xml'
$relsPath = Join-Path $tmp 'word/_rels/document.xml.rels'
$mediaDir = Join-Path $tmp 'word/media'
[xml]$xml = Get-Content -LiteralPath $docXmlPath -Raw -Encoding UTF8
[xml]$relsXml = Get-Content -LiteralPath $relsPath -Raw -Encoding UTF8
$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('w','http://schemas.openxmlformats.org/wordprocessingml/2006/main')
$body = $xml.SelectSingleNode('//w:body', $ns)
$sectPr = $body.SelectSingleNode('w:sectPr', $ns)
while($body.FirstChild) { [void]$body.RemoveChild($body.FirstChild) }

$figureMap = @(
  @{ Key='TMQ002'; File='tmq002_gain_vs_input.png'; Caption='Figura 1 - Ganho medido em funcao da amplitude de entrada no ensaio TMQ002.'; Cx=5800000; Cy=3200000 }
  @{ Key='TMQ003'; File='tmq003_polynomial_response.png'; Caption='Figura 2 - Comparacao entre contribuicao linear, contribuicao cubica e resposta total no ensaio TMQ003.'; Cx=5800000; Cy=3300000 }
  @{ Key='TMQ004'; File='tmq004_quantization_histogram.png'; Caption='Figura 3 - Histograma do erro de quantizacao em LSB no ensaio TMQ004.'; Cx=5600000; Cy=3200000 }
  @{ Key='TMQ010'; File='tmq010_repeatability_dashboard.png'; Caption='Figura 4 - Dashboard de repetibilidade e saturacao do ensaio TMQ010.'; Cx=6000000; Cy=3450000 }
  @{ Key='TMQ011'; File='tmq011_safe_region.png'; Caption='Figura 5 - Regiao segura de coeficientes reais sem saturacao no ensaio TMQ011.'; Cx=6200000; Cy=3600000 }
  @{ Key='TMQ012'; File='tmq012_complex_safe_region.png'; Caption='Figura 6 - Regiao segura de coeficientes complexos sem saturacao no ensaio TMQ012.'; Cx=6200000; Cy=3600000 }
  @{ Key='TMQ013'; File='tmq013_operational_limit_dashboard.png'; Caption='Figura 7 - Dashboard de limite operacional e saturacao progressiva no ensaio TMQ013.'; Cx=6200000; Cy=3600000 }
)

$insertedFigureKeys = New-Object System.Collections.Generic.HashSet[string]

$docPrId = 2000
foreach($item in $content) {
  if($item.Type -eq 'Paragraph') {
    $pNode = New-ParagraphNode $xml $item.Text $item.Kind
    [void]$body.AppendChild($pNode)
    foreach($fig in $figureMap) {
      if(($item.Text -like "*$($fig.Key)*") -and (-not $insertedFigureKeys.Contains($fig.Key))) {
        $src = Join-Path $figDir $fig.File
        if(Test-Path -LiteralPath $src) {
          Copy-Item -LiteralPath $src -Destination (Join-Path $mediaDir $fig.File) -Force
          $rid = Add-ImageRelationship $relsXml "media/$($fig.File)"
          $imgNode = New-ImageParagraphNode $xml $rid $fig.File $fig.Cx $fig.Cy $docPrId
          $docPrId++
          [void]$body.AppendChild($imgNode)
          [void]$body.AppendChild((New-ParagraphNode $xml $fig.Caption 'Caption'))
          [void]$insertedFigureKeys.Add($fig.Key)
        }
      }
    }
  } elseif($item.Type -eq 'Table') {
    [void]$body.AppendChild((New-TableNode $xml $item.Rows))
  }
}

if($sectPr) { [void]$body.AppendChild($sectPr) }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($docXmlPath, $xml.OuterXml, $utf8NoBom)
[System.IO.File]::WriteAllText($relsPath, $relsXml.OuterXml, $utf8NoBom)

$tmpOut = "$outputDoc.$([guid]::NewGuid().ToString()).tmp"
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $tmpOut)
if(Test-Path -LiteralPath $outputDoc) { Remove-Item -LiteralPath $outputDoc -Force }
Move-Item -LiteralPath $tmpOut -Destination $outputDoc -Force
Remove-Item -LiteralPath $tmp -Recurse -Force

Write-Output $outputDoc
