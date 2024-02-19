function Get-GitIssue {
    [Cmdletbinding()]
    param(
        $Issue,
        $RootDirectory = $PWD
    )
    $ApiKey = (Get-content $secretsPath | ConvertFrom-Json).GithubApiKey
    if(-not($ApiKey) -or $ApiKey -eq "") {
        throw "invalid apiKey or apiKey not found."
    }
    $GitData = (Get-Content "$RootDirectory\.git\config" | select-string "url = https://github.com/(.+)/(.+).git").Matches
    $RepoName = $GitData.Groups[2].Value
    $OwnerName = $GitData.Groups[1].Value
    if($RepoName -eq "" -or $null -eq $RepoName -or $OwnerName -eq "" -or $null -eq $OwnerName) {
        throw "invalid repository name or owner name"
    }
    $BaseUri = "https://api.github.com/repos/$OwnerName/$RepoName/issues"
    $Headers = @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $ApiKey"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    if($Issue -match ".+\(#(\d+)\)") {
        $IssueID = ($Issue | Select-String -Pattern ".+\(#(\d+)\)").Matches.Groups[1].Value
        if([int]$IssueID) {
            try {
                $Response = Invoke-RestMethod -Uri "$BaseUri/$IssueID" -Headers $Headers -Method Get
            } catch {
                throw $_
            }
            return $Response
        }
    } else {
        try {
            $Response = Invoke-RestMethod -Uri $BaseUri -Headers $Headers -Method Get
        } catch {
            throw $_
        }
        return ($Response | Where-Object {$_.title -like "*$Issue*"})
    }
}