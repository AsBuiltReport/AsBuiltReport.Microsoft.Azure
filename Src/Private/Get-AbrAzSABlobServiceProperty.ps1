function Get-AbrAzSABlobServiceProperty {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Storage Account Blob Service Property information
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
        $AzSABlobServiceProperties = Get-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        if (($InfoLevel.StorageAccount -gt 0) -and ($AzSABlobServiceProperties)) {
            Write-PscriboMessage "Collecting Azure Storage Account Blob Service Property information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Blob Service Property' {
                $AzSASrvPrtyInfo = @()
                foreach ($AzSABlobServiceProperty in $AzSABlobServiceProperties) {
                    $InObj = [Ordered]@{
                        'Blob Soft Delete Status' = Switch ($AzSABlobServiceProperty.DeleteRetentionPolicy.Enabled) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                        'Blob Soft Delete Days' = "$($AzSABlobServiceProperty.DeleteRetentionPolicy.Days) days"
                        'Container Soft Delete Status' = Switch ($AzSABlobServiceProperty.ContainerDeleteRetentionPolicy.Enabled) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                        'Container Soft Delete Days' = "$($AzSABlobServiceProperty.ContainerDeleteRetentionPolicy.Days) days"
                        'Is Versioning Enabled' = Switch ($AzSABlobServiceProperty.IsVersioningEnabled) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                    }
                    $AzSASrvPrtyInfo = [PSCustomObject]$InObj
                }
                $TableParams = @{
                    Name = "Blob Service Property - $($AzSABlobServiceProperty.StorageAccountName)"
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