function Invoke-Genie {
    [CmdletBinding()]
    param (
        [ValidateSet('List','Prune','Create')]
        [Parameter(Position=1)][string[]] $SubCommand = "List",
        [string] $GitDirectory = $PWD,
        [switch] $TestMode,
        [string] $TestDirectory = "test/"
    )

    if(-not(Test-Path ($GitDirectory + $directorySeparator + ".git"))) {
        Write-Error "no valid .git directory found in $GitDirectory"
        break 1
    }
    if($TestMode) {
        $SubCommand = 'List','Prune','Create'
    }
    $MatchPattern = "^(.*)(TODO)(.*):\s*(.*)$"
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
                Line     = $LineNumber
                File     = $Item
                FullLine = $Match.Groups[0].Value
                Prefix   = $Match.Groups[1].Value
                Keyword  = $Match.Groups[2].Value 
                ID       = $null
                Title    = $Match.Groups[4].Value
                Body     = ''
            }
            

            $IDMatch = $Match.Groups[3].Value
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
    foreach($Command in $SubCommand) {
        Write-Host "------ $Command ------"
        if($Command -eq 'List') {
            $IssueList | ForEach-Object {
                $Line     = $_.'Line'
                $File     = $_.'File'
                $FullLine = $_.'FullLine'
                Write-Host "+ $($File):$($Line): $FullLine"
            }
        } elseif($Command -eq 'Prune') {
            $AllIssues = Get-AllGitIssues $GitDirectory -State closed 
            $IssueList | Where-Object {$null -ne $_.'ID'} | ForEach-Object {    
                $ID = $_.'ID'
                if($ID -in $AllIssues.number) {
                    Write-Host "? Found $ID in closed state. Attempt to cleanup? (Y/N): " -NoNewline
                    $userInput = Read-Host
                    if($userInput -eq "Y") {
                        $result = Remove-FileTodo $_
                        if(-not($result)) {
                            Write-Error "Couldn't remove TODO from $($_.'File')"
                            continue
                        }
                    }
                }
            }
        } elseif($Command -eq 'Create') {
            $IssueList | Where-Object {$null -eq $_.'ID'} | ForEach-Object {
                Write-Host "? Attempt to create new git issue for [$($_.'title')]? (Y/N): " -NoNewline
                $userInput = Read-Host
                if($userInput -eq "Y") {
                    $NewIssueID = New-GitIssue $GitDirectory $($_.'Title') $($_.'Body')
                    if([int]$NewIssueID) {
                        $_.'ID' = $NewIssueID
                        $result = Update-FileTodo $_
                        if(-not($result)) {
                            Write-Error "Couldn't update TODO in $($_.'File')"
                            continue
                        }
                    }
                }
            }
        }
    }
    
}

New-Alias igen Invoke-Genie