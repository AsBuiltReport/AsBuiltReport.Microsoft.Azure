# Behaviour tests for Get-AbrAzSubscription, which run the real function with no Azure connection.
#
# PScribo and Az commands are replaced with stubs: simple functions that return test data and record what
# the function reported. Stubs are used rather than Pester's Mock because Mock needs the command to exist,
# and the Az modules are not installed in CI.
#
# Stubs only reflect what we expect Azure to return, so these tests do not replace a run against a live tenant.
# The lock stubs follow the Az source, where LockId and ResourceId both hold the lock's own path.
#
# Run from the repository root: Invoke-Pester -Path .\Tests\Get-AbrAzSubscription.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'AsBuiltReport.Microsoft.Azure'
    $script:LanguagePath = Join-Path -Path $ModulePath -ChildPath 'Language'
    . (Join-Path -Path $ModulePath -ChildPath 'Src/Private/Report/Get-AbrAzSubscription.ps1')

    function New-TestSubscription {
        param ([string] $Name)
        [PSCustomObject]@{ Name = $Name; Id = $Name; SubscriptionId = $Name; State = 'Enabled' }
    }

    function New-TestResource {
        param ([hashtable] $Tags)
        [PSCustomObject]@{ Tags = $Tags }
    }

    function New-TestLock {
        param ([string] $Name, [string] $Scope, [string] $Level = 'CanNotDelete', [string] $Notes)
        $LockId = "$Scope/providers/Microsoft.Authorization/locks/$Name"
        [PSCustomObject]@{
            Name       = $Name
            ResourceId = $LockId
            LockId     = $LockId
            Properties = [PSCustomObject]@{ Level = $Level; Notes = $Notes }
        }
    }

    # PScribo stubs. Section rejects an empty name, as PScribo does.
    function Section {
        param (
            [string] $Style,
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
        if ($IsWarning) { $script:Warnings += $Message }
    }

    # Az stubs. Each returns the test data for the subscription most recently selected by Set-AzContext.
    function Set-AzContext {
        [CmdletBinding()]
        param ([string] $Subscription, [string] $Tenant)
        $script:ContextChanges += $Subscription
        $script:CurrentSubscription = $Subscription
    }
    function Get-AzResourceGroup {
        [CmdletBinding()]
        param ()
        if ($script:FailingSubscription -eq $script:CurrentSubscription) { throw 'Access denied' }
        $script:ResourceGroups[$script:CurrentSubscription]
    }
    function Get-AzResource {
        [CmdletBinding()]
        param ()
        $script:Resources[$script:CurrentSubscription]
    }
    function Get-AzResourceLock {
        [CmdletBinding()]
        param ()
        $script:Locks[$script:CurrentSubscription]
    }

    function Invoke-Subscription {
        param ([int] $Level, [string] $Culture = 'en-US', [object] $TagCoverageLimit)
        $script:Headings = @()
        $script:Paragraphs = @()
        $script:TableRows = @()
        $script:Warnings = @()
        $script:ContextChanges = @()
        $InfoLevel = [PSCustomObject]@{ Subscription = $Level }
        $Report = [PSCustomObject]@{ ShowTableCaptions = $true }
        $Options = [PSCustomObject]@{ ShowSectionInfo = $false }
        if ($PSBoundParameters.ContainsKey('TagCoverageLimit')) {
            $Options | Add-Member -NotePropertyName TagCoverageLimit -NotePropertyValue $TagCoverageLimit
        }
        $AzTenant = [PSCustomObject]@{ Name = 'Contoso' }
        $TenantId = 'tenant-id'
        $AzSubscriptions = $script:Subscriptions
        Import-LocalizedData -BaseDirectory $script:LanguagePath -UICulture $Culture -FileName 'MicrosoftAzure.psd1' -BindingVariable reportTranslate
        $script:Text = $reportTranslate.GetAbrAzSubscription
        Get-AbrAzSubscription
    }

    # Returns the rows of one table. Table names start with the heading that was reported for them.
    function Get-TableRow {
        param ([string] $Heading)
        ($script:TableRows | Where-Object { $_.Table -like "$Heading - *" }).Row
    }
}

Describe 'Get-AbrAzSubscription' {
    BeforeEach {
        $script:FailingSubscription = $null
        $script:CurrentSubscription = $null
        $script:Subscriptions = @(New-TestSubscription 'Sub-B'; New-TestSubscription 'Sub-A')
        $script:ResourceGroups = @{
            'Sub-A' = @([PSCustomObject]@{ ResourceGroupName = 'rg-1' }, [PSCustomObject]@{ ResourceGroupName = 'rg-2' })
            'Sub-B' = @([PSCustomObject]@{ ResourceGroupName = 'rg-3' })
        }
        $script:Resources = @{
            'Sub-A' = @(
                New-TestResource @{ Environment = 'Prod'; Owner = 'Team A' }
                New-TestResource @{ Environment = 'Dev' }
                New-TestResource $null
                New-TestResource @{}
            )
            'Sub-B' = @(New-TestResource @{ environment = 'Test' })
        }
        $script:Locks = @{
            'Sub-A' = @(
                New-TestLock 'lock-sub' '/subscriptions/Sub-A'
                New-TestLock 'lock-rg' '/subscriptions/Sub-A/resourceGroups/rg-1' -Notes 'Protects the hub'
                New-TestLock 'lock-kv' '/subscriptions/Sub-A/resourceGroups/rg-1/providers/Microsoft.KeyVault/vaults/kv-1' -Level 'ReadOnly'
            )
            'Sub-B' = @()
        }
    }

    # Governance data needs every resource in every subscription, so InfoLevel 1 must not collect it.
    Context 'InfoLevels' {
        It 'InfoLevel 0 reports nothing' {
            Invoke-Subscription -Level 0
            $script:TableRows | Should -BeNullOrEmpty
        }

        It 'InfoLevel 1 reports only the subscription table, without switching subscription' {
            Invoke-Subscription -Level 1
            $script:Headings | Should -BeNullOrEmpty
            $script:TableRows.Row.($script:Text.Name) | Should -Be @('Sub-B', 'Sub-A')
            $script:ContextChanges | Should -BeNullOrEmpty
        }

        It 'InfoLevel 2 adds the governance summary and tag coverage, but not locks' {
            Invoke-Subscription -Level 2
            $script:Headings | Should -Be @($script:Text.GovernanceHeading, $script:Text.TagCoverageHeading)
        }

        It 'InfoLevel 3 adds the lock list' {
            Invoke-Subscription -Level 3
            $script:Headings | Should -Be @($script:Text.GovernanceHeading, $script:Text.TagCoverageHeading, $script:Text.LockHeading)
        }

        It 'Collects from each subscription in the filtered list' {
            Invoke-Subscription -Level 2
            $script:ContextChanges | Should -Be @('Sub-B', 'Sub-A')
        }
    }

    Context 'Governance summary' {
        It 'Reports the counts for each subscription, sorted by name' {
            Invoke-Subscription -Level 2
            $Rows = Get-TableRow $script:Text.GovernanceHeading
            $Rows.($script:Text.Subscription) | Should -Be @('Sub-A', 'Sub-B')
            $Rows[0].($script:Text.ResourceGroups) | Should -Be 2
            $Rows[0].($script:Text.Resources) | Should -Be 4
            $Rows[0].($script:Text.Locks) | Should -Be 3
            $Rows[1].($script:Text.Locks) | Should -Be 0
        }

        It 'Counts a resource with no tags or an empty tag list as untagged' {
            Invoke-Subscription -Level 2
            (Get-TableRow $script:Text.GovernanceHeading)[0].($script:Text.Tagged) | Should -Be '50%'
        }

        It 'Rounds down, so 100% always means every resource is tagged' {
            $script:Resources['Sub-A'] = @(1..199 | ForEach-Object { New-TestResource @{ Owner = 'Team' } }) + @(New-TestResource $null)
            Invoke-Subscription -Level 2
            (Get-TableRow $script:Text.GovernanceHeading)[0].($script:Text.Tagged) | Should -Be '99%'
        }

        It 'Shows -- for the percentage when a subscription has no resources' {
            $script:Resources['Sub-A'] = @()
            Invoke-Subscription -Level 2
            (Get-TableRow $script:Text.GovernanceHeading)[0].($script:Text.Tagged) | Should -Be '--'
        }

        # A count of 0 would wrongly tell the reader that a subscription has no locks
        It 'Shows -- and warns when a subscription cannot be read, and still reports the others' {
            $script:FailingSubscription = 'Sub-A'
            Invoke-Subscription -Level 3
            $Rows = Get-TableRow $script:Text.GovernanceHeading
            $Rows[0].($script:Text.ResourceGroups) | Should -Be '--'
            $Rows[0].($script:Text.Locks) | Should -Be '--'
            $Rows[1].($script:Text.Resources) | Should -Be 1
            $script:Warnings | Should -HaveCount 1
            $script:Warnings[0] | Should -BeLike '*Sub-A*Access denied*'
        }
    }

    Context 'Tag coverage' {
        It 'Counts across subscriptions, ignoring case, and sorts by most used' {
            Invoke-Subscription -Level 2
            $Rows = Get-TableRow $script:Text.TagCoverageHeading
            $Rows[0].($script:Text.Tag) | Should -Be 'Environment'
            $Rows[0].($script:Text.Resources) | Should -Be 3
            $Rows[0].($script:Text.Coverage) | Should -Be '60%'
            $Rows[1].($script:Text.Tag) | Should -Be 'Owner'
            $Rows[1].($script:Text.Coverage) | Should -Be '20%'
        }

        # On a hashtable, a key with the same name as a property hides that property
        It 'Handles tags named Count and Keys' {
            $script:Resources['Sub-A'] = @(New-TestResource @{ Count = '5'; Keys = 'abc' })
            $script:Resources['Sub-B'] = @()
            Invoke-Subscription -Level 2
            (Get-TableRow $script:Text.TagCoverageHeading).($script:Text.Tag) | Should -Be @('Count', 'Keys')
            (Get-TableRow $script:Text.GovernanceHeading)[0].($script:Text.Tagged) | Should -Be '100%'
        }

        It 'Does not list tag values' {
            Invoke-Subscription -Level 2
            $Values = (Get-TableRow $script:Text.TagCoverageHeading) | ForEach-Object { $_.PSObject.Properties.Value }
            $Values | Should -Not -Contain 'Prod'
        }

        # Existing report configuration files do not have the TagCoverageLimit option
        It 'Limits the table to the 10 most used names if the option is missing, and says when more exist' {
            $script:Resources['Sub-A'] = @(1..12 | ForEach-Object { New-TestResource @{ "Tag$_" = 'x' } })
            Invoke-Subscription -Level 2
            Get-TableRow $script:Text.TagCoverageHeading | Should -HaveCount 10
            $script:Paragraphs | Should -Contain ($script:Text.TagCoverageLimit -f 10, 13)
        }

        It 'Does not mention a limit at 10 names or fewer' {
            $script:Resources['Sub-A'] = @(1..9 | ForEach-Object { New-TestResource @{ "Tag$_" = 'x' } })
            Invoke-Subscription -Level 2
            Get-TableRow $script:Text.TagCoverageHeading | Should -HaveCount 10
            $script:Paragraphs | Should -Not -Contain ($script:Text.TagCoverageLimit -f 10, 10)
            $script:Paragraphs | Should -Contain ($script:Text.TagCoverageAll -f 10)
        }

        It 'Uses the configured limit, and says when more exist' {
            $script:Resources['Sub-A'] = @(1..12 | ForEach-Object { New-TestResource @{ "Tag$_" = 'x' } })
            Invoke-Subscription -Level 2 -TagCoverageLimit 5
            Get-TableRow $script:Text.TagCoverageHeading | Should -HaveCount 5
            $script:Paragraphs | Should -Contain ($script:Text.TagCoverageLimit -f 5, 13)
            $script:Paragraphs | Should -Not -Contain ($script:Text.TagCoverageAll -f 13)
            $script:Warnings | Should -BeNullOrEmpty
        }

        It 'Does not mention a limit when it is above the number of names' {
            $script:Resources['Sub-A'] = @(1..12 | ForEach-Object { New-TestResource @{ "Tag$_" = 'x' } })
            Invoke-Subscription -Level 2 -TagCoverageLimit 50
            Get-TableRow $script:Text.TagCoverageHeading | Should -HaveCount 13
            $script:Paragraphs | Should -Not -Contain ($script:Text.TagCoverageLimit -f 50, 13)
            $script:Paragraphs | Should -Contain ($script:Text.TagCoverageAll -f 13)
        }

        It 'Lists every name when the limit is *' {
            $script:Resources['Sub-A'] = @(1..30 | ForEach-Object { New-TestResource @{ "Tag$_" = 'x' } })
            Invoke-Subscription -Level 2 -TagCoverageLimit '*'
            Get-TableRow $script:Text.TagCoverageHeading | Should -HaveCount 31
            $script:Paragraphs | Should -Contain ($script:Text.TagCoverageAll -f 31)
            $script:Warnings | Should -BeNullOrEmpty
        }

        # An empty table or an error would lose the section because of a typing mistake in the configuration
        It 'Warns and uses 10 when the limit is <_>' -ForEach @(0, -1, 2.5, 'ten', '', '**') {
            $script:Resources['Sub-A'] = @(1..12 | ForEach-Object { New-TestResource @{ "Tag$_" = 'x' } })
            Invoke-Subscription -Level 2 -TagCoverageLimit $_
            Get-TableRow $script:Text.TagCoverageHeading | Should -HaveCount 10
            $script:Warnings | Should -HaveCount 1
            $script:Warnings[0] | Should -Be ($script:Text.TagCoverageLimitInvalid -f $_, 10)
        }

        It 'Reports no tag coverage section when nothing is tagged' {
            $script:Resources = @{ 'Sub-A' = @(New-TestResource $null); 'Sub-B' = @() }
            Invoke-Subscription -Level 2
            $script:Headings | Should -Not -Contain $script:Text.TagCoverageHeading
        }
    }

    Context 'Lock list' {
        It 'Derives the scope and target from the lock ID' {
            Invoke-Subscription -Level 3
            $Rows = @{}
            foreach ($Row in (Get-TableRow $script:Text.LockHeading)) { $Rows[$Row.($script:Text.Name)] = $Row }
            $Rows['lock-sub'].($script:Text.Scope) | Should -Be $script:Text.Subscription
            $Rows['lock-sub'].($script:Text.AppliesTo) | Should -Be 'Sub-A'
            $Rows['lock-rg'].($script:Text.Scope) | Should -Be $script:Text.ResourceGroup
            $Rows['lock-rg'].($script:Text.AppliesTo) | Should -Be 'rg-1'
            $Rows['lock-kv'].($script:Text.Scope) | Should -Be $script:Text.Resource
            $Rows['lock-kv'].($script:Text.AppliesTo) | Should -Be 'kv-1'
        }

        It 'Reports the columns in the agreed order' {
            Invoke-Subscription -Level 3
            (Get-TableRow $script:Text.LockHeading)[0].PSObject.Properties.Name | Should -Be @(
                $script:Text.Subscription, $script:Text.Name, $script:Text.Type, $script:Text.Scope, $script:Text.AppliesTo, $script:Text.Notes
            )
        }

        It 'Uses the portal names for lock types' {
            Invoke-Subscription -Level 3
            $Rows = @{}
            foreach ($Row in (Get-TableRow $script:Text.LockHeading)) { $Rows[$Row.Name] = $Row }
            $Rows['lock-rg'].Type | Should -Be 'Delete'
            $Rows['lock-kv'].Type | Should -Be 'Read-Only'
        }

        # A value the switch does not map must still be reported, rather than leaving the cell empty
        It 'Shows any other lock level as Azure returns it' {
            $script:Locks['Sub-B'] = @(New-TestLock 'lock-new' '/subscriptions/Sub-B' -Level 'NotSpecified')
            Invoke-Subscription -Level 3
            $Row = Get-TableRow $script:Text.LockHeading | Where-Object { $_.($script:Text.Name) -eq 'lock-new' }
            $Row.($script:Text.Type) | Should -Be 'NotSpecified'
        }

        It 'Reports the type and notes, showing -- when there are no notes' {
            Invoke-Subscription -Level 3
            $Rows = @{}
            foreach ($Row in (Get-TableRow $script:Text.LockHeading)) { $Rows[$Row.($script:Text.Name)] = $Row }
            $Rows['lock-kv'].($script:Text.Type) | Should -Be $script:Text.LockTypeReadOnly
            $Rows['lock-rg'].($script:Text.Type) | Should -Be $script:Text.LockTypeDelete
            $Rows['lock-kv'].($script:Text.Notes) | Should -Be '--'
            $Rows['lock-rg'].($script:Text.Notes) | Should -Be 'Protects the hub'
        }

        It 'Lists a lock returned twice only once' {
            $script:Locks['Sub-B'] = @($script:Locks['Sub-A'][0])
            Invoke-Subscription -Level 3
            Get-TableRow $script:Text.LockHeading | Should -HaveCount 3
        }

        It 'Reports no lock section when there are no locks' {
            $script:Locks = @{ 'Sub-A' = @(); 'Sub-B' = @() }
            Invoke-Subscription -Level 3
            $script:Headings | Should -Not -Contain $script:Text.LockHeading
        }
    }

    # Rows are keyed by translated names, so a missing or duplicated key would only fail in that language
    Context 'Languages' {
        It 'Reports every table in <_>' -ForEach @('de-DE', 'en-GB', 'en-US', 'es-ES', 'fr-FR') {
            Invoke-Subscription -Level 3 -Culture $_
            $script:Warnings | Should -BeNullOrEmpty
            $script:Headings | Should -HaveCount 3
            (Get-TableRow $script:Text.LockHeading).($script:Text.Name) | Should -Contain 'lock-kv'
            (Get-TableRow $script:Text.TagCoverageHeading)[0].($script:Text.Tag) | Should -Be 'Environment'
        }
    }
}
