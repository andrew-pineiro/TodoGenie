function Invoke-Genie {
    [CmdletBinding()]
    param (
        [string] $RootDirectory = $PWD,
        [switch] $NoUpdateTodo
    )
    if(-not(Test-Path ($RootDirectory + $directorySeparator + ".git"))) {
        Write-Error "no valid .git directory found in $RootDirectory"
        break 1
    }

    $MatchPattern = "TODO:\s*(.+)"
    $NewCount = 0
    $CloseCount = 0
    $Items = (Get-ChildItem -Recurse $RootDirectory | Where-Object {
        $_.PSIsContainer -eq $false -and 
        $_.Name -ne ".git" -and
        $_.Extension -in $ExtensionList
        }).FullName
    foreach($Item in $Items) {
        Write-Debug "Checking $Item"
        $FoundMatches = Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_}
        foreach($Match in $FoundMatches.Matches) {
            Write-Debug "Found Match $Match"
            $IssueTitle = $Match.Groups[1].Value.ToString().Trim()
            if($IssueTitle.Length -lt 1) {
                Write-Error "invalid issue name: $IssueTitle"
                break 1
            }
            $Issue = Get-GitIssue $IssueTitle $RootDirectory
            
            if($Issue) {
                Write-Debug "Found Issue in Github ID: $($Issue.number)"
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
                    Write-Error "error in ``New-GitIssue`` response"
                    break 1
                }

            }
        }
    }
    if($NewCount + $CloseCount -eq 0) {
        Write-Host "No updated or new TODO's found."
    }
}

New-Alias igen Invoke-Genie