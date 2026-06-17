<#
.SYNOPSIS
Converts data sizes between different units (decimal and binary).

.DESCRIPTION
The Convert-DataSize function converts a file or data size from one unit to another.
Supports both decimal units (KB, MB, GB, TB, PB - base 1000) and binary units
(KiB, MiB, GiB, TiB, PiB - base 1024).
If no output unit is specified, the function automatically selects the most appropriate
unit based on the calculated size in bytes.

.PARAMETER Size
The numeric value to convert. Can be any positive number, including decimals.

.PARAMETER InputUnit
The unit of the input size. Valid values are:
- Decimal: KB (1000), MB, GB, TB, PB
- Binary: KiB (1024), MiB, GiB, TiB, PiB
Default value is "GiB".

.PARAMETER OutputUnit
The unit to convert the size to. Can be any supported input unit.
If not specified, the function automatically selects the most appropriate unit,
preferring binary units (KiB, MiB, GiB, TiB, PiB).

.PARAMETER RoundUnits
The number of decimal places to round the output to.
Default value is 2. Minimum is 0, maximum is typically 15.

.EXAMPLE
Convert-DataSize -Size 1024 -InputUnit MiB -OutputUnit GiB
This command converts 1024 MiB to GiB.
Output: 1.00 GiB

.EXAMPLE
Convert-DataSize -Size 5 -InputUnit GiB
This command converts 5 GiB to the optimal unit (automatically determines GiB).
Output: 5.00 GiB

.EXAMPLE
Convert-DataSize -Size 1 -InputUnit TiB -OutputUnit MiB
This command converts 1 TiB to MiB.
Output: 1048576.00 MiB

.EXAMPLE
Convert-DataSize -Size 1000 -InputUnit KB -OutputUnit MB -RoundUnits 3
This command converts 1000 KB (decimal) to MB with 3 decimal places.
Output: 1.000 MB

.EXAMPLE
Convert-DataSize -Size 0.5 -InputUnit PiB
This command converts 0.5 PiB to the optimal unit.
Output: 512.00 TiB

.EXAMPLE
Convert-DataSize 1.5 MiB GiB
This command demonstrates positional parameters to convert 1.5 MiB to GiB.
Output: 0.00 GiB

.EXAMPLE
Convert-DataSize -Size 2000 -InputUnit KB -OutputUnit KiB
This command converts 2000 KB (decimal) to KiB (binary).
Output: 1953.13 KiB

.INPUTS
None. You cannot pipe objects to Convert-DataSize.

.OUTPUTS
System.String
Returns a formatted string with the converted size and unit.

.NOTES
- Decimal units (KB, MB, GB, TB, PB) use base 1000 multiplier.
- Binary units (KiB, MiB, GiB, TiB, PiB) use base 1024 multiplier.
- Automatic unit selection follows this hierarchy: PiB > TiB > GiB > MiB > KiB
- Decimal values are supported for both input and output.
- All output is returned as a formatted string.

.LINK
https://en.wikipedia.org/wiki/Byte#Multiple-byte_units
#>
function Convert-DataSize {
    param (
        [double]$Size,
        [ValidateSet("KB", "MB", "GB", "TB", "PB", "KiB", "MiB", "GiB", "TiB", "PiB")]
        [string]$InputUnit = "GiB",
        [ValidateSet("KB", "MB", "GB", "TB", "PB", "KiB", "MiB", "GiB", "TiB", "PiB")]
        [string]$OutputUnit,
        [int]$RoundUnits = 2
    )

    switch ($InputUnit) {
        "KB" { $SizeInBytes = $Size * 1000 }
        "MB" { $SizeInBytes = $Size * 1000 * 1000 }
        "GB" { $SizeInBytes = $Size * 1000 * 1000 * 1000 }
        "TB" { $SizeInBytes = $Size * 1000 * 1000 * 1000 * 1000 }
        "PB" { $SizeInBytes = $Size * 1000 * 1000 * 1000 * 1000 * 1000 }
        "KiB" { $SizeInBytes = $Size * 1024 }
        "MiB" { $SizeInBytes = $Size * 1024 * 1024 }
        "GiB" { $SizeInBytes = $Size * 1024 * 1024 * 1024 }
        "TiB" { $SizeInBytes = $Size * 1024 * 1024 * 1024 * 1024 }
        "PiB" { $SizeInBytes = $Size * 1024 * 1024 * 1024 * 1024 * 1024 }
    }

    if (-not $OutputUnit) {
        if ($SizeInBytes -ge [math]::Pow(1024, 5)) {
            $OutputUnit = "PiB"
        } elseif ($SizeInBytes -ge [math]::Pow(1024, 4)) {
            $OutputUnit = "TiB"
        } elseif ($SizeInBytes -ge [math]::Pow(1024, 3)) {
            $OutputUnit = "GiB"
        } elseif ($SizeInBytes -ge [math]::Pow(1024, 2)) {
            $OutputUnit = "MiB"
        } elseif ($SizeInBytes -ge [math]::Pow(1024, 1)) {
            $OutputUnit = "KiB"
        } else {
            $OutputUnit = "GiB"
        }
    }

    switch ($OutputUnit) {
        "KB" { $OutputSize = $SizeInBytes / 1000 }
        "MB" { $OutputSize = $SizeInBytes / (1000 * 1000) }
        "GB" { $OutputSize = $SizeInBytes / (1000 * 1000 * 1000) }
        "TB" { $OutputSize = $SizeInBytes / (1000 * 1000 * 1000 * 1000) }
        "PB" { $OutputSize = $SizeInBytes / (1000 * 1000 * 1000 * 1000 * 1000) }
        "KiB" { $OutputSize = $SizeInBytes / 1024 }
        "MiB" { $OutputSize = $SizeInBytes / (1024 * 1024) }
        "GiB" { $OutputSize = $SizeInBytes / (1024 * 1024 * 1024) }
        "TiB" { $OutputSize = $SizeInBytes / (1024 * 1024 * 1024 * 1024) }
        "PiB" { $OutputSize = $SizeInBytes / (1024 * 1024 * 1024 * 1024 * 1024) }
    }

    return "{0:N$RoundUnits} $OutputUnit" -f $OutputSize
}