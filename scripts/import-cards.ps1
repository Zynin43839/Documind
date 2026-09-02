<#
.SYNOPSIS
  Import a task card from a .md file into a GitHub Projects v2 project.

.DESCRIPTION
  Reads a task-card template .md file (see docs/task-card-template.md),
  takes the first "# Title" line as the item title, the rest as the body,
  creates a draft issue on the board, then optionally sets fields
  (Priority / Epic / Work Type) parsed from the "Metadata" section.

.PARAMETER BoardNumber
  Project number (default: 2 = Documind).

.PARAMETER File
  Path to the .md task card file.

.PARAMETER Owner
  Owner login, use "@me" for the current user (default "@me").

.PARAMETER SetFields
  Switch. If present, parse Metadata (Priority/Epic/Type/Work Type)
  and set the matching single-select fields on the created item.

.EXAMPLE
  .\scripts\import-cards.ps1 -File .\docs\task-card-template.md
  .\scripts\import-cards.ps1 -File .\docs\card-login.md -SetFields
#>
param(
    [int]$BoardNumber = 2,
    [string]$File,
    [string]$Owner = "@me",
    [switch]$SetFields
)

$ErrorActionPreference = "Stop"

if (-not $File -or -not (Test-Path -LiteralPath $File)) {
    Write-Error "File not found: $File"
    exit 1
}

# Read file as UTF-8 (Thai-safe)
$content = Get-Content -LiteralPath $File -Raw -Encoding UTF8
if (-not $content) { Write-Error "Empty file: $File"; exit 1 }

# Split title (first line starting with '# ') and body (rest)
$lines = $content -split "`r?`n"
$titleLine = ($lines | Where-Object { $_ -match '^#\s' } | Select-Object -First 1)
if (-not $titleLine) {
    Write-Error "No '# Title' line found in: $File"
    exit 1
}
$title = $titleLine -replace '^#\s+', ''
$body = (($lines | Where-Object { $_ -notmatch '^#\s' }) -join "`n").Trim()

Write-Host "=== Importing card ==="
Write-Host "Title : $title"
Write-Host "Board : #$BoardNumber ($Owner)"

# Create the draft issue and capture the item id directly (robust, no title matching)
$createOutJson = gh project item-create $BoardNumber --owner $Owner --title $title --body $body --format json 2>&1
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Host $createOutJson
    Write-Error "item-create failed (exit $code)"
    exit $code
}
$createdObj = $createOutJson | ConvertFrom-Json
$itemId = $createdObj.id
Write-Host "Created item id : $itemId"

# Optional: set fields from Metadata section
if ($SetFields) {
    # Map field name -> value parsed from Metadata lines like "Priority: High"
    $meta = @{}
    if ($body -match '(?m)^\s*[-*]?\s*Priority:\s*(.+)$')     { $meta['Priority']   = $Matches[1].Trim() }
    if ($body -match '(?m)^\s*[-*]?\s*Epic:\s*(.+)$')         { $meta['Epic']       = $Matches[1].Trim() }
    if ($body -match '(?m)^\s*[-*]?\s*(Type|Work Type):\s*(.+)$') { $meta['Work Type'] = $Matches[2].Trim() }
    if ($body -match '(?m)^\s*[-*]?\s*Status:\s*(.+)$')       { $meta['Status']     = $Matches[1].Trim() }
    if ($body -match '(?m)^\s*[-*]?\s*Sprint:\s*(.+)$')       { $meta['Sprint']     = $Matches[1].Trim() }
    if ($body -match '(?m)^\s*[-*]?\s*Due Date:\s*(.+)$')     { $meta['Due Date']   = $Matches[1].Trim() }

    # Get project id from project list
    $projectJson = gh project list --owner $Owner --format json 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "project list failed"; exit 1 }
    $projects = ($projectJson | ConvertFrom-Json).projects
    $proj = $projects | Where-Object { $_.number -eq $BoardNumber } | Select-Object -First 1
    if (-not $proj) { Write-Error "Project #$BoardNumber not found"; exit 1 }
    $projectId = $proj.id

    # Get field + option ids
    $fieldsJson = gh project field-list $BoardNumber --owner $Owner --format json 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "field-list failed"; exit 1 }
    $fields = $fieldsJson | ConvertFrom-Json

    foreach ($fieldName in @('Priority','Epic','Work Type','Status','Sprint')) {
        if (-not $meta.ContainsKey($fieldName)) { continue }
        $fieldObj = $fields.fields | Where-Object { $_.name -eq $fieldName -and $_.type -eq 'ProjectV2SingleSelectField' } | Select-Object -First 1
        if (-not $fieldObj) {
            Write-Host "  skip $fieldName (field not found)"
            continue
        }
        $opt = $fieldObj.options | Where-Object { $_.name -ieq $meta[$fieldName] } | Select-Object -First 1
        if (-not $opt) {
            Write-Host "  skip $fieldName (option '$($meta[$fieldName])' not found)"
            continue
        }
        gh project item-edit --owner $Owner --id $itemId --project-id $projectId --field-id $fieldObj.id --single-select-option-id $opt.id 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  set $fieldName = $($opt.name)"
        } else {
            Write-Host "  FAILED set $fieldName"
        }
    }

    # Due Date is a DATE field (set via --date), separate from single-select fields
    if ($meta.ContainsKey('Due Date') -and $meta['Due Date'] -notin @('-','')) {
        $ddField = $fields.fields | Where-Object { $_.name -eq 'Due Date' } | Select-Object -First 1
        if (-not $ddField) {
            Write-Host "  skip Due Date (field not found)"
        } else {
            gh project item-edit --owner $Owner --id $itemId --project-id $projectId --field-id $ddField.id --date $meta['Due Date'] 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  set Due Date = $($meta['Due Date'])"
            } else {
                Write-Host "  FAILED set Due Date"
            }
        }
    }
}

Write-Host "=== Done ==="
