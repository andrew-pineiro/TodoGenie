function Invoke-IssueCreator {
    [CmdletBinding()]
    param (
        [string] $RootDirectory = $PWD,
        [switch] $NoUpdateTodo
    )

    try { gh --version > $null } catch { throw "GitHub Powershell Module Not Available"}

    Push-Location $RootDirectory

    $MatchPattern = "TODO:\s*(.+)"
    $GitModuleURL = "https://github.com/andrew-pineiro/PSIssueCreator/"
    $NewCount = 0
    $CloseCount = 0
    $Items = (Get-ChildItem -Recurse $RootDirectory | Where-Object {$_.PSIsContainer -eq $false -and $_.Name -ne ".git"}).FullName
    foreach($Item in $Items) {
        $FoundMatches = Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_}
        foreach($Match in $FoundMatches.Matches) {
            $IssueTitle = $Match.Groups[1].Value.ToString().Trim()
            if($IssueTitle.Length -lt 1) {
                Pop-Location
                throw "invalid issue name: $IssueTitle"
            }
            if($IssueTitle -match ".+\(#\d+\)") {
                $IssueTitle = $IssueTitle.Substring(0,$IssueTitle.LastIndexOf('#')-1).Trim()
            }
            if(-not((gh issue list --state all) -like "*$IssueTitle*")) {
                try {
                    $NewCount++
                    Write-Host "Found [$IssueTitle], create issue in repo? (Y/N): " -NoNewline
                    $Response = Read-Host
                    if($Response -ne "Y") {
                        Pop-Location
                        break
                    }
                    Write-Host "Any additional body notes?: " -NoNewline
                    $Comments = Read-Host
                    $Body = "**Created On:** $(Get-Date)  <br />**Created By:** [PSIssueModule]($GitModuleURL) <br /><br />**Additional Comments:** $Comments"
                    $Reply = gh issue create --title "[Automated] $IssueTitle" --body $Body
                    if([System.Uri]::IsWellFormedUriString($Reply, 'Absolute')) {
                        $NewIssueId = $Reply.Substring($Reply.LastIndexOf('/')+1) 
                        if(-not([int]$NewIssueID)) {
                            Pop-Location
                            throw "invalid issue id $NewIssueID; error occured."
                        }
                        Write-Host "Github issue [$IssueTitle] created. ID: $NewIssueID"
                        
                        if(-not($NoUpdateTodo)) {
                            $NewLine = "$($Match.Value) (#$NewIssueID)"
                            (Get-Content $Item) -replace $($Match.Value), $NewLine | Set-Content $Item -Force
                        }
                    }
                } catch {
                    Pop-Location
                    throw $_
                }
            } elseif((gh issue list --state closed) -like "*$IssueTitle*") {
                $CloseCount++
                Write-Host "Found [$IssueTitle] in closed state, attempt to clean up TODO? (Y/N): " -NoNewline
                $Response = Read-Host
                if($Response -ne "Y") {
                    Pop-Location
                    break
                }
                
                try {
                    (Get-Content $Item) -replace $($Match.Value), $null | Set-Content $Item -Force
                    Write-Host "Removed [$IssueTitle] from $Item"
                } catch {
                    Pop-Location
                    throw $_
                }
            } else {
                Write-Debug "open issue found: $IssueTitle"
            }
        }
        Pop-Location
    }

    if($NewCount + $CloseCount -eq 0) {
        Write-Host "no results"
    }

}