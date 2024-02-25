function Invoke-Genie {
    [CmdletBinding()]
    param (
        [ValidateSet('List','Prune','Create')]
        [Parameter(Position=1)][string] $SubCommand = "List",
        [string] $GitDirectory = $PWD,
        [switch] $TestMode,
        [string] $TestDirectory = "test/",
        [switch] $NoUpdateTodo,
        [switch] $AllNo
    )

    if(-not(Test-Path ($GitDirectory + $directorySeparator + ".git"))) {
        Write-Error "no valid .git directory found in $GitDirectory"
        break 1
    }

    $MatchPattern = "^(.*)TODO(.*):\s*(.*)$"
    $IssueList = New-Object System.Collections.ArrayList
    $directory = switch ($TestMode) {
        $true { $TestDirectory }
        default {"*"}
    }
    $Items = Invoke-Command -ScriptBlock {git ls-files $directory}

    foreach($Item in $Items) {
        Write-Debug "current File: ``$Item``"

        if(-not(Test-Path $Item)) {
            Write-Debug "not found: ``$Item``"
            continue
        }
        
        foreach($Match in (Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_})) {
            $LineNumber = $Match.LineNumber
            $Match = $Match.Matches
            Write-Debug "match: $($LineNumber): ``$Match``"
            $IssueStruct = @{
                Line = $LineNumber
                File = $Item
                FullLine = $Match.Groups[0].Value
                Prefix = $Match.Groups[1].Value 
                ID = $null
                Title = $Match.Groups[3].Value
            }
            

            $IDMatch = $Match.Groups[2].Value
            if($IDMatch.Length -gt 0) {
                [int]$IssueStruct.ID = ($IDMatch | Select-String -Pattern "\(#(\d+)\)").Matches.Groups[1].Value
                Write-debug "id found: ``$($IssueStruct.ID)``"
            }
            if($IssueStruct.Title.Length -lt 1) {
                Write-Error "invalid issue name: $IssueTitle"
                break 1
            }
            [void]$IssueList.Add($IssueStruct)
        }
    }
    if($SubCommand -eq 'List') {
        $IssueList | ForEach-Object {
            $Line = $_.'Line'
            $File = $_.'File'
            $FullLine = $_.'FullLine'
            Write-Host "+ $($File):$($Line): $FullLine"
        }
    } elseif($SubCommand -eq 'Prune') {
            echo 'not implemented'
            # $IssueList | Where-Object {$null -ne $_.'ID'} | ForEach-Object {
            # }
    } elseif($SubCommand -eq 'Create') {
            echo 'not implemented'
    }
}
    #         if($ExistingIssue) {
    #             Write-Debug "found existing in repo; ID: $($IssueStruct.ID)"
    #             $Issue = Get-GitIssue $($IssueStruct.Title) $GitDirectory
    #             if($Issue.state -eq "closed") {
    #                 $CloseCount++
    #                 if($AllNo) {
    #                     continue
    #                 }

    #                 Write-Host "Found [$IssueTitle] in closed state, attempt to cleanup file? (Y/N): " -NoNewline
    #                 $Ans = Read-Host
    #                 if($Ans -ne "Y") {
    #                     continue
    #                 }

    #                 (Get-Content $Item) -replace $($Match.Value), $null | Set-Content $Item -Force
    #             } else {
    #                 Write-Debug "issue $($Issue.number) is currently open"
    #             }
    #         } else {
    #             $NewCount++

    #             if($AllNo) {
    #                 continue
    #             }

    #             Write-Host "Create Github issue for [$IssueTitle]? (Y/N): " -NoNewline
    #             $Ans = Read-Host
    #             if($Ans -ne "Y") {
    #                 continue
    #             }

    #             Write-Host "Label?: " -NoNewline
    #             $Label = Read-Host

    #             Write-Host "Any additional comments to add?: " -NoNewline
    #             $Comments = Read-Host

    #             $IssueID = New-GitIssue $IssueTitle $GitDirectory $Label $Comments
                
    #             if([int]$IssueID) {
    #                 if(-not($NoUpdateTodo) -and -not($IssueTitle -match ".+\(#(\d+)\)")) {
    #                     $NewLine = "$($Match.Value) (#$IssueID)"
    #                     (Get-Content $Item) -replace $($Match.Value), $NewLine | Set-Content $Item -Force
    #                 }
    #             } else {
    #                 Write-Error "error in ``New-GitIssue`` response"
    #                 break 1
    #             }

    #         }
    #     }
    # }
    # if($NewCount + $CloseCount -eq 0) {
    #     Write-Host "No updated or new TODO's found."
    # }
#}

New-Alias igen Invoke-Genie