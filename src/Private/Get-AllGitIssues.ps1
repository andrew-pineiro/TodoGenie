function Get-AllGitIssues {
    [CmdletBinding()]
    param(
        $RootDirectory,
        [ValidateSet('open','closed','all')]
        $State = 'open'
    )
    $ApiKey = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String((Get-content ($secretsPath + $directorySeparator + $secretsFile) | ConvertFrom-Json).GithubApiKey))
    if(-not($ApiKey) -or $ApiKey -eq "") {
        Write-Error "invalid apiKey or apiKey not found."
        break 1
    }

    $GitData = (Get-Content ($RootDirectory + $directorySeparator + ".git" + $directorySeparator + "config") | 
                    Select-String "url = https://github.com/(.+)/(.+).git").Matches
    
    $RepoName = $GitData.Groups[2].Value
    $OwnerName = $GitData.Groups[1].Value
    if($RepoName -eq "" -or $null -eq $RepoName -or $OwnerName -eq "" -or $null -eq $OwnerName) {
        Write-Error "invalid repository name or owner name"
        break 1
    }   

    $BaseUri = "https://api.github.com/repos/$OwnerName/$RepoName/issues"
    $Headers = @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $ApiKey"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    try {
        $Response = Invoke-WebRequest -Uri "$($BaseUri)?state=closed" -Headers $Headers -Method Get
        $ResponseHeaders = $Response.Headers
        $ResponseData = $Response.Content | ConvertFrom-Json
        $PageCount = $ResponseHeaders.Link.Split(',')[1].ToString().Trim() | Select-String -Pattern "^.+page=(\d*).*$"
        $AttemptsLeft = $ResponseHeaders."X-Ratelimit-Remaining"
        Write-Debug "Ratelimit attempts remaining: $AttemptsLeft"
        if($PageCount) {
            $PageCount = $PageCount.Matches.Groups[1].Value

            Write-Debug "Page Count: $PageCount"
            for ($i = 2; $i -le $PageCount; $i++) {
                Write-Debug "Working on page $i"
                $Response = Invoke-WebRequest -Uri "$($BaseUri)?state=closed&page=$i" -Headers $Headers -Method Get
                $ResponseData += $Response.Content | ConvertFrom-Json
            }
        }
    } catch {
        Write-Error $_
        break 1
    }
    return $ResponseData
}