# Scans the report functions for a bug that is invisible when testing in English (see issue #34).
#
# Table rows are built with translated property names, such as "Nombre" in es-ES and "Nom" in fr-FR.
# Reading one with a hardcoded name, such as $Row.Name, only works in languages where the label is "Name".
# Everywhere else the name is empty, PScribo rejects the section heading, and the section is lost.
#
# This reads the code without running it, so it covers every function, including new ones.
# It checks foreach loops over row variables. A less direct read could still be missed.
#
# Run from the repository root: Invoke-Pester -Path .\Tests\TranslatedReportRows.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'AsBuiltReport.Microsoft.Azure'
    $script:ReportPath = Join-Path -Path (Join-Path -Path (Join-Path -Path $ModulePath -ChildPath 'Src') -ChildPath 'Private') -ChildPath 'Report'

    # Finds the variables that hold table rows built by [PSCustomObject]$InObj, including copies of them.
    # The properties of these rows are named after translated labels, so they differ by language.
    function Get-TranslatedRowVariable {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $Assignments = $Ast.FindAll({
                param ($Node)
                $Node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $Node.Left -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        $RowVariables = @{}
        foreach ($Assignment in $Assignments) {
            if ($Assignment.Right.Extent.Text -match '\[PSCustomObject\]\s*\$\w+') {
                $RowVariables[$Assignment.Left.VariablePath.UserPath] = $true
            }
        }

        do {
            $Added = $false
            foreach ($Assignment in $Assignments) {
                $Name = $Assignment.Left.VariablePath.UserPath
                if ($RowVariables.ContainsKey($Name)) { continue }
                $Sources = [regex]::Matches($Assignment.Right.Extent.Text, '\$(\w+)') | ForEach-Object { $_.Groups[1].Value }
                if ($Sources | Where-Object { $RowVariables.ContainsKey($_) }) {
                    $RowVariables[$Name] = $true
                    $Added = $true
                }
            }
        } while ($Added)

        return $RowVariables
    }

    # Finds $Row.Property, where $Row is a loop variable over translated rows and Property is hardcoded
    function Get-HardcodedRowProperty {
        param ([System.IO.FileInfo] $File)

        $Tokens = $null
        $ParseErrors = $null
        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref] $Tokens, [ref] $ParseErrors)
        $RowVariables = Get-TranslatedRowVariable -Ast $Ast

        $Loops = $Ast.FindAll({ param ($Node) $Node -is [System.Management.Automation.Language.ForEachStatementAst] }, $true)
        foreach ($Loop in $Loops) {
            $Sources = [regex]::Matches($Loop.Condition.Extent.Text, '\$(\w+)') | ForEach-Object { $_.Groups[1].Value }
            if (-not ($Sources | Where-Object { $RowVariables.ContainsKey($_) })) { continue }

            $LoopVariable = $Loop.Variable.VariablePath.UserPath
            $Members = $Loop.Body.FindAll({ param ($Node) $Node -is [System.Management.Automation.Language.MemberExpressionAst] }, $true)
            foreach ($Member in $Members) {
                if ($Member.Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
                    $Member.Expression.VariablePath.UserPath -eq $LoopVariable -and
                    $Member.Member -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    "$($File.Name):$($Member.Extent.StartLineNumber) reads $($Member.Extent.Text)"
                }
            }
        }
    }
}

Describe 'Translated report rows' {
    # Guards the scan itself: if it stopped recognising row variables, the next test would pass without checking anything.
    It 'Finds translated rows to check' {
        $RowFiles = foreach ($File in (Get-ChildItem -Path $script:ReportPath -Filter '*.ps1')) {
            $Tokens = $null
            $ParseErrors = $null
            $Ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref] $Tokens, [ref] $ParseErrors)
            if ((Get-TranslatedRowVariable -Ast $Ast).Count -gt 0) { $File.Name }
        }
        @($RowFiles).Count | Should -BeGreaterThan 0
    }

    It 'Reads row properties through $LocalizedData, because hardcoded names only exist in some languages' {
        $Findings = foreach ($File in (Get-ChildItem -Path $script:ReportPath -Filter '*.ps1')) {
            Get-HardcodedRowProperty -File $File
        }
        @($Findings).Count | Should -Be 0 -Because ("use `$Row.(`$LocalizedData.Name) instead:`n" + ($Findings -join "`n"))
    }
}
