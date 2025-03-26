function Get-ApiKey() {
    Write-Debug "Attempting to get ApiKey..."
    Write-Debug "Secret file [$SecretsFile] from path: $SecretsPath"
    $jsonData = Get-content $SecretsFileFullPath | ConvertFrom-Json
    $key = $jsonData.GithubApiKey
    if($key) {
        return [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($key))
    } else {
        Write-Error "invalid apiKey or apiKey not found."
        break 1
    }
}