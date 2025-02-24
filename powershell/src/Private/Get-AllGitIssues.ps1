function Get-AllGitIssues {
    [CmdletBinding()]
    param(
        $rootDirectory,
        [ValidateSet('open','closed','all')]
        $state = 'open'
    )
    $apiKey = Get-ApiKey
    Write-Debug "Checking for .git config in $rootDirectory"
    if(-not(Test-Path ($rootDirectory + $DirectorySeparator + ".git"))) {
        Write-Error "Unable to find ``.git`` directory in $rootDirectory"
    }
    $gitData = Get-Content ($rootDirectory + $DirectorySeparator + ".git" + $DirectorySeparator + "config") | 
                    Select-String "url = https://github.com/(.+)/(.+).git"
    Write-Debug "Data: $gitData"
    if(-not($gitData.Matches)) {
        Write-Error "unable to gather items from .git config file"
        break 1
    }
    $gitData = $GitData.Matches
    $repoName = $GitData.Groups[2].Value
    $ownerName = $GitData.Groups[1].Value
    if($repoName -eq "" -or $null -eq $repoName -or $ownerName -eq "" -or $null -eq $ownerName) {
        Write-Error "invalid repository name or owner name"
        break 1
    }   

    $baseUri = "https://api.github.com/repos/$ownerName/$repoName/issues"
    $headers = @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $ApiKey"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    try {
        $response = Invoke-WebRequest -Uri "$($BaseUri)?state=$state" -Headers $Headers -Method Get 
        $responseHeaders = $response.Headers
        $responseData = $response.Content | ConvertFrom-Json
        $attemptsLeft = $responseHeaders."X-Ratelimit-Remaining"
        Write-Debug "Ratelimit attempts remaining: $attemptsLeft"
        if($responseHeaders.Link) {
            $pageCount = $responseHeaders.Link.Split(',')[1].ToString().Trim() | Select-String -Pattern "^.+page=(\d*).*$"
            if($pageCount) {
                $pageCount = $pageCount.Matches.Groups[1].Value
    
                Write-Debug "Page Count: $pageCount"
                for ($i = 2; $i -le $pageCount; $i++) {
                    Write-Debug "Working on page $i"
                    $response = Invoke-WebRequest -Uri "$($BaseUri)?state=$state&page=$i" -Headers $Headers -Method Get
                    $responseData += $response.Content | ConvertFrom-Json
                }
            }
        }
    } catch {
        Write-Error $_
        break 1
    }
    return $responseData
}