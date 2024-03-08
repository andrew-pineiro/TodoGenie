function Get-ApiKey() {
    $jsonData = Get-content ($secretsPath + $directorySeparator + $secretsFile) | ConvertFrom-Json
    if(($jsonData).GithubApiKey) {
        return [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(($jsonData).GithubApiKey))
    } else {
        Write-Error "invalid apiKey or apiKey not found."
        break 1
    }
}