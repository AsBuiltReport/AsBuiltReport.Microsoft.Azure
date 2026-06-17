function Test-AbrAzInfoLevelEnabled {
    <#
    .SYNOPSIS
        Returns $true if at least one section in the provided order has a non-zero InfoLevel.
    .DESCRIPTION
        Iterates over a list of section names and inspects the corresponding InfoLevel value.
        Simple integer InfoLevels are compared directly to zero. Complex InfoLevel objects
        (e.g. Policy with Assignments/Definitions sub-keys) are summed; a non-zero sum is
        treated as enabled. Returns $true as soon as the first enabled section is found,
        otherwise returns $false.
    .PARAMETER SectionOrder
        Array of section name strings to evaluate, typically sourced from Options.SectionOrder
        in the report JSON configuration.
    .PARAMETER InfoLevel
        The InfoLevel object or hashtable from the report JSON configuration. Each key
        corresponds to a section name and holds either an integer (0-4) or a nested object.
    .EXAMPLE
        Test-AbrAzInfoLevelEnabled -SectionOrder $JsonConfig.Options.SectionOrder -InfoLevel $JsonConfig.InfoLevel
    .NOTES
        Version:    0.1.0
        Author:     Tim Carman
        Github:     tpcarman
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string[]] $SectionOrder,
        [Parameter(Mandatory)]
        [object] $InfoLevel
    )
    foreach ($SectionName in $SectionOrder) {
        $level = if ($InfoLevel.PSObject.Properties.Name -contains $SectionName) {
            $InfoLevel.$SectionName
        } elseif ($InfoLevel -is [hashtable] -and $InfoLevel.ContainsKey($SectionName)) {
            $InfoLevel[$SectionName]
        } else {
            continue
        }
        $enabled = switch ($level) {
            { $_ -is [hashtable] -or $_ -is [PSCustomObject] } {
                $sum = if ($_ -is [hashtable]) {
                    ($_.Values | Measure-Object -Sum).Sum
                } else {
                    ($_.PSObject.Properties.Value | ForEach-Object { [int]$_ } | Measure-Object -Sum).Sum
                }
                $sum -gt 0
            }
            default { try { [int]$_ -gt 0 } catch { $false } }
        }
        if ($enabled) { return $true }
    }
    return $false
}
