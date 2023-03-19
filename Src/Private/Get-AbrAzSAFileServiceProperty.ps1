function Get-AbrAzSAFileServiceProperty {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Storage Account File Service Property information
    .DESCRIPTION

    .NOTES
        Version:        0.1.5
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ResourceGroupName,
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $StorageAccountName
    )

    begin {
        Write-PScriboMessage "StorageAccount InfoLevel set at $($InfoLevel.StorageAccount)."
    }

    process {
        $AzSAFileServiceProperties = Get-AzStorageFileServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        if (($InfoLevel.StorageAccount -gt 0) -and ($AzSAFileServiceProperties)) {
            Write-PscriboMessage "Collecting Azure Storage Account File Service Property information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'File Service Property' {
                $AzSASrvPrtyInfo = @()
                foreach ($AzSAFileServiceProperty in $AzSAFileServiceProperties) {
                    $InObj = [Ordered]@{
                        'Soft Delete' = Switch ($AzSAFileServiceProperty.ShareDeleteRetentionPolicy.Enabled) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                        'Soft Delete Days' = "$($AzSAFileServiceProperty.ShareDeleteRetentionPolicy.Days) days"
                    }
                    $AzSASrvPrtyInfo = [PSCustomObject]$InObj
                }
                $TableParams = @{
                    Name = "File Service Property - $($AzSAFileServiceProperty.StorageAccountName)"
                    List = $true
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzSASrvPrtyInfo | Table @TableParams
            }
        }
    }

    end {}
}