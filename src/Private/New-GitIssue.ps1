function New-GitIssue {
    [CmdletBinding()]
    param(
        $rootDirectory,
        $issue,
        $comments
    )

    $apiKey = Get-ApiKey
    Get-AllGitIssues $rootDirectory -State open | ForEach-Object { if($issue -eq $_.title.Replace("[Automated] ", "")) { Write-Error "Issue already exists."; break 1}}

    $gitModuleURL = "https://github.com/andrew-pineiro/TodoGenie/"
    $gitData = (Get-Content ($rootDirectory + $DirectorySeparator + ".git" + $DirectorySeparator + "config") | 
                        Select-String "url = https://github.com/(.+)/(.+).git").Matches
    $repoName = $gitData.Groups[2].Value
    $ownerName = $gitData.Groups[1].Value
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
    $body = @{
        "title" = "[Automated] $issue"
        "body" = "**Created On:** $(Get-Date)  <br />**Created By:** [TodoGenie]($gitModuleURL) <br /><br />**Additional Comments:** <br />$comments"
    } | ConvertTo-Json
    try {
        $response = Invoke-WebRequest -Uri $baseUri -Method Post -Headers $headers -Body $body
        Write-Debug "Ratelimit attempts remaining: $($response.Headers["X-Ratelimit-Remaining"])"
    } catch {
        Write-Error $_
        break 1
    }
    $response = $response.Content | ConvertFrom-Json
    return $response.Number

}