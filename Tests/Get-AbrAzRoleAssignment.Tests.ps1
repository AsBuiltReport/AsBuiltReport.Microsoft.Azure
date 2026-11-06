# Behaviour tests for Get-AbrAzRoleAssignment, which run the real function with no Azure connection.
#
# PScribo and Az commands are replaced with stubs: simple functions that return test data and record what
# the function reported. Stubs are used rather than Pester's Mock because Mock needs the command to exist,
# and the Az modules are not installed in CI.
#
# Stubs only reflect what we expect Azure to return, so these tests do not replace a run against a live tenant.
# The stubs follow the PSRoleAssignment, PSRoleDefinition and PSPermission models in Az.Resources.
#
# Principals must never be reported, so the 'Principal identities' tests give every stub a recognisable identity
# and check that it appears nowhere in the output.
#
# Run from the repository root: Invoke-Pester -Path .\Tests\Get-AbrAzRoleAssignment.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'AsBuiltReport.Microsoft.Azure'
    $script:LanguagePath = Join-Path -Path $ModulePath -ChildPath 'Language'
    $script:ReportPath = Join-Path -Path $ModulePath -ChildPath 'Src/Private/Report'
    . (Join-Path -Path $script:ReportPath -ChildPath 'Get-AbrAzRoleAssignment.ps1')
    . (Join-Path -Path $script:ReportPath -ChildPath 'Resolve-AbrAzRoleScopeName.ps1')
    . (Join-Path -Path $script:ReportPath -ChildPath 'Resolve-AbrAzPolicyScopeName.ps1')

    $script:Identities = @('Alice Example', 'alice@contoso.com', '11111111-2222-3333-4444-555555555555', 'Requested by Alice')

    function New-TestAssignment {
        param ([string] $Role, [string] $Type, [string] $Scope)
        [PSCustomObject]@{
            RoleAssignmentName = 'aaaaaaaa-0000-0000-0000-000000000000'
            RoleAssignmentId   = "$Scope/providers/Microsoft.Authorization/roleAssignments/aaaaaaaa-0000-0000-0000-000000000000"
            Scope              = $Scope
            DisplayName        = 'Alice Example'
            SignInName         = 'alice@contoso.com'
            RoleDefinitionName = $Role
            RoleDefinitionId   = 'bbbbbbbb-0000-0000-0000-000000000000'
            ObjectId           = '11111111-2222-3333-4444-555555555555'
            ObjectType         = $Type
            CanDelegate        = $false
            Description        = 'Requested by Alice'
        }
    }

    function New-TestCustomRole {
        param ([string] $Name, [string] $Description, [string[]] $AssignableScopes, [string[]] $Actions, [string[]] $DataActions)
        [PSCustomObject]@{
            Name             = $Name
            Id               = 'cccccccc-0000-0000-0000-000000000000'
            IsCustom         = $true
            Description      = $Description
            AssignableScopes = $AssignableScopes
            Permissions      = @([PSCustomObject]@{ Actions = $Actions; NotActions = @('Microsoft.Compute/virtualMachines/delete'); DataActions = $DataActions; NotDataActions = @() })
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
            [string] $Name, [switch] $List, [int[]] $ColumnWidths, [string] $Caption
        )
        process { $script:TableRows += [PSCustomObject]@{ Table = $Name; Row = $InputObject } }
    }
    function Write-PScriboMessage {
        param ([switch] $IsWarning, [Parameter(Position = 0)][string] $Message)
        $script:Messages += $Message
        if ($IsWarning) { $script:Warnings += $Message }
    }

    # Az stubs
    function Get-AzRoleAssignment {
        [CmdletBinding()]
        param ()
        $script:AssignmentCalls++
        if ($script:FailAssignments) { throw 'Could not read principal Alice Example (alice@contoso.com)' }
        $script:Assignments
    }
    function Get-AzRoleDefinition {
        [CmdletBinding()]
        param ([switch] $Custom)
        $script:RoleDefinitionCalls++
        if (-not $Custom) { throw 'Only custom roles should be requested' }
        if ($script:FailCustomRoles) { throw 'Access denied' }
        $script:CustomRoles
    }

    function Invoke-RoleAssignment {
        param ([int] $Assignments = 0, [int] $CustomRoles = 0, [string] $Culture = 'en-US')
        $script:Headings = @()
        $script:Paragraphs = @()
        $script:TableRows = @()
        $script:Warnings = @()
        $script:Messages = @()
        $script:AssignmentCalls = 0
        $script:RoleDefinitionCalls = 0
        $InfoLevel = [PSCustomObject]@{ RoleAssignment = [PSCustomObject]@{ Assignments = $Assignments; CustomRoles = $CustomRoles } }
        $Report = [PSCustomObject]@{ ShowTableCaptions = $true }
        $Options = [PSCustomObject]@{ ShowSectionInfo = $false }
        $AzSubscription = [PSCustomObject]@{ Name = 'Contoso-Prod'; Id = 'sub-1' }
        $AzSubscriptionLookup = @{ 'sub-1' = 'Contoso-Prod' }
        Import-LocalizedData -BaseDirectory $script:LanguagePath -UICulture $Culture -FileName 'MicrosoftAzure.psd1' -BindingVariable reportTranslate
        $script:Text = $reportTranslate.GetAbrAzRoleAssignment
        Get-AbrAzRoleAssignment
    }

    # Returns the rows of one table, using the name it was reported with
    function Get-TableRow {
        param ([string] $Name)
        @(($script:TableRows | Where-Object { $_.Table -eq $Name }).Row)
    }
}

Describe 'Get-AbrAzRoleAssignment' {
    BeforeEach {
        $script:FailAssignments = $false
        $script:FailCustomRoles = $false
        $Sub = '/subscriptions/sub-1'
        $script:Assignments = @(
            New-TestAssignment -Role 'Owner' -Type 'Group' -Scope '/providers/Microsoft.Management/managementGroups/mg-contoso'
            New-TestAssignment -Role 'Owner' -Type 'User' -Scope $Sub
            New-TestAssignment -Role 'Contributor' -Type 'ServicePrincipal' -Scope $Sub
            New-TestAssignment -Role 'Contributor' -Type 'ServicePrincipal' -Scope $Sub
            New-TestAssignment -Role 'Reader' -Type 'User' -Scope "$Sub/resourceGroups/rg-1"
            New-TestAssignment -Role 'Reader' -Type 'Group' -Scope "$Sub/resourceGroups/rg-1/providers/Microsoft.KeyVault/vaults/kv-1"
        )
        $script:CustomRoles = @(
            New-TestCustomRole -Name 'VM Operator' -Description 'Start and stop VMs' -AssignableScopes @($Sub, '/providers/Microsoft.Management/managementGroups/mg-contoso') -Actions @('Microsoft.Compute/virtualMachines/start/action', 'Microsoft.Compute/virtualMachines/read') -DataActions @('Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read')
        )
    }

    # Azure and the directory are only queried for what is enabled
    Context 'InfoLevels' {
        It 'Reports nothing and makes no Azure calls when both are 0' {
            Invoke-RoleAssignment
            $script:Headings | Should -BeNullOrEmpty
            $script:AssignmentCalls | Should -Be 0
            $script:RoleDefinitionCalls | Should -Be 0
        }

        It 'Assignments at 1 reports the summary only, and does not read custom roles' {
            Invoke-RoleAssignment -Assignments 1
            $script:Headings | Should -Be @($script:Text.Heading, $script:Text.AssignmentsHeading)
            $script:RoleDefinitionCalls | Should -Be 0
        }

        It 'Assignments at 2 adds the table by scope' {
            Invoke-RoleAssignment -Assignments 2
            $script:Headings | Should -Be @($script:Text.Heading, $script:Text.AssignmentsHeading, $script:Text.AssignmentDetailHeading)
        }

        It 'CustomRoles at 1 reports the summary only, and does not read assignments' {
            Invoke-RoleAssignment -CustomRoles 1
            $script:Headings | Should -Be @($script:Text.Heading, $script:Text.CustomRolesHeading)
            $script:AssignmentCalls | Should -Be 0
        }

        It 'CustomRoles at 2 adds a table for each role' {
            Invoke-RoleAssignment -CustomRoles 2
            $script:Headings | Should -Be @($script:Text.Heading, $script:Text.CustomRolesHeading, 'VM Operator')
        }

        It 'Reports nothing when there is nothing to show' {
            $script:Assignments = @()
            $script:CustomRoles = @()
            Invoke-RoleAssignment -Assignments 3 -CustomRoles 2
            $script:Headings | Should -BeNullOrEmpty
            $script:Warnings | Should -BeNullOrEmpty
        }
    }

    # This is a security requirement: a report must not identify anyone who holds a role
    Context 'Principal identities' {
        It 'Never reports an identity at InfoLevel <_>' -ForEach @(1, 2, 3) {
            Invoke-RoleAssignment -Assignments $_ -CustomRoles 2
            $Output = @($script:Headings) + @($script:Paragraphs) + @($script:Messages) + @($script:TableRows.Table) +
                @($script:TableRows.Row | ForEach-Object { $_.PSObject.Properties.Name; $_.PSObject.Properties.Value })
            $Output | Should -Not -BeNullOrEmpty
            foreach ($Identity in $script:Identities) {
                ($Output -join "`n") | Should -Not -Match ([regex]::Escape($Identity))
            }
        }

        It 'Does not repeat an Azure error, which could include an identity' {
            $script:FailAssignments = $true
            Invoke-RoleAssignment -Assignments 3
            $script:Warnings | Should -HaveCount 1
            foreach ($Identity in $script:Identities) {
                $script:Warnings[0] | Should -Not -Match ([regex]::Escape($Identity))
            }
        }

        # Catches a future change that reads these properties, even one the other tests would not exercise
        It 'Does not read identity properties in the function' {
            $Source = Get-Content -Path (Join-Path -Path $script:ReportPath -ChildPath 'Get-AbrAzRoleAssignment.ps1') -Raw
            $Source | Should -Not -Match '\b(DisplayName|SignInName|ObjectId)\b'
        }

        It 'Does not report the free text description of an assignment' {
            Invoke-RoleAssignment -Assignments 3
            ($script:TableRows.Row | ForEach-Object { $_.PSObject.Properties.Value }) -join "`n" | Should -Not -Match 'Requested by'
        }
    }

    Context 'Assignment summary' {
        It 'Counts each role by principal type, including every scope' {
            Invoke-RoleAssignment -Assignments 1
            $Rows = Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod"
            $Rows.($script:Text.Role) | Should -Be @('Contributor', 'Owner', 'Reader')
            $Rows[0].($script:Text.ServicePrincipals) | Should -Be 2
            $Rows[0].($script:Text.Total) | Should -Be 2
            $Rows[1].($script:Text.Users) | Should -Be 1
            $Rows[1].($script:Text.Groups) | Should -Be 1
            $Rows[2].($script:Text.Total) | Should -Be 2
        }

        It 'Sorts by most assigned, then by name' {
            $script:Assignments = @(
                New-TestAssignment -Role 'Owner' -Type 'User' -Scope '/subscriptions/sub-1'
                New-TestAssignment -Role 'Contributor' -Type 'User' -Scope '/subscriptions/sub-1'
                New-TestAssignment -Role 'Reader' -Type 'User' -Scope '/subscriptions/sub-1'
                New-TestAssignment -Role 'Reader' -Type 'Group' -Scope '/subscriptions/sub-1'
            )
            Invoke-RoleAssignment -Assignments 1
            (Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod").($script:Text.Role) | Should -Be @('Reader', 'Contributor', 'Owner')
        }

        It 'Counts any other principal type as Other, so the columns add up to the total' {
            $script:Assignments = @(
                New-TestAssignment -Role 'Owner' -Type 'ForeignGroup' -Scope '/subscriptions/sub-1'
                New-TestAssignment -Role 'Owner' -Type 'Unknown' -Scope '/subscriptions/sub-1'
                New-TestAssignment -Role 'Owner' -Type 'User' -Scope '/subscriptions/sub-1'
            )
            Invoke-RoleAssignment -Assignments 1
            $Row = (Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod")[0]
            $Row.($script:Text.Other) | Should -Be 2
            $Row.($script:Text.Users) | Should -Be 1
            $Row.($script:Text.Total) | Should -Be 3
        }

        # Az reports Unknown for a deleted principal, or when the account cannot read the directory
        It 'Warns when principal types are unknown' {
            $script:Assignments = @(New-TestAssignment -Role 'Owner' -Type 'Unknown' -Scope '/subscriptions/sub-1')
            Invoke-RoleAssignment -Assignments 1
            $script:Warnings | Should -Be @($script:Text.UnknownPrincipals -f 1, 'Contoso-Prod')
        }

        It 'Shows Unknown for a role with no name, such as a deleted custom role' {
            $script:Assignments = @(New-TestAssignment -Role '' -Type 'User' -Scope '/subscriptions/sub-1')
            Invoke-RoleAssignment -Assignments 1
            (Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod")[0].($script:Text.Role) | Should -Be $script:Text.Unknown
        }

        It 'Reports a single assignment' {
            $script:Assignments = @(New-TestAssignment -Role 'Owner' -Type 'User' -Scope '/subscriptions/sub-1')
            Invoke-RoleAssignment -Assignments 3
            Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod" | Should -HaveCount 1
            Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod" | Should -HaveCount 1
        }

        It 'Reports custom roles when role assignments cannot be read' {
            $script:FailAssignments = $true
            Invoke-RoleAssignment -Assignments 1 -CustomRoles 1
            $script:Warnings | Should -Be @($script:Text.AssignmentsError -f 'Contoso-Prod')
            Get-TableRow "$($script:Text.CustomRolesHeading) - Contoso-Prod" | Should -HaveCount 1
        }
    }

    Context 'Assignments by scope' {
        It 'InfoLevel 2 lists management group and subscription scopes, and counts the rest' {
            Invoke-RoleAssignment -Assignments 2
            $Rows = Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod"
            $Rows.($script:Text.Scope) | Should -Be @(
                "$($script:Text.Subscription): Contoso-Prod"
                "$($script:Text.ManagementGroup): mg-contoso"
                "$($script:Text.Subscription): Contoso-Prod"
            )
            $script:Paragraphs | Should -Contain ($script:Text.ParagraphLowerScopeCount -f 2)
        }

        It 'InfoLevel 3 lists every scope, and does not mention a further count' {
            Invoke-RoleAssignment -Assignments 3
            $Scopes = (Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod").($script:Text.Scope)
            $Scopes | Should -Contain "$($script:Text.ResourceGroup): rg-1"
            $Scopes | Should -Contain "$($script:Text.Resource): kv-1"
            $script:Paragraphs | Should -Not -Contain ($script:Text.ParagraphLowerScopeCount -f 2)
        }

        It 'Shows matching assignments as one row with a count' {
            Invoke-RoleAssignment -Assignments 2
            $Row = Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod" | Where-Object { $_.($script:Text.Role) -eq 'Contributor' }
            $Row | Should -HaveCount 1
            $Row.($script:Text.AssignmentCount) | Should -Be 2
            $Row.($script:Text.Type) | Should -Be $script:Text.ServicePrincipal
        }

        It 'Names the root scope, which has no last segment' {
            $script:Assignments = @(New-TestAssignment -Role 'Owner' -Type 'Group' -Scope '/')
            Invoke-RoleAssignment -Assignments 2
            (Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod")[0].($script:Text.Scope) | Should -Be $script:Text.RootScope
        }

        It 'Treats scopes as case-insensitive, as Azure does' {
            $script:Assignments = @(New-TestAssignment -Role 'Reader' -Type 'User' -Scope '/subscriptions/sub-1/resourcegroups/rg-1')
            Invoke-RoleAssignment -Assignments 2
            $script:Paragraphs | Should -Contain ($script:Text.ParagraphLowerScopeCount -f 1)
        }

        It 'Still reports the count when every assignment is on a lower scope' {
            $script:Assignments = @(New-TestAssignment -Role 'Reader' -Type 'User' -Scope '/subscriptions/sub-1/resourceGroups/rg-1')
            Invoke-RoleAssignment -Assignments 2
            Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod" | Should -BeNullOrEmpty
            $script:Paragraphs | Should -Contain ($script:Text.ParagraphLowerScopeCount -f 1)
        }
    }

    Context 'Custom roles' {
        It 'Summarises each role, counting actions and data actions' {
            Invoke-RoleAssignment -CustomRoles 1
            $Row = (Get-TableRow "$($script:Text.CustomRolesHeading) - Contoso-Prod")[0]
            $Row.($script:Text.Name) | Should -Be 'VM Operator'
            $Row.($script:Text.Description) | Should -Be 'Start and stop VMs'
            $Row.($script:Text.AssignableScopes) | Should -Be 2
            $Row.($script:Text.Actions) | Should -Be 3
        }

        It 'InfoLevel 2 lists the permissions and assignable scopes' {
            Invoke-RoleAssignment -CustomRoles 2
            $Row = (Get-TableRow "$($script:Text.CustomRoleTableHeading) - VM Operator")[0]
            $Row.($script:Text.Actions) | Should -Be 'Microsoft.Compute/virtualMachines/start/action, Microsoft.Compute/virtualMachines/read'
            $Row.($script:Text.NotActions) | Should -Be 'Microsoft.Compute/virtualMachines/delete'
            $Row.($script:Text.DataActions) | Should -Be 'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
            $Row.($script:Text.NotDataActions) | Should -Be '--'
            $Row.($script:Text.AssignableScopes) | Should -Be "$($script:Text.Subscription): Contoso-Prod, $($script:Text.ManagementGroup): mg-contoso"
        }

        It 'Shows -- for a role with no description' {
            $script:CustomRoles = @(New-TestCustomRole -Name 'No Description' -Description '' -AssignableScopes @('/subscriptions/sub-1') -Actions @('a/read') -DataActions @())
            Invoke-RoleAssignment -CustomRoles 1
            (Get-TableRow "$($script:Text.CustomRolesHeading) - Contoso-Prod")[0].($script:Text.Description) | Should -Be '--'
        }

        # Older Az.Resources versions hold actions on the role rather than in Permissions
        It 'Reads actions held on the role itself' {
            $script:CustomRoles = @([PSCustomObject]@{ Name = 'Old Model'; Description = 'x'; AssignableScopes = @('/subscriptions/sub-1'); Actions = @('a/read', 'b/read'); NotActions = @(); DataActions = @(); NotDataActions = @() })
            Invoke-RoleAssignment -CustomRoles 1
            (Get-TableRow "$($script:Text.CustomRolesHeading) - Contoso-Prod")[0].($script:Text.Actions) | Should -Be 2
        }

        It 'Reports assignments and warns when custom roles cannot be read' {
            $script:FailCustomRoles = $true
            Invoke-RoleAssignment -Assignments 1 -CustomRoles 1
            $script:Warnings | Should -HaveCount 1
            $script:Warnings[0] | Should -BeLike '*Contoso-Prod*Access denied*'
            Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod" | Should -Not -BeNullOrEmpty
        }
    }

    # Rows are keyed by translated names, so a missing or duplicated key would only fail in that language
    Context 'Languages' {
        It 'Reports every table in <_>' -ForEach @('de-DE', 'en-GB', 'en-US', 'es-ES', 'fr-FR') {
            Invoke-RoleAssignment -Assignments 3 -CustomRoles 2 -Culture $_
            $script:Warnings | Should -BeNullOrEmpty
            (Get-TableRow "$($script:Text.AssignmentsHeading) - Contoso-Prod")[0].($script:Text.Role) | Should -Be 'Contributor'
            (Get-TableRow "$($script:Text.AssignmentDetailHeading) - Contoso-Prod") | Should -HaveCount 5
            (Get-TableRow "$($script:Text.CustomRolesHeading) - Contoso-Prod")[0].($script:Text.Name) | Should -Be 'VM Operator'
            (Get-TableRow "$($script:Text.CustomRoleTableHeading) - VM Operator")[0].($script:Text.Actions) | Should -Match 'start/action'
        }
    }
}
