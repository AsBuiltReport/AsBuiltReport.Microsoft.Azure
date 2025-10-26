BeforeAll {
    # Import the module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
    Import-Module $ModulePath -Force
}

Describe 'AsBuiltReport.Microsoft.Azure Module Tests' {
    Context 'Module Manifest' {
        BeforeAll {
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
            $Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
        }

        It 'Should have a valid module manifest' {
            $Manifest | Should -Not -BeNullOrEmpty
        }

        It 'Should have the correct module name' {
            $Manifest.Name | Should -Be 'AsBuiltReport.Microsoft.Azure'
        }

        It 'Should have a valid GUID' {
            $Manifest.Guid | Should -Be '9be3285b-e0df-4744-96d7-903fac96f457'
        }

        It 'Should have a valid version' {
            $Manifest.Version | Should -Not -BeNullOrEmpty
            $Manifest.Version.GetType().Name | Should -Be 'Version'
        }

        It 'Should have a valid author' {
            $Manifest.Author | Should -Not -BeNullOrEmpty
        }

        It 'Should have a valid description' {
            $Manifest.Description | Should -Not -BeNullOrEmpty
        }

        It 'Should require AsBuiltReport.Core module' {
            $Manifest.RequiredModules | Should -Not -BeNullOrEmpty
            $Manifest.RequiredModules.Name | Should -Contain 'AsBuiltReport.Core'
        }

        It 'Should require AsBuiltReport.Core version 1.5.0 or higher' {
            $CoreModule = $Manifest.RequiredModules | Where-Object { $_.Name -eq 'AsBuiltReport.Core' }
            $CoreModule.Version | Should -BeGreaterOrEqual ([Version]'1.5.0')
        }

        It 'Should export the Invoke-AsBuiltReport.Microsoft.Azure function' {
            $Manifest.ExportedFunctions.Keys | Should -Contain 'Invoke-AsBuiltReport.Microsoft.Azure'
        }

        It 'Should have valid tags' {
            $Manifest.Tags | Should -Contain 'AsBuiltReport'
            $Manifest.Tags | Should -Contain 'Report'
            $Manifest.Tags | Should -Contain 'Microsoft'
            $Manifest.Tags | Should -Contain 'Azure'
        }

        It 'Should have a valid project URI' {
            $Manifest.ProjectUri | Should -Not -BeNullOrEmpty
            $Manifest.ProjectUri.ToString() | Should -Match '^https?://'
        }

        It 'Should have a valid license URI' {
            $Manifest.LicenseUri | Should -Not -BeNullOrEmpty
            $Manifest.LicenseUri.ToString() | Should -Match '^https?://'
        }

        It 'Should support PowerShell 5.1 and higher' {
            $Manifest.PowerShellVersion | Should -BeGreaterOrEqual ([Version]'5.1')
        }

        It 'Should support Desktop and Core editions' {
            $Manifest.CompatiblePSEditions | Should -Contain 'Desktop'
            $Manifest.CompatiblePSEditions | Should -Contain 'Core'
        }
    }

    Context 'Module Structure' {
        It 'Should have a valid root module file' {
            $RootModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psm1'
            Test-Path $RootModulePath | Should -Be $true
        }

        It 'Should have a Src folder' {
            $SrcPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Src'
            Test-Path $SrcPath | Should -Be $true
        }

        It 'Should have a Public functions folder' {
            $PublicPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Src\Public'
            Test-Path $PublicPath | Should -Be $true
        }

        It 'Should have a Private functions folder' {
            $PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Src\Private'
            Test-Path $PrivatePath | Should -Be $true
        }

        It 'Should have a Language folder' {
            $LanguagePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language'
            Test-Path $LanguagePath | Should -Be $true
        }

        It 'Should have en-US language files' {
            $EnUSPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language\en-US'
            Test-Path $EnUSPath | Should -Be $true
        }

        It 'Should have a JSON configuration file' {
            $JsonConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.json'
            Test-Path $JsonConfigPath | Should -Be $true
        }

        It 'Should have at least one private function' {
            $PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Src\Private'
            $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -ErrorAction SilentlyContinue
            $PrivateFunctions.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Public Functions' {
        It 'Should export Invoke-AsBuiltReport.Microsoft.Azure function' {
            Get-Command -Name 'Invoke-AsBuiltReport.Microsoft.Azure' -Module 'AsBuiltReport.Microsoft.Azure' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have exactly 1 exported function' {
            $ExportedFunctions = Get-Command -Module 'AsBuiltReport.Microsoft.Azure' -CommandType Function
            # Filter to only count the officially exported public functions
            $PublicFunctions = $ExportedFunctions | Where-Object {
                $_.Name -in @('Invoke-AsBuiltReport.Microsoft.Azure')
            }
            $PublicFunctions.Count | Should -Be 1
        }
    }

    Context 'Function Parameter Validation' {
        BeforeAll {
            $InvokeCommand = Get-Command -Name 'Invoke-AsBuiltReport.Microsoft.Azure'
        }

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have Target parameter' {
            $InvokeCommand.Parameters.Keys | Should -Contain 'Target'
        }

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have Credential parameter' {
            $InvokeCommand.Parameters.Keys | Should -Contain 'Credential'
        }

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have UseInteractiveAuth parameter' {
            $InvokeCommand.Parameters.Keys | Should -Contain 'UseInteractiveAuth'
        }

        It 'Target parameter should accept string array' {
            $TargetParam = $InvokeCommand.Parameters['Target']
            $TargetParam.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Credential parameter should accept PSCredential' {
            $CredentialParam = $InvokeCommand.Parameters['Credential']
            $CredentialParam.ParameterType.Name | Should -Be 'PSCredential'
        }

        It 'UseInteractiveAuth parameter should be a switch' {
            $UseInteractiveAuthParam = $InvokeCommand.Parameters['UseInteractiveAuth']
            $UseInteractiveAuthParam.SwitchParameter | Should -Be $true
        }
    }

    Context 'Help Content' {
        It 'Invoke-AsBuiltReport.Microsoft.Azure should have help content' {
            $Help = Get-Help -Name 'Invoke-AsBuiltReport.Microsoft.Azure' -ErrorAction SilentlyContinue
            $Help | Should -Not -BeNullOrEmpty
            $Help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have description' {
            $Help = Get-Help -Name 'Invoke-AsBuiltReport.Microsoft.Azure' -ErrorAction SilentlyContinue
            $Help.Description | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have a link' {
            $Help = Get-Help -Name 'Invoke-AsBuiltReport.Microsoft.Azure' -ErrorAction SilentlyContinue
            $Help.relatedLinks | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Private Functions' {
        BeforeAll {
            $PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Src\Private'
            $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -ErrorAction SilentlyContinue
        }

        It 'Should have Get-AbrAzStorageAccount function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzStorageAccount.ps1'
        }

        It 'Should have Get-AbrAzVirtualMachine function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzVirtualMachine.ps1'
        }

        It 'Should have Get-AbrAzVirtualNetwork function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzVirtualNetwork.ps1'
        }

        It 'Should have Get-AbrAzKeyVault function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzKeyVault.ps1'
        }

        It 'Should have Get-AbrAzLoadBalancer function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLoadBalancer.ps1'
        }

        It 'Should have Get-AbrAzLogAnalyticsWorkspace function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLogAnalyticsWorkspace.ps1'
        }

        It 'All private functions should follow naming convention Get-AbrAz*' {
            $InvalidNames = $PrivateFunctions | Where-Object {
                $_.BaseName -notmatch '^Get-Abr' -and $_.BaseName -notmatch '^Get-CountryName' -and $_.BaseName -notmatch '^Get-RequiredModule'
            }
            $InvalidNames | Should -BeNullOrEmpty
        }
    }

    Context 'JSON Configuration' {
        BeforeAll {
            $JsonConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.json'
            $JsonConfig = Get-Content -Path $JsonConfigPath -Raw | ConvertFrom-Json
        }

        It 'Should have a valid JSON configuration file' {
            $JsonConfig | Should -Not -BeNullOrEmpty
        }

        It 'Should have a Report section' {
            $JsonConfig.Report | Should -Not -BeNullOrEmpty
        }

        It 'Should have an Options section' {
            $JsonConfig.Options | Should -Not -BeNullOrEmpty
        }

        It 'Should have a Filter section' {
            $JsonConfig.Filter | Should -Not -BeNullOrEmpty
        }

        It 'Should have an InfoLevel section' {
            $JsonConfig.InfoLevel | Should -Not -BeNullOrEmpty
        }

        It 'Should have a HealthCheck section' {
            $JsonConfig.HealthCheck | Should -Not -BeNullOrEmpty
        }

        It 'InfoLevel should include StorageAccount' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'StorageAccount'
        }

        It 'InfoLevel should include VirtualMachine' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'VirtualMachine'
        }

        It 'InfoLevel should include LogAnalyticsWorkspace' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'LogAnalyticsWorkspace'
        }

        It 'HealthCheck should include Bastion checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'Bastion'
        }

        It 'HealthCheck should include DnsPrivateResolver checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'DnsPrivateResolver'
        }

        It 'HealthCheck should include ExpressRoute checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'ExpressRoute'
        }

        It 'HealthCheck should include Firewall checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'Firewall'
        }

        It 'HealthCheck should include FirewallPolicy checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'FirewallPolicy'
        }

        It 'HealthCheck should include IpGroup checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'IpGroup'
        }

        It 'HealthCheck should include KeyVault checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'KeyVault'
        }

        It 'HealthCheck should include LoadBalancer checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'LoadBalancer'
        }

        It 'HealthCheck should include LogAnalyticsWorkspace checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'LogAnalyticsWorkspace'
        }

        It 'HealthCheck should include NetworkSecurityGroup checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'NetworkSecurityGroup'
        }

        It 'HealthCheck should include PrivateEndpoint checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'PrivateEndpoint'
        }

        It 'HealthCheck should include RecoveryServicesVault checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'RecoveryServicesVault'
        }

        It 'HealthCheck should include RouteTable checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'RouteTable'
        }

        It 'HealthCheck should include StorageAccount checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'StorageAccount'
        }

        It 'HealthCheck should include VirtualMachine checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'VirtualMachine'
        }

        It 'HealthCheck should include VirtualNetwork checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'VirtualNetwork'
        }
    }
}

Describe 'Module File Syntax and Quality' {
    Context 'PowerShell Script Files' {
        It 'Should have valid PowerShell syntax in all script files' {
            $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
            $ScriptFiles = Get-ChildItem -Path $ModuleRoot -Include '*.ps1', '*.psm1' -Recurse

            foreach ($File in $ScriptFiles) {
                $FileContent = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
                $Errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($FileContent, [ref]$Errors)
                $Errors.Count | Should -Be 0 -Because "File $($File.Name) should have no syntax errors"
            }
        }
    }

    Context 'Language Files' {
        BeforeAll {
            $LanguagePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language\en-US'
            $LocalizedData = Import-LocalizedData -BaseDirectory $LanguagePath -FileName 'MicrosoftAzure.psd1'
            $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
            $PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\Src\Private" -Filter '*.ps1' -ErrorAction SilentlyContinue
        }

        It 'Should have valid PowerShell localization data files' {
            $LanguagePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language'
            $LanguageFiles = Get-ChildItem -Path $LanguagePath -Include '*.psd1' -Recurse -ErrorAction SilentlyContinue

            foreach ($File in $LanguageFiles) {
                # All .psd1 files in Language folder use ConvertFrom-StringData and should be loaded with Import-LocalizedData
                {
                    $null = Import-LocalizedData -BaseDirectory $File.Directory.FullName -FileName $File.Name -ErrorAction Stop
                } | Should -Not -Throw -Because "Localization file $($File.FullName) should be valid"
            }
        }

        # Test that every Get-AbrAz* private function has a corresponding localization section
        It 'All Get-AbrAz* functions should have localization sections' {
            $AzFunctions = $PrivateFunctions | Where-Object { $_.BaseName -match '^Get-AbrAz' }

            foreach ($Function in $AzFunctions) {
                # Convert Get-AbrAzStorageAccount to GetAbrAzStorageAccount
                $LocalizationKey = $Function.BaseName -replace '^Get-', 'Get'
                $LocalizationKey = $LocalizationKey -replace '-', ''

                $LocalizedData.$LocalizationKey | Should -Not -BeNullOrEmpty -Because "Function $($Function.BaseName) should have localization section '$LocalizationKey'"
            }
        }

        # Test that all $LocalizedData.* references in private functions have corresponding localization strings
        It 'All $LocalizedData property references should exist in localization file' {
            $AzFunctions = $PrivateFunctions | Where-Object { $_.BaseName -match '^Get-AbrAz' }
            $MissingProperties = @()

            foreach ($Function in $AzFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw

                # Convert Get-AbrAzStorageAccount to GetAbrAzStorageAccount
                $LocalizationKey = $Function.BaseName -replace '^Get-', 'Get'
                $LocalizationKey = $LocalizationKey -replace '-', ''

                # Find all $LocalizedData.PropertyName references
                # Pattern matches: $LocalizedData.PropertyName or $LocalizedData.'PropertyName' or $LocalizedData."PropertyName"
                $Pattern = '\$LocalizedData\.([''"])?(\w+)\1'
                $Matches = [regex]::Matches($Content, $Pattern)

                if ($Matches.Count -gt 0) {
                    $LocalizationSection = $LocalizedData.$LocalizationKey

                    foreach ($Match in $Matches) {
                        $PropertyName = $Match.Groups[2].Value

                        # Skip if it's a method call or special case
                        if ($PropertyName -notmatch '^(GetEnumerator|Count|Keys|Values)$') {
                            if ([string]::IsNullOrEmpty($LocalizationSection.$PropertyName)) {
                                $MissingProperties += "Function '$($Function.BaseName)' references `$LocalizedData.$PropertyName which should exist in localization section '$LocalizationKey'"
                            }
                        }
                    }
                }
            }

            # Assert all missing properties at once
            if ($MissingProperties.Count -gt 0) {
                $ErrorMessage = "Found $($MissingProperties.Count) missing localization property reference(s):`n" + ($MissingProperties -join "`n")
                $MissingProperties.Count | Should -Be 0 -Because $ErrorMessage
            }
        }

        # Test that all hashtable keys using $LocalizedData.* are defined
        It 'All hashtable keys using $LocalizedData should be defined' {
            $AzFunctions = $PrivateFunctions | Where-Object { $_.BaseName -match '^Get-AbrAz' }
            $MissingHashtableKeys = @()

            foreach ($Function in $AzFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw

                # Convert Get-AbrAzStorageAccount to GetAbrAzStorageAccount
                $LocalizationKey = $Function.BaseName -replace '^Get-', 'Get'
                $LocalizationKey = $LocalizationKey -replace '-', ''

                # Find all hashtable key patterns: $LocalizedData.Key = value
                # This catches cases like: $InObj[$LocalizedData.Name] = $Value
                $Pattern = '\$LocalizedData\.(\w+)\s*[=\]]'
                $Matches = [regex]::Matches($Content, $Pattern)

                if ($Matches.Count -gt 0) {
                    $LocalizationSection = $LocalizedData.$LocalizationKey

                    foreach ($Match in $Matches) {
                        $PropertyName = $Match.Groups[1].Value

                        # Skip method calls and special cases
                        if ($PropertyName -notmatch '^(GetEnumerator|Count|Keys|Values)$') {
                            if ([string]::IsNullOrEmpty($LocalizationSection.$PropertyName)) {
                                $MissingHashtableKeys += "Function '$($Function.BaseName)' uses `$LocalizedData.$PropertyName as a key which should exist in localization section '$LocalizationKey'"
                            }
                        }
                    }
                }
            }

            # Assert all missing hashtable keys at once
            if ($MissingHashtableKeys.Count -gt 0) {
                $ErrorMessage = "Found $($MissingHashtableKeys.Count) missing hashtable key localization(s):`n" + ($MissingHashtableKeys -join "`n")
                $MissingHashtableKeys.Count | Should -Be 0 -Because $ErrorMessage
            }
        }

        # Test InvokeAsBuiltReportMicrosoftAzure localization section
        It 'Should have InvokeAsBuiltReportMicrosoftAzure localization section' {
            $LocalizedData.InvokeAsBuiltReportMicrosoftAzure | Should -Not -BeNullOrEmpty
        }

        # Test GetCountryName localization section
        It 'Should have GetCountryName localization section' {
            $LocalizedData.GetCountryName | Should -Not -BeNullOrEmpty
        }

        # Test for specific critical localization strings that are commonly used
        It 'Common localization strings should exist in main Get-AbrAz* sections' {
            $AzFunctions = $PrivateFunctions | Where-Object { $_.BaseName -match '^Get-AbrAz' }
            $CommonKeys = @('InfoLevel', 'Collecting', 'Heading', 'Name', 'ResourceGroup', 'Location')

            # Helper functions are called from main functions and don't have InfoLevel support
            # They typically have patterns like Get-AbrAzLb*, Get-AbrAzSA*, Get-AbrAzFirewallNatRule, etc.
            $HelperFunctionPatterns = @(
                'Get-AbrAzLb',              # Load Balancer sub-functions
                'Get-AbrAzSA',              # Storage Account sub-functions
                'Get-AbrAzFirewallNatRule', # Firewall NAT rules
                'Get-AbrAzFirewallNetworkRule', # Firewall Network rules
                'Get-AbrAzNetworkSecurityGroupRule', # NSG rules
                'Get-AbrAzVirtualNetworkPeering',    # VNet peering
                'Get-AbrAzVirtualNetworkSubnet',     # VNet subnet
                'Get-AbrAsrProtectedItems',          # Site Recovery items
                'Get-AbrAzPolicy'                    # Policy sub-functions
            )

            # Collect all missing keys instead of failing on first one
            $MissingKeys = @()

            foreach ($Function in $AzFunctions) {
                # Check if this is a helper function
                $IsHelperFunction = $false
                foreach ($Pattern in $HelperFunctionPatterns) {
                    if ($Function.BaseName -match "^$Pattern") {
                        $IsHelperFunction = $true
                        break
                    }
                }

                # Skip helper functions - they don't have InfoLevel, ResourceGroup, Location
                if ($IsHelperFunction) {
                    continue
                }

                $LocalizationKey = $Function.BaseName -replace '^Get-', 'Get'
                $LocalizationKey = $LocalizationKey -replace '-', ''

                $LocalizationSection = $LocalizedData.$LocalizationKey

                if ($LocalizationSection) {
                    foreach ($Key in $CommonKeys) {
                        if ([string]::IsNullOrEmpty($LocalizationSection.$Key)) {
                            $MissingKeys += "Function '$($Function.BaseName)' missing key '$Key' in localization section '$LocalizationKey'"
                        }
                    }
                }
            }

            # Assert all missing keys at once with detailed error message
            if ($MissingKeys.Count -gt 0) {
                $ErrorMessage = "Found $($MissingKeys.Count) missing localization string(s):`n" + ($MissingKeys -join "`n")
                $MissingKeys.Count | Should -Be 0 -Because $ErrorMessage
            }
        }
    }

    Context 'Code Style and Standards' {
        BeforeAll {
            $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\Src\Public" -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
            $PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\Src\Private" -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
        }

        It 'All public functions should have comment-based help' {
            foreach ($Function in $PublicFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\.SYNOPSIS'
                $Content | Should -Match '\.DESCRIPTION'
            }
        }

        It 'All public functions should have CmdletBinding attribute' {
            foreach ($Function in $PublicFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\[CmdletBinding\(\)\]'
            }
        }

        It 'All private functions should have CmdletBinding attribute' {
            foreach ($Function in $PrivateFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\[CmdletBinding\(\)\]'
            }
        }

        It 'All private Get-AbrAz* functions should use try/catch blocks' {
            $AzFunctions = $PrivateFunctions | Where-Object { $_.BaseName -match '^Get-AbrAz' }
            foreach ($Function in $AzFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\btry\s*\{' -Because "$($Function.Name) should use try/catch for error handling"
                $Content | Should -Match '\}\s*catch\s*\{' -Because "$($Function.Name) should use try/catch for error handling"
            }
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module -Name 'AsBuiltReport.Microsoft.Azure' -Force -ErrorAction SilentlyContinue
}
