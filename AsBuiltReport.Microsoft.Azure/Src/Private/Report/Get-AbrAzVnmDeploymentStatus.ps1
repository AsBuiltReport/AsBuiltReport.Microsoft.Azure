function Get-AbrAzVnmDeploymentStatus {
    <#
    .SYNOPSIS
        Used by As Built Report to report Azure Virtual Network Manager configuration deployments
    .DESCRIPTION
        Documents the regional deployment status of Azure Virtual Network Manager configurations, in Word/HTML/Text
        formats using PScribo. Deployment status records are collected once by Get-AbrAzVirtualNetworkManager and
        passed in, because the configuration sections also use them.
    .NOTES
        Version:        0.3.1
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $NetworkManagerName,

        # Deployment status records for the network manager; $null when they could not be collected
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object[]] $DeploymentStatus
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVnmDeploymentStatus
    }

    process {
        Try {
            if ($null -eq $DeploymentStatus) {
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    Paragraph ($LocalizedData.Unavailable -f $NetworkManagerName)
                }
            } elseif ($DeploymentStatus.Count -gt 0) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $NetworkManagerName)
                $AzDeploymentInfo = foreach ($AzDeployment in $DeploymentStatus) {
                    [PSCustomObject]@{
                        $LocalizedData.Region = $(if ($AzLocationLookup."$($AzDeployment.Region)") {
                            $AzLocationLookup."$($AzDeployment.Region)"
                        } else {
                            $AzDeployment.Region
                        })
                        $LocalizedData.DeploymentType = switch ($AzDeployment.DeploymentType) {
                            'Connectivity' { $LocalizedData.Connectivity }
                            'SecurityAdmin' { $LocalizedData.SecurityAdmin }
                            'Routing' { $LocalizedData.Routing }
                            default { $AzDeployment.DeploymentType }
                        }
                        $LocalizedData.Status = switch ($AzDeployment.DeploymentStatus) {
                            'Deployed' { $LocalizedData.Deployed }
                            'Deploying' { $LocalizedData.Deploying }
                            'NotStarted' { $LocalizedData.NotStarted }
                            'Failed' { $LocalizedData.Failed }
                            default { $AzDeployment.DeploymentStatus }
                        }
                        $LocalizedData.CommitTime = $(if ($AzDeployment.CommitTime) { $AzDeployment.CommitTime } else { $LocalizedData.None })
                        $LocalizedData.Configurations = $(if ($AzDeployment.ConfigurationIds) {
                            ($AzDeployment.ConfigurationIds | ForEach-Object { $_.split('/')[-1] } | Sort-Object) -join ', '
                        } else {
                            $LocalizedData.None
                        })
                    }
                }

                if ($Healthcheck.VirtualNetworkManager.DeploymentStatus) {
                    $AzDeploymentInfo | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Failed } | Set-Style -Style Critical -Property $LocalizedData.Status
                    $AzDeploymentInfo | Where-Object { $_.$($LocalizedData.Status) -in @($LocalizedData.Deploying, $LocalizedData.NotStarted) } | Set-Style -Style Warning -Property $LocalizedData.Status
                }

                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeadings) - $NetworkManagerName"
                        List = $false
                        ColumnWidths = 18, 17, 15, 20, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzDeploymentInfo | Sort-Object $LocalizedData.Region, $LocalizedData.DeploymentType | Table @TableParams

                    # The table has no room for error detail, so surface failure messages beneath it
                    foreach ($AzFailedDeployment in ($DeploymentStatus | Where-Object { $_.ErrorMessage })) {
                        Paragraph ($LocalizedData.DeploymentError -f $AzFailedDeployment.DeploymentType, $AzFailedDeployment.Region, $AzFailedDeployment.ErrorMessage)
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning ($LocalizedData.CollectionError -f $NetworkManagerName, $_.Exception.Message)
        }
    }

    end {}
}
