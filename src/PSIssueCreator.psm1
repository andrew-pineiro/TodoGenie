"$(Split-Path -Path $MyInvocation.MyCommand.Path)\Public\*.ps1" | 
    Resolve-Path | ForEach-Object { . $_.ProviderPath }