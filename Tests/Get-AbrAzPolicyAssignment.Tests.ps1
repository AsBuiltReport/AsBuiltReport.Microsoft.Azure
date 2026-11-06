# Behaviour tests for Get-AbrAzPolicyAssignment, which run the real function with no Azure connection.
#
# PScribo and Az commands are replaced with stubs: simple functions that return test data and record what
# the function reported. Stubs are used rather than Pester's Mock because Mock needs the command to exist,
# and the Az modules are not installed in CI.
#
# Stubs only reflect what we expect Azure to return, so these tests do not replace a run against a live tenant.
#
# Run from the repository root: Invoke-Pester -Path .\Tests\Get-AbrAzPolicyAssignment.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'AsBuiltReport.Microsoft.Azure'
    $script:LanguagePath = Join-Path -Path $ModulePath -ChildPath 'Language'
    . (Join-Path -Path $ModulePath -ChildPath 'Src/Private/Report/Get-AbrAzPolicyAssignment.ps1')
    . (Join-Path -Path $ModulePath -ChildPath 'Src/Private/Report/Resolve-AbrAzPolicyScopeName.ps1')

    $script:SubscriptionId = '11111111-1111-1111-1111-111111111111'
    $script:DefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/definition'
    $script:ManagementGroupScope = '/providers/Microsoft.Management/managementGroups/mg-root'
    $script:SubscriptionScope = "/subscriptions/$script:SubscriptionId"
    $script:ResourceGroupScope = "$script:SubscriptionScope/resourceGroups/rg-app"
    $script:ResourceScope = "$script:ResourceGroupScope/providers/Microsoft.Storage/storageAccounts/stgacct01"

    function New-TestAssignment {
        param ([string] $DisplayName, [string] $Scope, [string[]] $NotScope)
        [PSCustomObject]@{
            DisplayName        = $DisplayName
            Description        = ''
            Location           = ''
            Scope              = $Scope
            NotScope           = $NotScope
            PolicyDefinitionId = $script:DefinitionId
            EnforcementMode    = 'Default'
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
        $script:Headings += $Name
        & $ScriptBlock
    }
    function Paragraph { param ([Parameter(Position = 0)][string] $Text) $script:Paragraphs += $Text }
    function BlankLine { }
    function Table {
        param (
            [Parameter(ValueFromPipeline)] $InputObject,
            [string] $Name, [switch] $List, [int[]] $ColumnWidths, [string[]] $Columns, [string[]] $Headers, [string] $Caption
        )
        process { $script:TableRows += [PSCustomObject]@{ Table = $Name; Row = $InputObject } }
    }
    function Write-PScriboMessage {
        param ([switch] $IsWarning, [Parameter(Position = 0)][string] $Message)
        if ($IsWarning) { $script:Warnings += $Message }
    }

    # Az stubs. Assignments below the subscription are only returned with -IncludeDescendent, as documented.
    function Get-AzPolicyAssignment {
        [CmdletBinding()]
        param ([switch] $IncludeDescendent)
        $script:Assignments | Where-Object { $IncludeDescendent -or $_.Scope -notmatch '/resourceGroups/' }
    }
    function Get-AzPolicyDefinition { [PSCustomObject]@{ Id = $script:DefinitionId } }
    function Get-AzPolicySetDefinition { }

    function Invoke-Assignment {
        param ([int] $Level, [string] $Culture = 'en-US')
        $script:Headings = @()
        $script:Paragraphs = @()
        $script:TableRows = @()
        $script:Warnings = @()
        $InfoLevel = [PSCustomObject]@{ Policy = [PSCustomObject]@{ Assignments = $Level } }
        $Report = [PSCustomObject]@{ ShowTableCaptions = $true }
        $AzLocationLookup = @{ }
        $AzSubscriptionLookup = @{ $script:SubscriptionId = 'Sub-Connectivity' }
        $AzSubscription = [PSCustomObject]@{ Name = 'Sub-Connectivity' }
        Import-LocalizedData -BaseDirectory $script:LanguagePath -UICulture $Culture -FileName 'MicrosoftAzure.psd1' -BindingVariable reportTranslate
        $script:Text = $reportTranslate.GetAbrAzPolicyAssignment
        Get-AbrAzPolicyAssignment
    }
}

Describe 'Get-AbrAzPolicyAssignment' {
    BeforeEach {
        $script:Assignments = @(
            New-TestAssignment 'B Subscription' $script:SubscriptionScope
            New-TestAssignment 'D Management group' $script:ManagementGroupScope
            New-TestAssignment 'A Resource group' $script:ResourceGroupScope
            New-TestAssignment 'C Resource' $script:ResourceScope
        )
    }

    # Assignments on resource groups and resources can be numerous, so they are reported as
    # a count at InfoLevel 1, a compact table at InfoLevel 2, and in full at InfoLevel 3.
    Context 'InfoLevels' {
        It 'InfoLevel 0 reports nothing' {
            Invoke-Assignment -Level 0
            $script:Headings | Should -BeNullOrEmpty
        }

        It 'InfoLevel 1 lists subscription and management group assignments, and counts the rest' {
            Invoke-Assignment -Level 1
            $script:TableRows.Row.($script:Text.Name) | Should -Be @('B Subscription', 'D Management group')
            $script:Paragraphs | Should -Contain ($script:Text.ParagraphResourceAssignmentCount -f 2, 'Sub-Connectivity')
        }

        It 'InfoLevel 1 omits the count when there are no resource group or resource assignments' {
            $script:Assignments = @(New-TestAssignment 'B Subscription' $script:SubscriptionScope)
            Invoke-Assignment -Level 1
            $script:Paragraphs | Should -Not -Contain ($script:Text.ParagraphResourceAssignmentCount -f 0, 'Sub-Connectivity')
            $script:Paragraphs.Count | Should -Be 1
        }

        It 'InfoLevel 1 still reports the count when every assignment is on a resource group or resource' {
            $script:Assignments = @(New-TestAssignment 'A Resource group' $script:ResourceGroupScope)
            Invoke-Assignment -Level 1
            $script:TableRows | Should -BeNullOrEmpty
            $script:Paragraphs | Should -Contain ($script:Text.ParagraphResourceAssignmentCount -f 1, 'Sub-Connectivity')
        }

        It 'InfoLevel 2 details subscription assignments and summarises the rest in one table' {
            Invoke-Assignment -Level 2
            $script:Headings | Should -Contain 'B Subscription'
            $script:Headings | Should -Contain 'D Management group'
            $script:Headings | Should -Not -Contain 'A Resource group'
            $script:Headings | Should -Contain $script:Text.ResourceAssignmentsHeading
            $Compact = $script:TableRows | Where-Object { $_.Table -like "$($script:Text.ResourceAssignmentsHeading)*" }
            $Compact.Row.($script:Text.Name) | Should -Be @('A Resource group', 'C Resource')
        }

        It 'InfoLevel 3 details every assignment in name order, with no compact table' {
            Invoke-Assignment -Level 3
            $script:Headings | Should -Not -Contain $script:Text.ResourceAssignmentsHeading
            $script:TableRows.Row.($script:Text.Name) | Should -Be @('A Resource group', 'B Subscription', 'C Resource', 'D Management group')
        }
    }

    # Regression tests for #34: the section was lost in es-ES and fr-FR, where the Name label is translated.
    Context 'Languages' {
        It 'InfoLevel <Level> reports assignments with translated labels in <Culture>' -ForEach @(
            foreach ($Culture in 'de-DE', 'en-GB', 'en-US', 'es-ES', 'fr-FR') {
                foreach ($Level in 1, 2, 3) { @{ Culture = $Culture; Level = $Level } }
            }
        ) {
            Invoke-Assignment -Level $Level -Culture $Culture
            $script:Warnings | Should -BeNullOrEmpty
            $script:TableRows.Row.($script:Text.Name) | Should -Contain 'B Subscription'
        }

        It 'Per-assignment headings use the assignment name in <_>' -ForEach @('de-DE', 'en-GB', 'en-US', 'es-ES', 'fr-FR') {
            Invoke-Assignment -Level 2 -Culture $_
            $script:Headings | Should -Contain 'B Subscription'
        }
    }

    # Scopes are full resource paths, which these tests check are shown as readable names.
    # Excluded scopes were previously blank for resource groups, and repeated when there was more than one.
    Context 'Scopes' {
        It 'Shows readable names for each scope type' {
            Invoke-Assignment -Level 3
            $Scopes = @{}
            foreach ($Row in $script:TableRows.Row) { $Scopes[$Row.($script:Text.Name)] = $Row.($script:Text.Scope) }
            $Scopes['B Subscription'] | Should -Be 'Sub-Connectivity'
            $Scopes['D Management group'] | Should -Be 'mg-root'
            $Scopes['A Resource group'] | Should -Be 'rg-app'
            $Scopes['C Resource'] | Should -Be 'stgacct01'
        }

        It 'Shows -- when nothing is excluded' {
            $script:Assignments = @(New-TestAssignment 'B Subscription' $script:SubscriptionScope)
            Invoke-Assignment -Level 2
            $script:TableRows[0].Row.($script:Text.ExcludedScopes) | Should -Be '--'
        }

        It 'Lists each excluded scope once, by name' {
            $NotScope = @($script:SubscriptionScope, $script:ResourceGroupScope, $script:ResourceScope)
            $script:Assignments = @(New-TestAssignment 'D Management group' $script:ManagementGroupScope $NotScope)
            Invoke-Assignment -Level 2
            $script:TableRows[0].Row.($script:Text.ExcludedScopes) | Should -Be 'Sub-Connectivity, rg-app, stgacct01'
        }

        It 'Shows the subscription ID when the subscription is not known' {
            $Scope = '/subscriptions/22222222-2222-2222-2222-222222222222'
            $script:Assignments = @(New-TestAssignment 'B Subscription' $Scope)
            Invoke-Assignment -Level 2
            $script:TableRows[0].Row.($script:Text.Scope) | Should -Be '22222222-2222-2222-2222-222222222222'
        }
    }
}
