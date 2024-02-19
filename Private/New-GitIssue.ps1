function New-GitIssue {
    [CmdletBinding()]
    param(
        $Issue,
        $RootDirectory = $PWD,
        $Label,
        $Comments
    )

    $ApiKey = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String((Get-content $secretsPath | ConvertFrom-Json).GithubApiKey))
    if(-not($ApiKey) -or $ApiKey -eq "") {
        throw "invalid apiKey or apiKey not found."
    }
    $GitModuleURL = "https://github.com/andrew-pineiro/PSIssueCreator/"
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
    $Body = @{
        "title" = "[Automated] $Issue"
        "labels" = $Label
        "body" = "**Created On:** $(Get-Date)  <br />**Created By:** [PSIssueModule]($GitModuleURL) <br /><br />**Additional Comments:** <br />$Comments"
    } | ConvertTo-Json
    try {
        $Response = Invoke-RestMethod -Uri $BaseUri -Method Post -Headers $Headers -Body $Body
    } catch {
        throw $_
    }
    return $Response.number

}