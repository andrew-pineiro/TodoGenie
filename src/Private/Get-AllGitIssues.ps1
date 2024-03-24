function Get-AllGitIssues {
    [CmdletBinding()]
    param(
        $RootDirectory,
        [ValidateSet('open','closed','all')]
        $State = 'open'
    )
    $ApiKey = Get-ApiKey
    Write-Debug "Checking for .git config in $RootDirectory"
    if(-not(Test-Path $RootDirectory + $directorySeparator + ".git")) {
        Write-Error "Unable to find ``.git`` directory in $RootDirectory"
    }
    $GitData = Get-Content ($RootDirectory + $directorySeparator + ".git" + $directorySeparator + "config") | 
                    Select-String "url = https://github.com/(.+)/(.+).git"
    Write-Debug $GitData
    if(-not($GitData.Matches)) {
        Write-Error "unable to gather items from .git config file"
        break 1
    }
    $GitData = $GitData.Matches
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
        $AttemptsLeft = $ResponseHeaders."X-Ratelimit-Remaining"
        Write-Debug "Ratelimit attempts remaining: $AttemptsLeft"
        if($ResponseHeaders.Link) {
            $PageCount = $ResponseHeaders.Link.Split(',')[1].ToString().Trim() | Select-String -Pattern "^.+page=(\d*).*$"
            if($PageCount) {
                $PageCount = $PageCount.Matches.Groups[1].Value
    
                Write-Debug "Page Count: $PageCount"
                for ($i = 2; $i -le $PageCount; $i++) {
                    Write-Debug "Working on page $i"
                    $Response = Invoke-WebRequest -Uri "$($BaseUri)?state=closed&page=$i" -Headers $Headers -Method Get
                    $ResponseData += $Response.Content | ConvertFrom-Json
                }
            }
        }
    } catch {
        Write-Error $_
        break 1
    }
    return $ResponseData
}