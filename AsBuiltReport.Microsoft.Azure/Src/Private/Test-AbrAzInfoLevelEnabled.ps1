function Test-AbrAzInfoLevelEnabled {
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
