#
# Module manifest for module 'AsBuiltReport.Microsoft.Azure'
#
# Generated by: Tim Carman
#
# Generated on: 8/08/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'AsBuiltReport.Microsoft.Azure.psm1'

# Version number of this module.
ModuleVersion = '0.1.8.2'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '9be3285b-e0df-4744-96d7-903fac96f457'

# Author of this module
Author = 'Tim Carman'

# Company or vendor of this module
# CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2024 Tim Carman. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A PowerShell module to generate an as built report on the configuration of Microsoft Azure.'

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
        @{
            ModuleName = 'AsBuiltReport.Core';
            ModuleVersion = '1.4.0'
        }
    )

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Invoke-AsBuiltReport.Microsoft.Azure')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'AsBuiltReport', 'Report', 'Microsoft', 'Azure', 'Documentation', 'PScribo', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'MacOS', 'Linux'

        # A URL to the license for this module.
        LicenseUri = 'https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/AsBuiltReport.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/master/CHANGELOG.md'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        ExternalModuleDependencies = @('AsBuiltReport.Core')

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}


