# Microsoft Default Document Style

# Configure document options
DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Arial' -MarginLeftAndRight 71 -MarginTopAndBottom 71 -Orientation $Orientation

# Configure Heading and Font Styles
Style -Name 'Title' -Size 24 -Color '0076CE' -Align Center
Style -Name 'Title 2' -Size 18 -Color '00447C' -Align Center
Style -Name 'Title 3' -Size 12 -Color '00447C' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '00447C'
Style -Name 'Heading 2' -Size 14 -Color '00447C'
Style -Name 'Heading 3' -Size 12 -Color '00447C'
Style -Name 'Heading 4' -Size 11 -Color '00447C'
Style -Name 'Heading 5' -Size 11 -Color '00447C'
Style -Name 'Heading 6' -Size 11 -Color '00447C'
Style -Name 'Normal' -Size 10 -Color '565656' -Default
Style -Name 'Caption' -Size 10 -Color '565656' -Italic -Align Center
Style -Name 'Header' -Size 10 -Color '565656' -Align Center
Style -Name 'Footer' -Size 10 -Color '565656' -Align Center
Style -Name 'TOC' -Size 16 -Color '00447C'
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FAFAFA' -BackgroundColor '0076CE'
Style -Name 'TableDefaultRow' -Size 10 -Color '565656'
Style -Name 'Critical' -Size 10 -BackgroundColor 'F25022'
Style -Name 'Warning' -Size 10 -BackgroundColor 'FFB900'
Style -Name 'Info' -Size 10 -BackgroundColor '00447C'
Style -Name 'OK' -Size 10 -BackgroundColor '7FBA00'

# Configure Table Styles
$TableDefaultProperties = @{
    Id = 'TableDefault'
    HeaderStyle = 'TableDefaultHeading'
    RowStyle = 'TableDefaultRow'
    BorderColor = '0076CE'
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
    $LineCount = 32 + $LineCount
} else {
    BlankLine -Count 7
    $LineCount = 15 + $LineCount
}

# Microsoft Logo Image
if ($ReportConfig.Report.ShowCoverPageImage) {
    Try {
        Image -Text 'Microsoft Logo' -Align 'Center' -Percent 20 -Base64 "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"
        BlankLine -Count 2
    } Catch {
        Write-PScriboMessage -Message ".NET Core is required for cover page image support. Please install .NET Core or disable 'ShowCoverPageImage' in the report JSON configuration file."
    }
}

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