# Behaviour tests for the endpoint tables in Get-AbrAzDnsPrivateResolver (see issue #37).
#
# Runs the real function with stubbed PScribo and Az commands, so no Azure connection is needed.
# The stubs follow the Az.DnsResolver models: inbound endpoints have a list of IP configurations, while
# outbound endpoints have a SubnetId. These tests do not replace a run against a live tenant.
#
# Run from the repository root: Invoke-Pester -Path .\Tests\Get-AbrAzDnsPrivateResolver.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'AsBuiltReport.Microsoft.Azure'
    $script:LanguagePath = Join-Path -Path $ModulePath -ChildPath 'Language'
    . (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $ModulePath -ChildPath 'Src') -ChildPath 'Private') -ChildPath 'Report') -ChildPath 'Get-AbrAzDnsPrivateResolver.ps1')

    $script:SubscriptionId = '11111111-1111-1111-1111-111111111111'

    function New-TestResolver {
        param ([string] $Name, [string] $ResourceGroup = 'rg-dns')
        [PSCustomObject]@{
            Name                     = $Name
            Id                       = "/subscriptions/$script:SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/dnsResolvers/$Name"
            Location                 = 'westeurope'
            VirtualNetworkId         = "/subscriptions/$script:SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/virtualNetworks/vnet"
            ResourceGuid             = 'guid'
            SystemDataCreatedAt      = [DateTime]::UtcNow
            SystemDataLastModifiedAt = [DateTime]::UtcNow
            State                    = 'Connected'
            ProvisioningState        = 'Succeeded'
            Tag                      = $null
        }
    }
    function New-TestInboundEndpoint {
        param ([string] $Name, [string[]] $IpAddress)
        [PSCustomObject]@{
            Name            = $Name
            IPConfiguration = @($IpAddress | ForEach-Object { [PSCustomObject]@{ PrivateIPAddress = $_; PrivateIPAllocationMethod = 'Dynamic' } })
        }
    }
    function New-TestOutboundEndpoint {
        param ([string] $Name, [string] $Subnet)
        [PSCustomObject]@{
            Name     = $Name
            SubnetId = "/subscriptions/$script:SubscriptionId/resourceGroups/rg-dns/providers/Microsoft.Network/virtualNetworks/vnet/subnets/$Subnet"
        }
    }

    # PScribo stubs. Section rejects an empty name, as PScribo does.
    function Section {
        param (
            [string] $Style,
            [switch] $ExcludeFromTOC,
            [Parameter(Position = 0)][ValidateNotNullOrEmpty()][string] $Name,
            [Parameter(Position = 1)][scriptblock] $ScriptBlock
        )
        & $ScriptBlock
    }
    function Paragraph { param ([Parameter(Position = 0)][string] $Text) }
    function BlankLine { }
    function Table {
        param (
            [Parameter(ValueFromPipeline)] $InputObject,
            [string] $Name, [switch] $List, [int[]] $ColumnWidths, [string[]] $Columns, [string] $Caption
        )
        process { $script:TableRows += [PSCustomObject]@{ Table = $Name; Row = $InputObject } }
    }
    function Write-PScriboMessage {
        param ([switch] $IsWarning, [Parameter(Position = 0)][string] $Message)
        if ($IsWarning) { $script:Warnings += $Message }
    }

    # Az stubs. Endpoints belong to a resource group and resolver, so lookups need both.
    function Get-AzDnsResolver { $script:Resolvers }
    function Get-AzDnsResolverInboundEndpoint {
        [CmdletBinding()]
        param ($DnsResolverName, $ResourceGroupName)
        $script:Inbound["$ResourceGroupName/$DnsResolverName"]
    }
    function Get-AzDnsResolverOutboundEndpoint {
        [CmdletBinding()]
        param ($DnsResolverName, $ResourceGroupName)
        $script:Outbound["$ResourceGroupName/$DnsResolverName"]
    }

    function Invoke-Resolver {
        param ([int] $Level = 2, [string] $Culture = 'en-US')
        $script:TableRows = @()
        $script:Warnings = @()
        $InfoLevel = [PSCustomObject]@{ DnsPrivateResolver = $Level }
        $Report = [PSCustomObject]@{ ShowTableCaptions = $true }
        $Options = [PSCustomObject]@{ ShowSectionInfo = $false; ShowTags = $false }
        $AzLocationLookup = @{ westeurope = 'West Europe' }
        $AzSubscriptionLookup = @{ $script:SubscriptionId = 'Sub-Dns' }
        $AzSubscription = [PSCustomObject]@{ Name = 'Sub-Dns' }
        Import-LocalizedData -BaseDirectory $script:LanguagePath -UICulture $Culture -FileName 'MicrosoftAzure.psd1' -BindingVariable reportTranslate
        $script:Text = $reportTranslate.GetAbrAzDnsPrivateResolver
        Get-AbrAzDnsPrivateResolver
    }

    function Get-EndpointRow {
        param ([string] $Heading, [string] $Resolver)
        ($script:TableRows | Where-Object { $_.Table -eq "$Heading - $Resolver" }).Row
    }
}

Describe 'Get-AbrAzDnsPrivateResolver endpoints' {
    BeforeEach {
        $script:Resolvers = @((New-TestResolver 'resolver-a'), (New-TestResolver 'resolver-b'))
        $script:Inbound = @{
            'rg-dns/resolver-a' = @((New-TestInboundEndpoint 'inbound-a2' '10.1.0.5'), (New-TestInboundEndpoint 'inbound-a1' '10.1.0.4'))
            'rg-dns/resolver-b' = @(New-TestInboundEndpoint 'inbound-b1' '10.2.0.4')
        }
        $script:Outbound = @{
            'rg-dns/resolver-a' = @(New-TestOutboundEndpoint 'outbound-a1' 'snet-a')
            'rg-dns/resolver-b' = @(New-TestOutboundEndpoint 'outbound-b1' 'snet-b')
        }
    }

    # Regression test for #37: endpoints were collected in one loop and read in a later one,
    # so every resolver showed the last resolver's endpoints.
    It 'Shows each resolver its own endpoints' {
        Invoke-Resolver
        (Get-EndpointRow $script:Text.InboundEndpoints 'resolver-a').($script:Text.EndpointName) | Should -Be @('inbound-a1', 'inbound-a2')
        (Get-EndpointRow $script:Text.InboundEndpoints 'resolver-b').($script:Text.EndpointName) | Should -Be 'inbound-b1'
        (Get-EndpointRow $script:Text.OutboundEndpoints 'resolver-a').($script:Text.EndpointName) | Should -Be 'outbound-a1'
        (Get-EndpointRow $script:Text.OutboundEndpoints 'resolver-b').($script:Text.EndpointName) | Should -Be 'outbound-b1'
    }

    It 'Reports one row per endpoint, in name order' {
        Invoke-Resolver
        $Rows = @(Get-EndpointRow $script:Text.InboundEndpoints 'resolver-a')
        $Rows.Count | Should -Be 2
        $Rows[0].($script:Text.IpAddress) | Should -Be '10.1.0.4'
        $Rows[1].($script:Text.IpAddress) | Should -Be '10.1.0.5'
    }

    It 'Lists every IP address on an inbound endpoint, in its row' {
        $script:Inbound['rg-dns/resolver-a'] = @(New-TestInboundEndpoint 'inbound-a1' @('10.1.0.4', '10.1.0.5'))
        Invoke-Resolver
        $Row = Get-EndpointRow $script:Text.InboundEndpoints 'resolver-a'
        $Row.($script:Text.IpAddress) | Should -Be '10.1.0.4, 10.1.0.5'
        $Row.($script:Text.IpAllocation) | Should -Be 'Dynamic, Dynamic'
    }

    # The outbound endpoint model has no IP configuration, so IP columns could never be populated.
    It 'Reports the subnet for outbound endpoints, not IP columns' {
        Invoke-Resolver
        $Row = Get-EndpointRow $script:Text.OutboundEndpoints 'resolver-a'
        $Row.($script:Text.Subnet) | Should -Be 'snet-a'
        $Row.PSObject.Properties.Name | Should -Not -Contain $script:Text.IpAddress
        $Row.PSObject.Properties.Name | Should -Not -Contain $script:Text.IpAllocation
    }

    It 'Keeps endpoints separate for resolvers with the same name in different resource groups' {
        $script:Resolvers = @((New-TestResolver 'resolver-a' 'rg-one'), (New-TestResolver 'resolver-a' 'rg-two'))
        $script:Inbound = @{
            'rg-one/resolver-a' = @(New-TestInboundEndpoint 'inbound-one' '10.1.0.4')
            'rg-two/resolver-a' = @(New-TestInboundEndpoint 'inbound-two' '10.2.0.4')
        }
        $script:Outbound = @{}
        Invoke-Resolver
        # Sort-Object is not stable in Windows PowerShell 5.1, so resolvers with the same name can appear in either order
        (Get-EndpointRow $script:Text.InboundEndpoints 'resolver-a').($script:Text.EndpointName) | Sort-Object | Should -Be @('inbound-one', 'inbound-two')
    }

    It 'Omits the endpoint tables for a resolver with no endpoints, even if another resolver has them' {
        $script:Inbound.Remove('rg-dns/resolver-a')
        $script:Outbound.Remove('rg-dns/resolver-a')
        Invoke-Resolver
        Get-EndpointRow $script:Text.InboundEndpoints 'resolver-a' | Should -BeNullOrEmpty
        Get-EndpointRow $script:Text.OutboundEndpoints 'resolver-a' | Should -BeNullOrEmpty
        Get-EndpointRow $script:Text.InboundEndpoints 'resolver-b' | Should -Not -BeNullOrEmpty
    }

    It 'Counts match the endpoints listed' {
        Invoke-Resolver
        $Summary = Get-EndpointRow $script:Text.TableHeading 'resolver-a'
        $Summary.($script:Text.InboundEndpoints) | Should -Be 2
        $Summary.($script:Text.OutboundEndpoints) | Should -Be 1
    }

    It 'Reports endpoints in <_>' -ForEach @('de-DE', 'en-GB', 'en-US', 'es-ES', 'fr-FR') {
        Invoke-Resolver -Culture $_
        $script:Warnings | Should -BeNullOrEmpty
        $script:Text.Subnet | Should -Not -BeNullOrEmpty
        (Get-EndpointRow $script:Text.OutboundEndpoints 'resolver-b').($script:Text.Subnet) | Should -Be 'snet-b'
    }
}
