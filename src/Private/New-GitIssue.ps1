function New-GitIssue {
    [CmdletBinding()]
    param(
        $Issue,
        $RootDirectory,
        $Label,
        $Comments
    )

    $ApiKey = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String((Get-content ($secretsPath + $directorySeparator + $secretsFile) | ConvertFrom-Json).GithubApiKey))
    if(-not($ApiKey) -or $ApiKey -eq "") {
        Write-Error "invalid apiKey or apiKey not found."
        break 1
    }
    $GitModuleURL = "https://github.com/andrew-pineiro/PSIssueCreator/"
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
    $Body = @{
        "title" = "[Automated] $Issue"
        "labels" = $Label
        "body" = "**Created On:** $(Get-Date)  <br />**Created By:** [TodoGenie]($GitModuleURL) <br /><br />**Additional Comments:** <br />$Comments"
    } | ConvertTo-Json
    try {
        $Response = Invoke-RestMethod -Uri $BaseUri -Method Post -Headers $Headers -Body $Body
    } catch {
        Write-Error $_
        break 1
    }
    return $Response.number

}