# Behaviour tests for how Invoke-AsBuiltReport.Microsoft.Azure decides which subscriptions to report.
#
# A subscription is only reported if it has a resource for an enabled section. Policy and DiagnosticSetting
# have no resource type to check, so these tests cover those sections on their own and alongside others.
#
# The real function runs with stubbed PScribo, AsBuiltReport.Core and Az commands, so no Azure connection
# is needed. The report sections are also stubs, which only record that they ran.
#
# Run from the repository root: Invoke-Pester -Path .\Tests\Invoke-AsBuiltReport.Microsoft.Azure.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'AsBuiltReport.Microsoft.Azure'
    $script:LanguagePath = Join-Path -Path $ModulePath -ChildPath 'Language'
    . (Join-Path -Path $ModulePath -ChildPath 'Src/Public/Invoke-AsBuiltReport.Microsoft.Azure.ps1')
    . (Join-Path -Path $ModulePath -ChildPath 'Src/Private/Report/Test-AbrAzInfoLevelEnabled.ps1')

    $script:SubscriptionName = 'Sub-Connectivity'

    # PScribo stubs
    function Section {
        param (
            [string] $Style,
            [Parameter(Position = 0)][string] $Name,
            [Parameter(Position = 1)][scriptblock] $ScriptBlock
        )
        $script:Headings += $Name
        & $ScriptBlock
    }
    function Write-PScriboMessage { param ([string] $Plugin, [string] $Message, [switch] $IsWarning) }

    # AsBuiltReport.Core stubs
    function Get-RequiredModule { param ($Name, $Version) }
    function Write-ReportModuleInfo { param ($ModuleName) }

    # Az stubs
    function Clear-AzContext { [CmdletBinding()] param ($Scope, [switch] $Force) }
    function Connect-AzAccount { [CmdletBinding()] param ($TenantId) [PSCustomObject]@{ Account = 'test' } }
    function Disconnect-AzAccount { param ($Account) }
    function Get-AzTenant { [CmdletBinding()] param ($TenantId) [PSCustomObject]@{ Name = 'Contoso' } }
    function Get-AzLocation { [CmdletBinding()] param () }
    function Get-AzSubscription {
        [CmdletBinding()]
        param ($TenantId, $SubscriptionId)
        [PSCustomObject]@{ Name = $script:SubscriptionName; Id = 'sub-id'; SubscriptionId = 'sub-id' }
    }
    function Set-AzContext { [CmdletBinding()] param ($Subscription, $Tenant) }
    function Get-AzResource {
        [CmdletBinding()]
        param ($ResourceType)
        if ($script:HasVirtualNetwork -and $ResourceType -eq 'Microsoft.Network/virtualNetworks') {
            [PSCustomObject]@{ Name = 'vnet1' }
        }
    }

    # Report section stubs, which record that they ran
    function Get-AbrAzTenant { }
    function Get-AbrAzManagementGroup { }
    function Get-AbrAzNetworkTopology { }
    function Get-AbrAzSubscription { }
    function Get-AbrAzPolicy { $script:SectionsRun += 'Policy' }
    function Get-AbrAzDiagnosticSetting { $script:SectionsRun += 'DiagnosticSetting' }
    function Get-AbrAzVirtualNetwork { $script:SectionsRun += 'VirtualNetwork' }

    function Invoke-Report {
        param ([object] $InfoLevel, [bool] $HasVirtualNetwork)
        $script:Headings = @()
        $script:SectionsRun = @()
        $script:HasVirtualNetwork = $HasVirtualNetwork
        $ReportConfig = [PSCustomObject]@{
            Report    = [PSCustomObject]@{ }
            Filter    = [PSCustomObject]@{ Subscription = @('*') }
            InfoLevel = $InfoLevel
            Options   = [PSCustomObject]@{ SectionOrder = @('VirtualNetwork', 'Policy', 'DiagnosticSetting') }
            Diagram   = [PSCustomObject]@{ }
        }
        Import-LocalizedData -BaseDirectory $script:LanguagePath -UICulture 'en-US' -FileName 'MicrosoftAzure.psd1' -BindingVariable reportTranslate
        Invoke-AsBuiltReport.Microsoft.Azure -Target 'tenant-id'
    }

    function New-InfoLevel {
        param ([int] $VirtualNetwork, [int] $DiagnosticSetting, [int] $Assignments)
        [PSCustomObject]@{
            Subscription      = 2
            VirtualNetwork    = $VirtualNetwork
            DiagnosticSetting = $DiagnosticSetting
            Policy            = [PSCustomObject]@{ Assignments = $Assignments; Definitions = 0; Exemptions = 0 }
        }
    }
}

Describe 'Invoke-AsBuiltReport.Microsoft.Azure subscription sections' {
    # Regression test: with only Policy enabled, the report contained just the subscriptions table.
    It 'Reports Policy when it is the only section enabled' {
        Invoke-Report -InfoLevel (New-InfoLevel -Assignments 3) -HasVirtualNetwork $true
        $script:Headings | Should -Contain $script:SubscriptionName
        $script:SectionsRun | Should -Be @('Policy')
    }

    It 'Reports DiagnosticSetting when it is the only section enabled' {
        Invoke-Report -InfoLevel (New-InfoLevel -DiagnosticSetting 1) -HasVirtualNetwork $true
        $script:Headings | Should -Contain $script:SubscriptionName
        $script:SectionsRun | Should -Be @('DiagnosticSetting')
    }

    It 'Reports no subscription section when every section is disabled' {
        Invoke-Report -InfoLevel (New-InfoLevel) -HasVirtualNetwork $true
        $script:Headings | Should -Not -Contain $script:SubscriptionName
        $script:SectionsRun | Should -BeNullOrEmpty
    }

    # Empty subscriptions are deliberately left out of reports, including when Policy is enabled alongside other sections.
    It 'Hides a subscription with no resources for the enabled sections' {
        Invoke-Report -InfoLevel (New-InfoLevel -VirtualNetwork 1 -DiagnosticSetting 1 -Assignments 1) -HasVirtualNetwork $false
        $script:Headings | Should -Not -Contain $script:SubscriptionName
        $script:SectionsRun | Should -BeNullOrEmpty
    }

    It 'Reports every enabled section for a subscription with resources' {
        Invoke-Report -InfoLevel (New-InfoLevel -VirtualNetwork 1 -Assignments 1) -HasVirtualNetwork $true
        $script:Headings | Should -Contain $script:SubscriptionName
        $script:SectionsRun | Should -Be @('VirtualNetwork', 'Policy')
    }
}
