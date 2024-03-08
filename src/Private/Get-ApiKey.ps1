function Get-ApiKey() {
    Write-Host "Attempting to get key from $($secretsPath + $directorySeparator + $secretsFile)"
    $jsonData = Get-content $($secretsPath + $directorySeparator + $secretsFile) | ConvertFrom-Json
    Write-Host "$(($jsonData).GithubApiKey)"
    if(($jsonData).GithubApiKey) {
        return [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(($jsonData).GithubApiKey))
    } else {
        Write-Error "invalid apiKey or apiKey not found."
        break 1
    }
}