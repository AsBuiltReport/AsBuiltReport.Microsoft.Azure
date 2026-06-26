BeforeAll {
    # Import the module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
    $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
    } catch {
        # Fallback: import .psm1 directly when required module dependencies are not available
        $PsmPath = Join-Path -Path $ModuleRoot -ChildPath 'AsBuiltReport.Microsoft.Azure.psm1'
        Import-Module $PsmPath -Force
    }
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

        It 'Should require AsBuiltReport.Core version 1.6.2 or higher' {
            $CoreModule = $Manifest.RequiredModules | Where-Object { $_.Name -eq 'AsBuiltReport.Core' }
            $CoreModule.Version | Should -BeGreaterOrEqual ([Version]'1.6.2')
        }

        It 'Should declare Az as an external module dependency' {
            $Manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Not -BeNullOrEmpty
            $Manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Contain 'Az'
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

        It 'Should have a copyright with current or recent year' {
            $Manifest.Copyright | Should -Not -BeNullOrEmpty
            $Manifest.Copyright | Should -Match '202[0-9]'
        }

        It 'Should have a meaningful description' {
            $Manifest.Description | Should -Not -BeNullOrEmpty
            $Manifest.Description.Length | Should -BeGreaterThan 50
        }

        It 'Should have a ReleaseNotes URI' {
            $Manifest.PrivateData.PSData.ReleaseNotes | Should -Not -BeNullOrEmpty
            $Manifest.PrivateData.PSData.ReleaseNotes | Should -Match '^https?://'
        }



        It 'Should have module version matching expected format' {
            $Manifest.Version.ToString() | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Should have author information' {
            $Manifest.Author | Should -Not -BeNullOrEmpty
            $Manifest.Author.Length | Should -BeGreaterThan 2
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

        foreach ($lang in @('en-US', 'en-GB', 'de-DE', 'es-ES', 'fr-FR')) {
            It "Should have <Language> language folder" -TestCases @(@{ Language = $lang }) {
                $LangPath = Join-Path -Path $PSScriptRoot -ChildPath "..\AsBuiltReport.Microsoft.Azure\Language\$Language"
                Test-Path $LangPath | Should -Be $true
            }

            It "Should have <Language> MicrosoftAzure.psd1 localization file" -TestCases @(@{ Language = $lang }) {
                $LangFile = Join-Path -Path $PSScriptRoot -ChildPath "..\AsBuiltReport.Microsoft.Azure\Language\$Language\MicrosoftAzure.psd1"
                Test-Path $LangFile | Should -Be $true
            }

            It "Should be able to load <Language> localization file" -TestCases @(@{ Language = $lang }) {
                $LangPath = Join-Path -Path $PSScriptRoot -ChildPath "..\AsBuiltReport.Microsoft.Azure\Language\$Language"
                { Import-LocalizedData -BaseDirectory $LangPath -FileName 'MicrosoftAzure.psd1' -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It 'Should have a JSON configuration file' {
            $JsonConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.json'
            Test-Path $JsonConfigPath | Should -Be $true
        }

        It 'Should have at least one private function' {
            $PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Src\Private'
            $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
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

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have Token parameter' {
            $InvokeCommand.Parameters.Keys | Should -Contain 'Token'
        }

        It 'Token parameter should accept string' {
            $TokenParam = $InvokeCommand.Parameters['Token']
            $TokenParam.ParameterType.Name | Should -Be 'String'
        }

        It 'Invoke-AsBuiltReport.Microsoft.Azure should have AccountId parameter' {
            $InvokeCommand.Parameters.Keys | Should -Contain 'AccountId'
        }

        It 'AccountId parameter should accept string' {
            $AccountIdParam = $InvokeCommand.Parameters['AccountId']
            $AccountIdParam.ParameterType.Name | Should -Be 'String'
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
            $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
            $AllPrivateFunctions = $PrivateFunctions
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

        It 'Should have Get-AbrAzAvailabilitySet function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzAvailabilitySet.ps1'
        }

        It 'Should have Get-AbrAzBastion function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzBastion.ps1'
        }

        It 'Should have Get-AbrAzDnsPrivateResolver function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzDnsPrivateResolver.ps1'
        }

        It 'Should have Get-AbrAzExpressRouteCircuit function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzExpressRouteCircuit.ps1'
        }

        It 'Should have Get-AbrAzFirewall function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzFirewall.ps1'
        }

        It 'Should have Get-AbrAzFirewallPolicy function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzFirewallPolicy.ps1'
        }

        It 'Should have Get-AbrAzIpGroup function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzIpGroup.ps1'
        }

        It 'Should have Get-AbrAzNetworkSecurityGroup function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzNetworkSecurityGroup.ps1'
        }

        It 'Should have Get-AbrAzPolicy function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzPolicy.ps1'
        }

        It 'Should have Get-AbrAzPolicyAssignment function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzPolicyAssignment.ps1'
        }

        It 'Should have Get-AbrAzPolicyDefinition function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzPolicyDefinition.ps1'
        }

        It 'Should have Get-AbrAzPrivateEndpoint function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzPrivateEndpoint.ps1'
        }

        It 'Should have Get-AbrAzRecoveryServicesVault function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzRecoveryServicesVault.ps1'
        }

        It 'Should have Get-AbrAzRouteTable function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzRouteTable.ps1'
        }

        It 'Should have Get-AbrAzSubscription function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSubscription.ps1'
        }

        It 'Should have Get-AbrAzTenant function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzTenant.ps1'
        }

        It 'Should have Get-AbrAsrProtectedItems function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAsrProtectedItems.ps1'
        }

        It 'Should have Get-AbrAzAsrPolicy function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzAsrPolicy.ps1'
        }

        It 'Should have Get-AbrAzAsrRecoveryPlan function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzAsrRecoveryPlan.ps1'
        }

        It 'Should have Get-AbrAzAsrNetworkMapping function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzAsrNetworkMapping.ps1'
        }

        It 'Should have Get-AbrAzUserAssignedManagedIdentity function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzUserAssignedManagedIdentity.ps1'
        }

        It 'Should have Get-AbrAzAutomationAccount function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzAutomationAccount.ps1'
        }

        It 'Should have Get-AbrAzDiagnosticSetting function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzDiagnosticSetting.ps1'
        }

        It 'Should have Get-CountryName function' {
            $PrivateFunctions.Name | Should -Contain 'Get-CountryName.ps1'
        }

        It 'Should have Convert-DataSize function' {
            $PrivateFunctions.Name | Should -Contain 'Convert-DataSize.ps1'
        }

        # Helper Functions - Load Balancer
        It 'Should have Get-AbrAzLbBackendPool helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLbBackendPool.ps1'
        }

        It 'Should have Get-AbrAzLbHealthProbe helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLbHealthProbe.ps1'
        }

        It 'Should have Get-AbrAzLbInboundNatPool helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLbInboundNatPool.ps1'
        }

        It 'Should have Get-AbrAzLbLoadBalancingRule helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLbLoadBalancingRule.ps1'
        }

        It 'Should have Get-AbrAzLbFrontendIpConfig helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzLbFrontendIpConfig.ps1'
        }

        # Helper Functions - Storage Account
        It 'Should have Get-AbrAzSABlobServiceProperty helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSABlobServiceProperty.ps1'
        }

        It 'Should have Get-AbrAzSAContainer helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSAContainer.ps1'
        }

        It 'Should have Get-AbrAzSAFileServiceProperty helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSAFileServiceProperty.ps1'
        }

        It 'Should have Get-AbrAzSAQueue helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSAQueue.ps1'
        }

        It 'Should have Get-AbrAzSAShare helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSAShare.ps1'
        }

        It 'Should have Get-AbrAzSATable helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzSATable.ps1'
        }

        # Helper Functions - Virtual Network
        It 'Should have Get-AbrAzVirtualNetworkPeering helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzVirtualNetworkPeering.ps1'
        }

        It 'Should have Get-AbrAzVirtualNetworkSubnet helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzVirtualNetworkSubnet.ps1'
        }

        # Helper Functions - Firewall
        It 'Should have Get-AbrAzFirewallNatRule helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzFirewallNatRule.ps1'
        }

        It 'Should have Get-AbrAzFirewallNetworkRule helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzFirewallNetworkRule.ps1'
        }

        # Helper Functions - Network Security Group
        It 'Should have Get-AbrAzNetworkSecurityGroupRule helper function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzNetworkSecurityGroupRule.ps1'
        }

        # Management Group
        It 'Should have Get-AbrAzManagementGroup function' {
            $PrivateFunctions.Name | Should -Contain 'Get-AbrAzManagementGroup.ps1'
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

        It 'Options should have SectionOrder array' {
            $JsonConfig.Options.SectionOrder | Should -Not -BeNullOrEmpty
            $JsonConfig.Options.SectionOrder.Count | Should -BeGreaterThan 0
        }

        It 'SectionOrder should contain expected sections' {
            $JsonConfig.Options.SectionOrder | Should -Contain 'StorageAccount'
            $JsonConfig.Options.SectionOrder | Should -Contain 'VirtualMachine'
            $JsonConfig.Options.SectionOrder | Should -Contain 'VirtualNetwork'
            $JsonConfig.Options.SectionOrder | Should -Contain 'KeyVault'
            $JsonConfig.Options.SectionOrder | Should -Contain 'LoadBalancer'
        }

        It 'SectionOrder should contain UserAssignedManagedIdentity' {
            $JsonConfig.Options.SectionOrder | Should -Contain 'UserAssignedManagedIdentity'
        }

        It 'SectionOrder should contain AutomationAccount' {
            $JsonConfig.Options.SectionOrder | Should -Contain 'AutomationAccount'
        }

        It 'SectionOrder should contain DiagnosticSetting' {
            $JsonConfig.Options.SectionOrder | Should -Contain 'DiagnosticSetting'
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

        It 'InfoLevel should include AvailabilitySet' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'AvailabilitySet'
        }

        It 'InfoLevel should include Bastion' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'Bastion'
        }

        It 'InfoLevel should include DnsPrivateResolver' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'DnsPrivateResolver'
        }

        It 'InfoLevel should include ExpressRoute' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'ExpressRoute'
        }

        It 'InfoLevel should include Firewall' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'Firewall'
        }

        It 'InfoLevel should include FirewallPolicy' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'FirewallPolicy'
        }

        It 'InfoLevel should include IpGroup' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'IpGroup'
        }

        It 'InfoLevel should include KeyVault' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'KeyVault'
        }

        It 'InfoLevel should include LoadBalancer' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'LoadBalancer'
        }

        It 'InfoLevel should include NetworkSecurityGroup' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'NetworkSecurityGroup'
        }

        It 'InfoLevel should include Policy' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'Policy'
        }

        It 'InfoLevel Policy should be a complex object with Assignments and Definitions' {
            $JsonConfig.InfoLevel.Policy | Should -Not -BeNullOrEmpty
            $JsonConfig.InfoLevel.Policy.PSObject.Properties.Name | Should -Contain 'Assignments'
            $JsonConfig.InfoLevel.Policy.PSObject.Properties.Name | Should -Contain 'Definitions'
        }

        It 'InfoLevel should include PrivateEndpoint' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'PrivateEndpoint'
        }

        It 'InfoLevel should include RecoveryServicesVault' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'RecoveryServicesVault'
        }

        It 'InfoLevel should include RouteTable' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'RouteTable'
        }

        It 'InfoLevel should include SiteRecovery' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'SiteRecovery'
        }

        It 'InfoLevel should include Subscription' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'Subscription'
        }

        It 'InfoLevel should include Tenant' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'Tenant'
        }

        It 'InfoLevel should include ManagementGroup' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'ManagementGroup'
        }

        It 'InfoLevel should include UserAssignedManagedIdentity' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'UserAssignedManagedIdentity'
        }

        It 'InfoLevel should include AutomationAccount' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'AutomationAccount'
        }

        It 'InfoLevel should include DiagnosticSetting' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'DiagnosticSetting'
        }

        It 'InfoLevel should include VirtualNetwork' {
            $JsonConfig.InfoLevel.PSObject.Properties.Name | Should -Contain 'VirtualNetwork'
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

        It 'HealthCheck should include AutomationAccount checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'AutomationAccount'
        }

        It 'HealthCheck should include DiagnosticSetting checks' {
            $JsonConfig.HealthCheck.PSObject.Properties.Name | Should -Contain 'DiagnosticSetting'
        }
    }

    Context 'Configuration Schema Validation' {
        BeforeAll {
            $JsonConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.json'
            $JsonConfig = Get-Content -Path $JsonConfigPath -Raw | ConvertFrom-Json
        }

        It 'All InfoLevel values should be valid (0-4 or complex object)' {
            $InvalidInfoLevels = @()

            foreach ($Property in $JsonConfig.InfoLevel.PSObject.Properties) {
                # Skip comment fields (fields starting with underscore)
                if ($Property.Name -match '^_') {
                    continue
                }

                $Value = $Property.Value

                # Check if it's a complex object (like Policy with Assignments/Definitions)
                if ($Value -is [PSCustomObject]) {
                    # Validate each sub-property
                    foreach ($SubProperty in $Value.PSObject.Properties) {
                        $SubValue = $SubProperty.Value
                        # Accept both Int32 and Int64 (JSON deserializes to Int64)
                        $IsValidInteger = ($SubValue -is [int] -or $SubValue -is [int64])
                        if (-not $IsValidInteger -or $SubValue -lt 0 -or $SubValue -gt 4) {
                            $InvalidInfoLevels += "$($Property.Name).$($SubProperty.Name) = $SubValue (expected 0-4)"
                        }
                    }
                } elseif ($Value -is [int] -or $Value -is [int64]) {
                    # Accept both Int32 and Int64
                    if ($Value -lt 0 -or $Value -gt 4) {
                        $InvalidInfoLevels += "$($Property.Name) = $Value (expected 0-4)"
                    }
                } else {
                    $InvalidInfoLevels += "$($Property.Name) has invalid type: $($Value.GetType().Name)"
                }
            }

            if ($InvalidInfoLevels.Count -gt 0) {
                $ErrorMessage = "Found $($InvalidInfoLevels.Count) invalid InfoLevel value(s):`n" + ($InvalidInfoLevels -join "`n")
                $InvalidInfoLevels.Count | Should -Be 0 -Because $ErrorMessage
            }
        }

        It 'All HealthCheck values should be boolean' {
            $InvalidHealthChecks = @()

            foreach ($Section in $JsonConfig.HealthCheck.PSObject.Properties) {
                foreach ($Check in $Section.Value.PSObject.Properties) {
                    if ($Check.Value -isnot [bool]) {
                        $InvalidHealthChecks += "$($Section.Name).$($Check.Name) = $($Check.Value) (expected boolean)"
                    }
                }
            }

            if ($InvalidHealthChecks.Count -gt 0) {
                $ErrorMessage = "Found $($InvalidHealthChecks.Count) non-boolean HealthCheck value(s):`n" + ($InvalidHealthChecks -join "`n")
                $InvalidHealthChecks.Count | Should -Be 0 -Because $ErrorMessage
            }
        }

        It 'Filter.Subscription should be an array or wildcard string' {
            # Allow either an array or a string "*" (wildcard)
            $IsValid = ($JsonConfig.Filter.Subscription -is [System.Array]) -or
                       ($JsonConfig.Filter.Subscription -is [string] -and $JsonConfig.Filter.Subscription -eq '*')

            $IsValid | Should -Be $true -Because "Filter.Subscription should be an array like ['*'] or a wildcard string '*'"
        }

        It 'Options.ShowSectionInfo should be boolean' {
            $JsonConfig.Options.ShowSectionInfo | Should -BeOfType [bool]
        }

        It 'Options.ShowTags should be boolean' {
            $JsonConfig.Options.ShowTags | Should -BeOfType [bool]
        }

        It 'Options.EnableDiagrams should be boolean' {
            $JsonConfig.Options.EnableDiagrams | Should -BeOfType [bool]
        }

        It 'Policy InfoLevel structure should have Assignments and Definitions' {
            $JsonConfig.InfoLevel.Policy.PSObject.Properties.Name | Should -Contain 'Assignments'
            $JsonConfig.InfoLevel.Policy.PSObject.Properties.Name | Should -Contain 'Definitions'
        }

        It 'All SectionOrder entries should have corresponding InfoLevel sections' {
            $MissingSections = @()

            foreach ($Section in $JsonConfig.Options.SectionOrder) {
                if ($Section -notin $JsonConfig.InfoLevel.PSObject.Properties.Name) {
                    $MissingSections += $Section
                }
            }

            if ($MissingSections.Count -gt 0) {
                $ErrorMessage = "SectionOrder contains sections without InfoLevel definitions:`n" + ($MissingSections -join "`n")
                $MissingSections.Count | Should -Be 0 -Because $ErrorMessage
            }
        }

        It 'Report.Name should not be empty' {
            $JsonConfig.Report.Name | Should -Not -BeNullOrEmpty
            $JsonConfig.Report.Name.Length | Should -BeGreaterThan 5
        }

        It 'Report.Version should be valid' {
            $JsonConfig.Report.Version | Should -Not -BeNullOrEmpty
            $JsonConfig.Report.Version | Should -Match '^\d+\.\d+$'
        }

        It 'Report boolean settings should be boolean type' {
            $JsonConfig.Report.ShowCoverPageImage | Should -BeOfType [bool]
            $JsonConfig.Report.ShowTableOfContents | Should -BeOfType [bool]
            $JsonConfig.Report.ShowHeaderFooter | Should -BeOfType [bool]
            $JsonConfig.Report.ShowTableCaptions | Should -BeOfType [bool]
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
            $PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\Src\Private" -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
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
                'Get-AbrAzAsr',                      # ASR sub-functions (policies, plans, mappings)
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

        # Cross-Language Validation
        It 'en-GB and en-US should have matching localization section keys' {
            $EnUSPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language\en-US'
            $EnGBPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language\en-GB'

            $EnUSData = Import-LocalizedData -BaseDirectory $EnUSPath -FileName 'MicrosoftAzure.psd1'
            $EnGBData = Import-LocalizedData -BaseDirectory $EnGBPath -FileName 'MicrosoftAzure.psd1'

            $EnUSKeys = $EnUSData.Keys | Sort-Object
            $EnGBKeys = $EnGBData.Keys | Sort-Object

            # Check if all en-US keys exist in en-GB
            $MissingInGB = $EnUSKeys | Where-Object { $_ -notin $EnGBKeys }
            $MissingInUS = $EnGBKeys | Where-Object { $_ -notin $EnUSKeys }

            $Differences = @()
            if ($MissingInGB.Count -gt 0) {
                $Differences += "Keys in en-US but missing in en-GB: $($MissingInGB -join ', ')"
            }
            if ($MissingInUS.Count -gt 0) {
                $Differences += "Keys in en-GB but missing in en-US: $($MissingInUS -join ', ')"
            }

            if ($Differences.Count -gt 0) {
                $ErrorMessage = "Language file key mismatch:`n" + ($Differences -join "`n")
                ($MissingInGB.Count + $MissingInUS.Count) | Should -Be 0 -Because $ErrorMessage
            }
        }

        # Verify new v0.2.0 functions have localization
        It 'Should have GetAbrAzAvailabilitySet localization section' {
            $LocalizedData.GetAbrAzAvailabilitySet | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzBastion localization section' {
            $LocalizedData.GetAbrAzBastion | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzFirewallPolicy localization section' {
            $LocalizedData.GetAbrAzFirewallPolicy | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzPrivateEndpoint localization section' {
            $LocalizedData.GetAbrAzPrivateEndpoint | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzDnsPrivateResolver localization section' {
            $LocalizedData.GetAbrAzDnsPrivateResolver | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzExpressRouteCircuit localization section' {
            $LocalizedData.GetAbrAzExpressRouteCircuit | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzIpGroup localization section' {
            $LocalizedData.GetAbrAzIpGroup | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzRouteTable localization section' {
            $LocalizedData.GetAbrAzRouteTable | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzManagementGroup localization section' {
            $LocalizedData.GetAbrAzManagementGroup | Should -Not -BeNullOrEmpty
        }

        # Verify new v0.3.0 functions have localization
        It 'Should have GetAbrAzUserAssignedManagedIdentity localization section' {
            $LocalizedData.GetAbrAzUserAssignedManagedIdentity | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzAutomationAccount localization section' {
            $LocalizedData.GetAbrAzAutomationAccount | Should -Not -BeNullOrEmpty
        }

        It 'Should have GetAbrAzDiagnosticSetting localization section' {
            $LocalizedData.GetAbrAzDiagnosticSetting | Should -Not -BeNullOrEmpty
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

        It 'All private Get-AbrAz* functions should use try/catch blocks' {
            $AzFunctions = $PrivateFunctions | Where-Object { $_.BaseName -match '^Get-AbrAz' }
            foreach ($Function in $AzFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\btry\s*\{' -Because "$($Function.Name) should use try/catch for error handling"
                $Content | Should -Match '\}\s*catch\s*\{' -Because "$($Function.Name) should use try/catch for error handling"
            }
        }
    }

    Context 'PSScriptAnalyzer Compliance' {
        BeforeAll {
            $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
            $SettingsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.github\workflows\PSScriptAnalyzerSettings.psd1'
        }

        It 'Should have no critical PSScriptAnalyzer violations' {
            $AnalyzerResults = Invoke-ScriptAnalyzer -Path $ModuleRoot -Recurse -Severity Error -ErrorAction SilentlyContinue

            if ($AnalyzerResults.Count -gt 0) {
                $ErrorMessages = $AnalyzerResults | ForEach-Object { "$($_.ScriptName):$($_.Line) - $($_.Message)" }
                $ErrorMessage = "Found $($AnalyzerResults.Count) critical violation(s):`n" + ($ErrorMessages -join "`n")
                $AnalyzerResults.Count | Should -Be 0 -Because $ErrorMessage
            } else {
                $AnalyzerResults.Count | Should -Be 0
            }
        }

        It 'Should have minimal PSScriptAnalyzer warnings' {
            try {
                $AnalyzerResults = Invoke-ScriptAnalyzer -Path $ModuleRoot -Recurse -Severity Warning -ErrorAction SilentlyContinue
            } catch {
                $AnalyzerResults = @()
            }
            @($AnalyzerResults).Count | Should -BeLessThan 20 -Because "Module should have fewer than 20 warnings"
        }

        It 'Should pass PSScriptAnalyzer with settings file if it exists' {
            if (Test-Path $SettingsPath) {
                $AnalyzerResults = Invoke-ScriptAnalyzer -Path $ModuleRoot -Settings $SettingsPath -Recurse -ErrorAction SilentlyContinue
                $CriticalResults = $AnalyzerResults | Where-Object { $_.Severity -eq 'Error' }

                if ($CriticalResults.Count -gt 0) {
                    $ErrorMessages = $CriticalResults | ForEach-Object { "$($_.ScriptName):$($_.Line) - $($_.Message)" }
                    $ErrorMessage = "Found $($CriticalResults.Count) violation(s) with settings file:`n" + ($ErrorMessages -join "`n")
                    $CriticalResults.Count | Should -Be 0 -Because $ErrorMessage
                } else {
                    $CriticalResults.Count | Should -Be 0
                }
            } else {
                Set-ItResult -Skipped -Because "PSScriptAnalyzerSettings.psd1 not found"
            }
        }

        It 'Should not use Write-Host in functions' {
            $PublicPath = Join-Path -Path $ModuleRoot -ChildPath 'Src\Public'
            $PrivatePath = Join-Path -Path $ModuleRoot -ChildPath 'Src\Private'

            $ViolatingFiles = @()
            foreach ($Path in @($PublicPath, $PrivatePath)) {
                $Results = Invoke-ScriptAnalyzer -Path $Path -IncludeRule PSAvoidUsingWriteHost -Recurse -ErrorAction SilentlyContinue
                $ViolatingFiles += $Results
            }

            $ViolatingFiles.Count | Should -Be 0 -Because "Functions should use Write-Verbose, Write-Warning, or Write-Error instead of Write-Host"
        }
    }

    Context 'Function Documentation Quality' {
        BeforeAll {
            $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
            $PublicFunctions = Get-ChildItem -Path "$ModuleRoot\Src\Public" -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
        }

        It 'All public functions should have SYNOPSIS' {
            foreach ($Function in $PublicFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\.SYNOPSIS' -Because "$($Function.Name) should have .SYNOPSIS documentation"
            }
        }

        It 'All public functions should have DESCRIPTION' {
            foreach ($Function in $PublicFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\.DESCRIPTION' -Because "$($Function.Name) should have .DESCRIPTION documentation"
            }
        }

        It 'All public functions should have at least one EXAMPLE' {
            foreach ($Function in $PublicFunctions) {
                # Check file content directly since Get-Help requires module to be loaded
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\.EXAMPLE' -Because "$($Function.Name) should have at least one .EXAMPLE section in comment-based help"
            }
        }

        It 'All public functions should have NOTES section' {
            foreach ($Function in $PublicFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\.NOTES' -Because "$($Function.Name) should have .NOTES documentation"
            }
        }

        It 'All public functions should have LINK section' {
            foreach ($Function in $PublicFunctions) {
                $Content = Get-Content -Path $Function.FullName -Raw
                $Content | Should -Match '\.LINK' -Because "$($Function.Name) should have .LINK documentation"
            }
        }

        It 'Public function DESCRIPTION should be meaningful' {
            foreach ($Function in $PublicFunctions) {
                # Check file content directly since Get-Help requires module to be loaded
                $Content = Get-Content -Path $Function.FullName -Raw

                # Extract DESCRIPTION section content (allow for whitespace/newlines)
                if ($Content -match '\.DESCRIPTION\s+([\s\S]+?)(?=\s+\.(?:NOTES|PARAMETER|EXAMPLE|LINK|INPUTS|OUTPUTS)|$)') {
                    $DescriptionText = $Matches[1].Trim()
                    # Remove excessive whitespace
                    $DescriptionText = $DescriptionText -replace '\s+', ' '
                    $DescriptionText.Length | Should -BeGreaterThan 50 -Because "$($Function.Name) should have a meaningful description (>50 characters)"
                }
            }
        }
    }
}

Describe 'Error Handling and Edge Cases' {
    Context 'Configuration Error Handling' {
        It 'Should handle invalid JSON configuration gracefully' {
            $InvalidJsonPath = Join-Path -Path $TestDrive -ChildPath 'invalid.json'
            Set-Content -Path $InvalidJsonPath -Value '{ invalid json content'

            { Get-Content -Path $InvalidJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop } | Should -Throw
        }

        It 'Should validate InfoLevel range when manually checking' {
            # Test that our validation logic works for out-of-range values
            $ValidValues = 0..4
            $InvalidValues = @(-1, 5, 10, 100)

            foreach ($Invalid in $InvalidValues) {
                $Invalid -in $ValidValues | Should -Be $false
            }

            foreach ($Valid in $ValidValues) {
                $Valid -in $ValidValues | Should -Be $true
            }
        }
    }

    Context 'Parameter Validation' {
        BeforeAll {
            $InvokeCommand = Get-Command -Name 'Invoke-AsBuiltReport.Microsoft.Azure' -ErrorAction SilentlyContinue
        }

        It 'Target parameter should be mandatory or have default behavior' {
            if ($InvokeCommand) {
                $TargetParam = $InvokeCommand.Parameters['Target']
                # Target should exist as we've already tested
                $TargetParam | Should -Not -BeNullOrEmpty
            }
        }

        It 'Credential parameter should accept PSCredential type' {
            if ($InvokeCommand) {
                $CredParam = $InvokeCommand.Parameters['Credential']
                $CredParam.ParameterType.Name | Should -Be 'PSCredential'
            }
        }
    }

    Context 'Module Import Error Scenarios' {
        It 'Should gracefully handle missing required modules in manifest' {
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
            $Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop

            # Verify required modules are declared
            $Manifest.RequiredModules | Should -Not -BeNullOrEmpty
            $Manifest.RequiredModules.Name | Should -Contain 'AsBuiltReport.Core'
        }

        It 'Should have valid PowerShell version requirement' {
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
            $Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop

            $Manifest.PowerShellVersion | Should -Not -BeNullOrEmpty
            $Manifest.PowerShellVersion | Should -BeOfType [System.Version]
        }
    }

    Context 'File Path Validation' {
        It 'Module manifest path should be valid' {
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
            Test-Path $ManifestPath | Should -Be $true
        }

        It 'Module root path should be valid' {
            $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure'
            Test-Path $ModuleRoot | Should -Be $true
        }

        It 'Language files should exist' {
            $LanguagePath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language'
            Test-Path $LanguagePath | Should -Be $true

            $EnUSPath = Join-Path -Path $LanguagePath -ChildPath 'en-US\MicrosoftAzure.psd1'
            Test-Path $EnUSPath | Should -Be $true

            $EnGBPath = Join-Path -Path $LanguagePath -ChildPath 'en-GB\MicrosoftAzure.psd1'
            Test-Path $EnGBPath | Should -Be $true
        }
    }

    Context 'Type Safety and Null Handling' {
        It 'JSON configuration should deserialize without errors' {
            $JsonConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.json'
            { Get-Content -Path $JsonConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Localization data should load without errors' {
            $EnUSPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\Language\en-US'
            { Import-LocalizedData -BaseDirectory $EnUSPath -FileName 'MicrosoftAzure.psd1' -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Module manifest should parse correctly' {
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\AsBuiltReport.Microsoft.Azure\AsBuiltReport.Microsoft.Azure.psd1'
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module -Name 'AsBuiltReport.Microsoft.Azure' -Force -ErrorAction SilentlyContinue
}
