$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$baseDir = $PSScriptRoot
$sourceMd = Join-Path $baseDir 'Capitulo_7_Completo_DPDnano_Lite.md'
$templateDoc = Join-Path $baseDir 'Capitulo_6_Completo_DPDnano_Lite.docx'
$outputDoc = Join-Path $baseDir 'Capitulo_7_Completo_DPDnano_Lite.docx'
$figDir = Join-Path $baseDir '..\figuras_capitulo_7'

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
    'Caption' {
      $jc = New-Element $xml 'jc'; Add-Attr $jc 'val' 'center'
      $spacing = New-Element $xml 'spacing'; Add-Attr $spacing 'before' '80'; Add-Attr $spacing 'after' '120'
      [void]$pPr.AppendChild($jc); [void]$pPr.AppendChild($spacing); [void]$p.AppendChild($pPr)
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

function Add-ImageRelationship([xml]$relsXml, [string]$target) {
  $nsUri = 'http://schemas.openxmlformats.org/package/2006/relationships'
  $ids = @($relsXml.Relationships.Relationship | ForEach-Object { $_.Id })
  $n = 3000
  do { $rid = "rId_ch7_img_$n"; $n++ } while($ids -contains $rid)
  $rel = $relsXml.CreateElement('Relationship', $nsUri)
  $rel.SetAttribute('Id', $rid)
  $rel.SetAttribute('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image')
  $rel.SetAttribute('Target', $target)
  [void]$relsXml.Relationships.AppendChild($rel)
  $rid
}

function Get-ImageExtent([string]$imagePath) {
  $img = [System.Drawing.Image]::FromFile($imagePath)
  try {
    $maxWidthPx = 620
    $scale = [Math]::Min(1.0, $maxWidthPx / $img.Width)
    $widthPx = [int]($img.Width * $scale)
    $heightPx = [int]($img.Height * $scale)
    return @{
      Cx = [int]($widthPx * 9525)
      Cy = [int]($heightPx * 9525)
    }
  } finally {
    $img.Dispose()
  }
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

if(-not (Test-Path -LiteralPath $sourceMd)) { throw "Markdown nao encontrado: $sourceMd" }
if(-not (Test-Path -LiteralPath $templateDoc)) { throw "Template DOCX nao encontrado: $templateDoc" }
if(-not (Test-Path -LiteralPath $figDir)) { throw "Pasta de figuras nao encontrada: $figDir" }

$lines = Get-Content -LiteralPath $sourceMd -Encoding UTF8
$content = New-Object System.Collections.ArrayList

for($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i].TrimEnd()
  $trim = $line.Trim()
  if($trim.Length -eq 0) { continue }

  if($trim -match '^\[\[FIGURE:([^|]+)\|(.+)\]\]$') {
    [void]$content.Add([pscustomobject]@{
      Type = 'Figure'
      File = $matches[1].Trim()
      Caption = $matches[2].Trim()
    })
    continue
  }

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
  if($trim -match '^## ') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Heading1'; Text=$trim.Substring(3).Trim() })
    continue
  }
  if($trim -match '^### ') {
    [void]$content.Add([pscustomobject]@{ Type='Paragraph'; Kind='Heading2'; Text=$trim.Substring(4).Trim() })
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

if(Test-Path -LiteralPath $mediaDir) {
  Remove-Item -LiteralPath $mediaDir -Recurse -Force
}
New-Item -ItemType Directory -Path $mediaDir -Force | Out-Null

$imageRels = @($relsXml.Relationships.Relationship | Where-Object {
  $_.Type -eq 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image'
})
foreach($rel in $imageRels) {
  [void]$relsXml.Relationships.RemoveChild($rel)
}

$docPrId = 5000
foreach($item in $content) {
  if($item.Type -eq 'Paragraph') {
    [void]$body.AppendChild((New-ParagraphNode $xml $item.Text $item.Kind))
  } elseif($item.Type -eq 'Table') {
    [void]$body.AppendChild((New-TableNode $xml $item.Rows))
  } elseif($item.Type -eq 'Figure') {
    $src = Join-Path $figDir $item.File
    if(-not (Test-Path -LiteralPath $src)) { throw "Figura nao encontrada: $src" }
    $destName = [System.IO.Path]::GetFileName($item.File)
    Copy-Item -LiteralPath $src -Destination (Join-Path $mediaDir $destName) -Force
    $rid = Add-ImageRelationship $relsXml "media/$destName"
    $extent = Get-ImageExtent $src
    $imgNode = New-ImageParagraphNode $xml $rid $destName $extent.Cx $extent.Cy $docPrId
    $docPrId++
    [void]$body.AppendChild($imgNode)
    [void]$body.AppendChild((New-ParagraphNode $xml $item.Caption 'Caption'))
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
