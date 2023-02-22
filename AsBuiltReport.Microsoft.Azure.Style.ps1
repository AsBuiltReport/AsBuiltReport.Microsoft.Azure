# Microsoft Default Document Style

# Configure document options
DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Segoe Ui' -MarginLeftAndRight 71 -MarginTopAndBottom 71 -Orientation $Orientation

# Configure Heading and Font Styles
Style -Name 'Title' -Size 24 -Color '0078D4' -Align Center
Style -Name 'Title 2' -Size 18 -Color '00447C' -Align Center
Style -Name 'Title 3' -Size 12 -Color '1F6BCF' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '0078D4'
Style -Name 'Heading 2' -Size 14 -Color '00447C'
Style -Name 'Heading 3' -Size 13 -Color '0081FF'
Style -Name 'Heading 4' -Size 12 -Color '0077B7'
Style -Name 'Heading 5' -Size 11 -Color '1A9BA3'
Style -Name 'NO TOC Heading 5' -Size 11 -Color '1A9BA3'
Style -Name 'Heading 6' -Size 10 -Color '505050'
Style -Name 'NO TOC Heading 6' -Size 10 -Color '505050'
Style -Name 'NO TOC Heading 7' -Size 10 -Color '551A4C' -Italic
Style -Name 'Normal' -Size 10 -Color '565656' -Default
Style -Name 'Caption' -Size 10 -Color '565656' -Italic -Align Center
Style -Name 'Header' -Size 10 -Color '565656' -Align Center
Style -Name 'Footer' -Size 10 -Color '565656' -Align Center
Style -Name 'TOC' -Size 16 -Color '1F6BCF'
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FAFAFA' -BackgroundColor '0078D4'
Style -Name 'TableDefaultRow' -Size 10 -Color '565656'
Style -Name 'Critical' -Size 10 -BackgroundColor 'E81123' -Color 'FAFAFA'
Style -Name 'Warning' -Size 10 -BackgroundColor 'FCD116'
Style -Name 'Info' -Size 10 -BackgroundColor '0072C6'
Style -Name 'OK' -Size 10 -BackgroundColor '7FBA00'

# Configure Table Styles
$TableDefaultProperties = @{
    Id = 'TableDefault'
    HeaderStyle = 'TableDefaultHeading'
    RowStyle = 'TableDefaultRow'
    BorderColor = '0078D4'
    Align = 'Left'
    CaptionStyle = 'Caption'
    CaptionLocation = 'Below'
    BorderWidth = 0.25
    PaddingTop = 1
    PaddingBottom = 1.5
    PaddingLeft = 2
    PaddingRight = 2
}

TableStyle @TableDefaultProperties -Default
TableStyle -Id 'Borderless' -HeaderStyle Normal -RowStyle Normal -BorderWidth 0

# Microsoft AD Cover Page Layout
# Header & Footer
if ($ReportConfig.Report.ShowHeaderFooter) {
    Header -Default {
        Paragraph -Style Header "$($ReportConfig.Report.Name) - v$($ReportConfig.Report.Version)"
    }

    Footer -Default {
        Paragraph -Style Footer 'Page <!# PageNumber #!>'
    }
}

# Set position of report titles and information based on page orientation
if (!($ReportConfig.Report.ShowCoverPageImage)) {
    $LineCount = 5
}
if ($Orientation -eq 'Portrait') {
    BlankLine -Count 11
    $LineCount = 30 + $LineCount
} else {
    BlankLine -Count 7
    $LineCount = 15 + $LineCount
}

<#
# Microsoft Logo Image
# The use of Microsoft logos require a license - https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks
if ($ReportConfig.Report.ShowCoverPageImage) {
    Try {
        Image -Text 'Microsoft Logo' -Align 'Center' -Percent 20 -Base64 ""
    } Catch {
        Write-PScriboMessage -Message "Unable to display cover page logo. Please set 'ShowCoverPageImage' to 'false' in the report JSON configuration file to avoid this error."
    }
}
#>

# Add Report Name
Paragraph -Style Title $ReportConfig.Report.Name

if ($AsBuiltConfig.Company.FullName) {
    # Add Company Name if specified
    BlankLine -Count 2
    Paragraph -Style Title2 $AsBuiltConfig.Company.FullName
    BlankLine -Count $LineCount
} else {
    BlankLine -Count ($LineCount + 1)
}
Table -Name 'Cover Page' -List -Style Borderless -Width 0 -Hashtable ([Ordered] @{
        'Author:' = $AsBuiltConfig.Report.Author
        'Date:' = (Get-Date).ToLongDateString()
        'Version:' = $ReportConfig.Report.Version
    })
PageBreak

if ($ReportConfig.Report.ShowTableOfContents) {
    # Add Table of Contents
    TOC -Name 'Table of Contents'
    PageBreak
}