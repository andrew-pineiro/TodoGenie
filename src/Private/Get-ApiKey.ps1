function Get-ApiKey() {
    $jsonData = Get-content ($secretsPath + $directorySeparator + $secretsFile) | ConvertFrom-Json
    if(($jsonData).GithubApiKey) {
        return [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(($jsonData).GithubApiKey))
    }
    Write-Error "invalid apiKey or apiKey not found. $jsonData"
    break 1
}