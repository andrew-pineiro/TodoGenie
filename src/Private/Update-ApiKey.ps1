function Update-ApiKey {
    [CmdletBinding()]
    param (
        [string] $NewKey
    )
    $EncryptedKey = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($NewKey))
    $JsonData = @{
        "GithubApiKey" = $EncryptedKey
    } | ConvertTo-Json
    if(-not(Test-Path $secretsFileFullPath)) {
        New-Item $secretsFileFullPath > $null
    }
    Set-Content $secretsFileFullPath $JsonData
}