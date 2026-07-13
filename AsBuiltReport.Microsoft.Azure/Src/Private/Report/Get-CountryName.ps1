function Get-CountryName {
    <#
    .SYNOPSIS
        Resolves an ISO 3166-1 alpha-2 country code to a localised country name.
    .DESCRIPTION
        Accepts a two-letter ISO 3166-1 alpha-2 country code and returns the corresponding
        country name from the active report localisation data. Input is normalised to
        uppercase before lookup. Returns a localised "not found" message if the code is
        not present in the lookup table.
    .PARAMETER CountryCode
        ISO 3166-1 alpha-2 country code (e.g. 'US', 'GB', 'DE'). Case-insensitive.
    .EXAMPLE
        Get-CountryName -CountryCode 'AU'
    .NOTES
        Version:    0.1.0
        Author:     Tim Carman
        Github:     tpcarman
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CountryCode
    )

    # Translation data
    $LocalizedData = $reportTranslate.GetCountryName

    # Define a hashtable of country codes and names
    $CountryLookup = @{
        AF = $LocalizedData.AF
        AX = $LocalizedData.AX
        AL = $LocalizedData.AL
        DZ = $LocalizedData.DZ
        AS = $LocalizedData.AS
        AD = $LocalizedData.AD
        AO = $LocalizedData.AO
        AQ = $LocalizedData.AQ
        AG = $LocalizedData.AG
        AR = $LocalizedData.AR
        AM = $LocalizedData.AM
        AW = $LocalizedData.AW
        AU = $LocalizedData.AU
        AT = $LocalizedData.AT
        AZ = $LocalizedData.AZ
        BS = $LocalizedData.BS
        BH = $LocalizedData.BH
        BD = $LocalizedData.BD
        BB = $LocalizedData.BB
        BY = $LocalizedData.BY
        BE = $LocalizedData.BE
        BZ = $LocalizedData.BZ
        BJ = $LocalizedData.BJ
        BM = $LocalizedData.BM
        BT = $LocalizedData.BT
        BO = $LocalizedData.BO
        BQ = $LocalizedData.BQ
        BA = $LocalizedData.BA
        BW = $LocalizedData.BW
        BV = $LocalizedData.BV
        BR = $LocalizedData.BR
        IO = $LocalizedData.IO
        VG = $LocalizedData.VG
        BN = $LocalizedData.BN
        BG = $LocalizedData.BG
        BF = $LocalizedData.BF
        BI = $LocalizedData.BI
        CV = $LocalizedData.CV
        KH = $LocalizedData.KH
        CM = $LocalizedData.CM
        CA = $LocalizedData.CA
        KY = $LocalizedData.KY
        CF = $LocalizedData.CF
        TD = $LocalizedData.TD
        CZ = $LocalizedData.CZ
        CL = $LocalizedData.CL
        CN = $LocalizedData.CN
        CX = $LocalizedData.CX
        CC = $LocalizedData.CC
        CO = $LocalizedData.CO
        KM = $LocalizedData.KM
        CG = $LocalizedData.CG
        CD = $LocalizedData.CD
        CK = $LocalizedData.CK
        CR = $LocalizedData.CR
        CI = $LocalizedData.CI
        HR = $LocalizedData.HR
        CU = $LocalizedData.CU
        CW = $LocalizedData.CW
        CY = $LocalizedData.CY
        DK = $LocalizedData.DK
        DJ = $LocalizedData.DJ
        DM = $LocalizedData.DM
        DO = $LocalizedData.DO
        EC = $LocalizedData.EC
        EG = $LocalizedData.EG
        SV = $LocalizedData.SV
        GQ = $LocalizedData.GQ
        ER = $LocalizedData.ER
        EE = $LocalizedData.EE
        SZ = $LocalizedData.SZ
        ET = $LocalizedData.ET
        FO = $LocalizedData.FO
        FJ = $LocalizedData.FJ
        FI = $LocalizedData.FI
        FR = $LocalizedData.FR
        GF = $LocalizedData.GF
        PF = $LocalizedData.PF
        TF = $LocalizedData.TF
        GA = $LocalizedData.GA
        GM = $LocalizedData.GM
        GE = $LocalizedData.GE
        DE = $LocalizedData.DE
        GH = $LocalizedData.GH
        GI = $LocalizedData.GI
        GR = $LocalizedData.GR
        GL = $LocalizedData.GL
        GD = $LocalizedData.GD
        GP = $LocalizedData.GP
        GU = $LocalizedData.GU
        GT = $LocalizedData.GT
        GG = $LocalizedData.GG
        GN = $LocalizedData.GN
        GW = $LocalizedData.GW
        GY = $LocalizedData.GY
        HT = $LocalizedData.HT
        HM = $LocalizedData.HM
        HN = $LocalizedData.HN
        HK = $LocalizedData.HK
        HU = $LocalizedData.HU
        IS = $LocalizedData.IS
        IN = $LocalizedData.IN
        ID = $LocalizedData.ID
        IR = $LocalizedData.IR
        IQ = $LocalizedData.IQ
        IE = $LocalizedData.IE
        IM = $LocalizedData.IM
        IL = $LocalizedData.IL
        IT = $LocalizedData.IT
        JM = $LocalizedData.JM
        JP = $LocalizedData.JP
        JE = $LocalizedData.JE
        JO = $LocalizedData.JO
        KZ = $LocalizedData.KZ
        KE = $LocalizedData.KE
        KI = $LocalizedData.KI
        KR = $LocalizedData.KR
        KW = $LocalizedData.KW
        KG = $LocalizedData.KG
        LA = $LocalizedData.LA
        LV = $LocalizedData.LV
        LB = $LocalizedData.LB
        LS = $LocalizedData.LS
        LR = $LocalizedData.LR
        LY = $LocalizedData.LY
        LI = $LocalizedData.LI
        LT = $LocalizedData.LT
        LU = $LocalizedData.LU
        MO = $LocalizedData.MO
        MG = $LocalizedData.MG
        MW = $LocalizedData.MW
        MY = $LocalizedData.MY
        MV = $LocalizedData.MV
        ML = $LocalizedData.ML
        MT = $LocalizedData.MT
        MH = $LocalizedData.MH
        MQ = $LocalizedData.MQ
        MR = $LocalizedData.MR
        MU = $LocalizedData.MU
        YT = $LocalizedData.YT
        MX = $LocalizedData.MX
        FM = $LocalizedData.FM
        MD = $LocalizedData.MD
        MC = $LocalizedData.MC
        MN = $LocalizedData.MN
        ME = $LocalizedData.ME
        MS = $LocalizedData.MS
        MA = $LocalizedData.MA
        MZ = $LocalizedData.MZ
        MM = $LocalizedData.MM
        NA = $LocalizedData.NA
        NR = $LocalizedData.NR
        NP = $LocalizedData.NP
        NL = $LocalizedData.NL
        NC = $LocalizedData.NC
        NZ = $LocalizedData.NZ
        NI = $LocalizedData.NI
        NE = $LocalizedData.NE
        NG = $LocalizedData.NG
        NU = $LocalizedData.NU
        NF = $LocalizedData.NF
        KP = $LocalizedData.KP
        MP = $LocalizedData.MP
        MK = $LocalizedData.MK
        NO = $LocalizedData.NO
        OM = $LocalizedData.OM
        PK = $LocalizedData.PK
        PW = $LocalizedData.PW
        PS = $LocalizedData.PS
        PA = $LocalizedData.PA
        PG = $LocalizedData.PG
        PY = $LocalizedData.PY
        PE = $LocalizedData.PE
        PH = $LocalizedData.PH
        PN = $LocalizedData.PN
        PL = $LocalizedData.PL
        PT = $LocalizedData.PT
        PR = $LocalizedData.PR
        QA = $LocalizedData.QA
        RE = $LocalizedData.RE
        RO = $LocalizedData.RO
        RU = $LocalizedData.RU
        RW = $LocalizedData.RW
        BL = $LocalizedData.BL
        KN = $LocalizedData.KN
        LC = $LocalizedData.LC
        MF = $LocalizedData.MF
        PM = $LocalizedData.PM
        VC = $LocalizedData.VC
        WS = $LocalizedData.WS
        SM = $LocalizedData.SM
        ST = $LocalizedData.ST
        SA = $LocalizedData.SA
        SN = $LocalizedData.SN
        RS = $LocalizedData.RS
        SC = $LocalizedData.SC
        SL = $LocalizedData.SL
        SG = $LocalizedData.SG
        SX = $LocalizedData.SX
        SK = $LocalizedData.SK
        SI = $LocalizedData.SI
        SB = $LocalizedData.SB
        SO = $LocalizedData.SO
        ZA = $LocalizedData.ZA
        GS = $LocalizedData.GS
        SS = $LocalizedData.SS
        ES = $LocalizedData.ES
        LK = $LocalizedData.LK
        SH = $LocalizedData.SH
        SD = $LocalizedData.SD
        SR = $LocalizedData.SR
        SJ = $LocalizedData.SJ
        SE = $LocalizedData.SE
        CH = $LocalizedData.CH
        SY = $LocalizedData.SY
        TW = $LocalizedData.TW
        TJ = $LocalizedData.TJ
        TZ = $LocalizedData.TZ
        TH = $LocalizedData.TH
        TL = $LocalizedData.TL
        TG = $LocalizedData.TG
        TK = $LocalizedData.TK
        TO = $LocalizedData.TO
        TT = $LocalizedData.TT
        TN = $LocalizedData.TN
        TR = $LocalizedData.TR
        TM = $LocalizedData.TM
        TC = $LocalizedData.TC
        TV = $LocalizedData.TV
        UG = $LocalizedData.UG
        UA = $LocalizedData.UA
        AE = $LocalizedData.AE
        GB = $LocalizedData.GB
        US = $LocalizedData.US
        UY = $LocalizedData.UY
        UM = $LocalizedData.UM
        VI = $LocalizedData.VI
        UZ = $LocalizedData.UZ
        VU = $LocalizedData.VU
        VA = $LocalizedData.VA
        VE = $LocalizedData.VE
        VN = $LocalizedData.VN
        WF = $LocalizedData.WF
        YE = $LocalizedData.YE
        ZM = $LocalizedData.ZM
        ZW = $LocalizedData.ZW
    }

    # Convert input to uppercase to handle case insensitivity
    $CountryCode = $CountryCode.ToUpper()

    # Lookup the country name or return a default message if not found
    if ($CountryLookup.ContainsKey($CountryCode)) {
        return $CountryLookup[$CountryCode]
    } else {
        if ($LocalizedData) {
            return ($LocalizedData.CodeNotFound -f $CountryCode)
        } else {
            return ("Country code '{0}' not found." -f $CountryCode)
        }
    }
}