function Invoke-IssueCreator {
    [CmdletBinding()]
    param (
        [string] $RootDirectory = $PWD,
        [switch] $NoUpdateTodo
    )
    if(-not(Test-Path "$RootDirectory\.git")) {
        throw "no valid .git directory found in $RootDirectory"
    }

    $MatchPattern = "TODO:\s*(.+)"
    $NewCount = 0
    $CloseCount = 0
    $Items = (Get-ChildItem -Recurse $RootDirectory | Where-Object {$_.PSIsContainer -eq $false -and $_.Name -ne ".git"}).FullName

    foreach($Item in $Items) {
        $FoundMatches = Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_}
        foreach($Match in $FoundMatches.Matches) {
            $IssueTitle = $Match.Groups[1].Value.ToString().Trim()
            if($IssueTitle.Length -lt 1) {
                throw "invalid issue name: $IssueTitle"
            }
            $Issue = Get-GitIssue $IssueTitle $RootDirectory
            if($Issue) {
                If($Issue.state -eq "closed") {
                    $CloseCount++
                    Write-Host "Found [$IssueTitle] in closed state, attempt to cleanup TODO's? (Y/N): " -NoNewline
                    $Ans = Read-Host
                    if($Ans -ne "Y") {
                        break
                    }
                    (Get-Content $Item) -replace $($Match.Value), $null | Set-Content $Item -Force
                }
            } else {
                $NewCount++
                Write-Host "Create Github issue for [$IssueTitle]? (Y/N): " -NoNewline
                $Ans = Read-Host
                if($Ans -ne "Y") {
                    break
                }
                Write-Host "Label?: " -NoNewline
                $Label = Read-Host
                Write-Host "Any additional comments to add?: " -NoNewline
                $Comments = Read-Host
                $IssueID = New-GitIssue $IssueTitle $RootDirectory $Label $Comments
                if([int]$IssueID) {
                    if(-not($NoUpdateTodo) -and -not($IssueTitle -match ".+\(#(\d+)\)")) {
                        $NewLine = "$($Match.Value) (#$IssueID)"
                        (Get-Content $Item) -replace $($Match.Value), $NewLine | Set-Content $Item -Force
                    }
                } else {
                    throw "error in ``New-GitIssue`` response"
                }

            }
        }
    }
    if($NewCount + $CloseCount -eq 0) {
        Write-Host "No updated or new TODO's found."
    }
}