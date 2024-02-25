function Invoke-Genie {
    [CmdletBinding()]
    param (
        [string] $RootDirectory = $PWD,
        [string] $GitDirectory = $PWD,
        [switch] $NoUpdateTodo,
        [switch] $AllNo
    )

    if(-not(Test-Path ($GitDirectory + $directorySeparator + ".git"))) {
        Write-Error "no valid .git directory found in $GitDirectory"
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

        Write-Debug "current File: ``$Item``"

        $FoundMatches = Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_}
        
        foreach($Match in $FoundMatches.Matches) {

            Write-Debug "match: ``$Match``"
            
            $IssueTitle = $Match.Groups[1].Value.ToString().Trim()
            
            if($IssueTitle.Length -lt 1) {
                Write-Error "invalid issue name: $IssueTitle"
                break 1
            }
            
            $Issue = Get-GitIssue $IssueTitle $GitDirectory
            
            if($Issue) {
                Write-Debug "found issue in repo; ID: $($Issue.number)"
                
                if($Issue.state -eq "closed") {
                    $CloseCount++
                    if($AllNo) {
                        continue
                    }

                    Write-Host "Found [$IssueTitle] in closed state, attempt to cleanup file? (Y/N): " -NoNewline
                    $Ans = Read-Host
                    if($Ans -ne "Y") {
                        continue
                    }

                    (Get-Content $Item) -replace $($Match.Value), $null | Set-Content $Item -Force
                } else {
                    Write-Debug "issue $($Issue.number) is currently open"
                }
            } else {
                $NewCount++

                if($AllNo) {
                    continue
                }

                Write-Host "Create Github issue for [$IssueTitle]? (Y/N): " -NoNewline
                $Ans = Read-Host
                if($Ans -ne "Y") {
                    continue
                }

                Write-Host "Label?: " -NoNewline
                $Label = Read-Host

                Write-Host "Any additional comments to add?: " -NoNewline
                $Comments = Read-Host

                $IssueID = New-GitIssue $IssueTitle $GitDirectory $Label $Comments
                
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