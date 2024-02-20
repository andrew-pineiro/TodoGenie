function Get-GitIssue {
    [Cmdletbinding()]
    param(
        $Issue,
        $RootDirectory = $PWD
    )
    $ApiKey = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String((Get-content $secretsPath | ConvertFrom-Json).GithubApiKey))
    if(-not($ApiKey) -or $ApiKey -eq "") {
        Write-Error "invalid apiKey or apiKey not found."
        break 1
    }
    $GitData = (Get-Content "$RootDirectory\.git\config" | select-string "url = https://github.com/(.+)/(.+).git").Matches
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
    if($Issue -match ".+\(#(\d+)\)") {
        $IssueID = ($Issue | Select-String -Pattern ".+\(#(\d+)\)").Matches.Groups[1].Value
        if([int]$IssueID) {
            try {
                $Response = Invoke-RestMethod -Uri "$BaseUri/$IssueID" -Headers $Headers -Method Get
            } catch {
                Write-Error $_
                break 1
            }
            return $Response
        }
    } else {
        try {
            $Response = Invoke-RestMethod -Uri $BaseUri -Headers $Headers -Method Get
        } catch {
            Write-Error $_
            break 1
        }
        return ($Response | Where-Object {$_.title -like "*$Issue*"})
    }
}