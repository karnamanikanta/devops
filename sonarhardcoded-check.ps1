Write-Host "Scanning for Hardcoded sensitive data..." 
 
# Define extended patterns for sensitive info
$patterns = @{
    # 'Card Number'   = '"\d{16}"'
    'Card Number'   = '^(?!.*GPAY_LOWER_TESTING_CARD).*"\d{16}"'
    'CVV'           = '\b(CVV|cvv|cvc|CVC)[\s:=]*["'']?\d{3,4}["'']?'
    'ExpiryDate'    = '\b(0[1-9]|1[0-2])\/((\d{4})|(\d{2}))\b(?!\/\d)'
    'ZIP Code'      = "^\\d{5}$"
    'First Name'    = 'this\.firstName\s*=\s*["''][A-Z][a-zA-Z]*["'']'
    'Last Name'     = 'this\.lastName\s*=\s*["''][A-Z][a-zA-Z]*(?:[-''][A-Z][a-zA-Z]*)?["'']'
    'Email'         = '\b(?!help@doordash\.com\b)[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.(com|net|org|edu|gov|mil|info|biz|io|co|in|uk|us|de|jp|fr|au|ca)\b'
    # 'StoreID'       =  '\bstoreid\s*=\s*["'](?!n/a["'])[A-Za-z0-9 _\-]+["']'
    'StoreID'       = '\\bstoreid\\s*=\\s*["''](?!n/a["''])[A-Za-z0-9 _\\-]+["'']'
    'STORE_NUMBER'  = "^\\d{3,5}-(0|1)$"
    'Location ID'   = '\b(loc(Id|ationID)?)\s*=\s*["'']?\d+["'']?'
    # 'User Country'  = '\b(userCountry|country)\s*=\s*(?!["'](?:country)?["'])["']?[A-Za-z ]+["']'
    'User Country'  = '\\b(userCountry|country)\\s*=\\s*(?!["''](?:country)?["''])["'']?[A-Za-z \\]+["'']' 

}
# Collect only relevant files:
# - Include .java, .kt, .json (all)
# - Include .swift ONLY if not under /SUBWAY®UITests/ or /SubwayTests/
$files = @()

# Non-swift files
$files = Get-ChildItem -Recurse -Include *.java,*.kt -File | Where-Object {
    $_.FullName -notmatch '\\test\\|\\tests\\|Test\.|Tests\.'
}
# Include swift files excluding SUBWAY®UITests and SubwayTests
$swiftFiles = Get-ChildItem -Recurse -Include *.swift -File | Where-Object {
    $_.FullName -notlike "*/Subway/SUBWAY®UITests/*" -and $_.FullName -notlike "*/Subway/SubwayTests/*"
}
$files += $swiftFiles

$found = $false
$summary = @{}
 
foreach ($file in $files) {
    $lines = Get-Content $file.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        foreach ($label in $patterns.Keys) {
            if ($line -match $patterns[$label]) {
                Write-Host "`n[WARNING] Potential $label in:"
                Write-Host "File: $($file.FullName)"
                Write-Host "Line $($i + 1): $line"
                if (-not $summary.ContainsKey($label)) {
                    $summary[$label] = 0
                }
                $summary[$label]++
                $found = $true
            }
        }
    }
}

# ANSI Color Codes
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Magenta = "`e[35m"
$Cyan = "`e[36m"
$White = "`e[37m"
$Bold = "`e[1m"
$Reset = "`e[0m"

if ($summary.Count -gt 0) {
    Write-Host "${Yellow}${Bold}================ Summary of Sensitive Hardcoded Values ===============${Reset}"
    Write-Host "${Cyan}| Sensitive Label                  | Occurrences ${Reset}"
    Write-Host "${Cyan}-------------------------------------------------------------${Reset}"
    
    foreach ($label in $summary.Keys) {
        $count = $summary[$label]
        $formattedLine = "{0,-28} | {1,-13}" -f $label, $count
        Write-Host "${Green}$formattedLine${Reset}"
    }
    
    Write-Host "${Cyan}-------------------------------------------------------------${Reset}"
    Write-Host "${Red}${Bold}[ERROR] Hardcoded sensitive data found!${Reset}"
    # exit 1
} else {
    Write-Host "${Green}${Bold}No hardcoded sensitive values found!${Reset}"
    exit 0
}
