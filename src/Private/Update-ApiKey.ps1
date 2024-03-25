function Update-ApiKey {
    [CmdletBinding()]
    param (
        [string] $newKey
    )
    $encryptedKey = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($newKey))
    $jsonData = @{
        "GithubApiKey" = $encryptedKey
    } | ConvertTo-Json
    if(-not(Test-Path $SecretsFileFullPath)) {
        New-Item $SecretsFileFullPath > $null
    }
    Set-Content $SecretsFileFullPath $jsonData
}