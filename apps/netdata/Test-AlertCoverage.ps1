param([switch]$RequireDeployed, [switch]$Offline)
$ErrorActionPreference = 'Stop'
$endpoint = 'https://homelab.tail239aaa.ts.net:8444'
$rulePath = Join-Path $PSScriptRoot 'health.d/homelab.conf'
$ruleText = Get-Content -LiteralPath $rulePath -Raw
$composeText = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'compose.yaml') -Raw
$inline = [regex]::Match($composeText, '(?ms)^  netdata_health:\r?\n(?:    #[^\n]*\n)*    content: \|\r?\n(?<content>.*?)(?=^  netdata_notifications:)')
if (-not $inline.Success) { throw 'Configuration health inline absente' }
$decoded = [regex]::Replace($inline.Groups['content'].Value, '(?m)^      ', '').Replace('$$', '$')
if ($decoded.Replace("`r`n", "`n").TrimEnd() -cne $ruleText.Replace("`r`n", "`n").TrimEnd()) {
    throw 'Regles inline et health.d/homelab.conf desynchronisees'
}
# Chaque dollar doit appartenir a une paire $$ dans le Compose.
if ($inline.Groups['content'].Value.Replace('$$', '') -match '\$') { throw 'Variable Netdata non protegee dans le Compose' }
if ($Offline -and $RequireDeployed) { throw 'Offline et RequireDeployed sont incompatibles' }
if ($Offline) { 'Parite inline/canonique et echappement verifies. Aucun test runtime.'; return }
$ruleBlocks = [regex]::Split($ruleText, '(?m)(?=^alarm:)') | Where-Object { $_ -match '^alarm:' }
$charts = Invoke-RestMethod "$endpoint/api/v1/charts" -TimeoutSec 20
$alarms = Invoke-RestMethod "$endpoint/api/v1/alarms?all" -TimeoutSec 20
$alarmValues = @($alarms.alarms.PSObject.Properties.Value)
$expected = @()
foreach ($block in $ruleBlocks) {
    $name = [regex]::Match($block, '(?m)^alarm:\s*(\S+)').Groups[1].Value
    $chartId = [regex]::Match($block, '(?m)^\s+on:\s*(\S+)').Groups[1].Value
    $chartProperty = $charts.charts.PSObject.Properties[$chartId]
    if ($null -eq $chartProperty) { throw "Graphique absent : $chartId ($name)" }
    foreach ($reference in [regex]::Matches($block, '\$\{([^}]+)\}')) {
        $dimension = $reference.Groups[1].Value
        if ($null -eq $chartProperty.Value.dimensions.PSObject.Properties[$dimension]) {
            throw "Dimension absente : $chartId / $dimension"
        }
    }
    $lookup = [regex]::Match($block, '(?m)^\s+lookup:.*\sof\s+(.+)$')
    if ($lookup.Success) {
        foreach ($dimension in $lookup.Groups[1].Value.Trim().Split(',')) {
            if ($null -eq $chartProperty.Value.dimensions.PSObject.Properties[$dimension.Trim()]) {
                throw "Dimension absente : $chartId / $dimension"
            }
        }
    }
    $expected += $name
    $loaded = @($alarmValues | Where-Object { $_.name -eq $name -and $_.chart -eq $chartId })
    if ($RequireDeployed -and $loaded.Count -ne 1) { throw "Regle non chargee : $name" }
    if ($RequireDeployed -and ($loaded[0].status -notin @('CLEAR', 'WARNING', 'CRITICAL') -or $null -eq $loaded[0].value)) {
        throw "Regle non evaluee : $name"
    }
}
if ($expected.Count -ne 23 -or ($expected | Select-Object -Unique).Count -ne 23) { throw 'Inventaire attendu incorrect' }
if ($RequireDeployed) {
    foreach ($native in @('oom_kill', '1hour_memory_hw_corrupted')) {
        $match = @($alarmValues | Where-Object name -eq $native)
        if ($match.Count -ne 1 -or $match[0].status -notin @('CLEAR','WARNING','CRITICAL') -or $null -eq $match[0].value) {
            throw "Regle native absente ou non evaluee : $native"
        }
    }
    $unexpected = @($alarmValues | Where-Object { $_.name -notin ($expected + @('oom_kill', '1hour_memory_hw_corrupted')) })
    if ($unexpected.Count) { throw 'Regles inattendues encore chargees : liste fermee non appliquee' }
    'Couverture runtime verifiee : 23 regles homelab et 2 regles natives evaluees.'
} else {
    'References verifiees : 23 graphiques et dimensions disponibles. Validation runtime non executee.'
}
