function Invoke-Genie {
    [CmdletBinding()]
    param (
        [ValidateSet('List','Prune','Create')]
        [Parameter(Position=0,
            HelpMessage = "Enter one of the subcommands to begin (List, Prune, Create)"
            )][string[]] $SubCommand,
        [string] $GitDirectory = $PWD,
        [Parameter(
            ParameterSetName = 'TestMode'
        )][Alias('t')][switch] $TestMode,
        [Parameter(
            ParameterSetName = 'TestMode'
        )][string] $TestDirectory = "test/",
        [switch] $NoAutoCommit,
        [Alias('h')][switch] $Help
    )
    if($TestMode) {
        $SubCommand = 'List','Prune','Create'
    }
    if($Help -or $SubCommand.Count -eq 0) {
        Show-HelpMessage
        break
    }
    if(-not(Test-Path ($GitDirectory + $directorySeparator + ".git"))) {
        Write-Error "no valid .git directory found in $GitDirectory"
        break 1
    }

    $MatchPattern = "^(.*)(TODO)(.*):\s*(.*)$"
    $IssueList = New-Object System.Collections.ArrayList
    $CommitList = New-Object System.Collections.ArrayList
    $directory = switch ($TestMode) {
        $true { $TestDirectory }
        default {"*"}
    }
    $Items = Invoke-Command -ScriptBlock {git ls-files $directory}

    foreach($Item in $Items) {
        Write-Debug "current file: ``$Item``"

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
                State    = ''
            }
            
            $IDMatch = $Match.Groups[3].Value
            if($IDMatch.Length -gt 0) {
                $IDMatch = $IDMatch | Select-String -Pattern "\(#(\d+)\)"
                if($IDMatch) {
                    [int]$IssueStruct.ID = $IDMatch.Matches.Groups[1].Value
                    Write-debug "id found: ``$($IssueStruct.ID)``"
                }
                
            }
            if($IssueStruct.Title.Length -lt 1) {
                Write-Error "invalid issue name: $IssueTitle"
                break 1
            }
            [void]$IssueList.Add($IssueStruct)
        }
    }
    if($IssueList.Count -eq 0) {
        Write-Host "- No TODOs found in $GitDirectory"
        break
    }
    foreach($Command in $SubCommand) {
        Write-Debug "------ $Command ------"
        if($Command -eq 'List') {
            $IssueList | ForEach-Object {
                $Line     = $_.Line
                $File     = $_.File
                $FullLine = $_.FullLine
                Write-Host "+ $($File):$($Line): $FullLine"
            }
        } elseif($Command -eq 'Prune') {
            $AllIssues = Get-AllGitIssues $GitDirectory -State closed 
            $IssueList | Where-Object {$null -ne $_.ID} | ForEach-Object {    
                $ID = $_.ID
                if($ID -in $AllIssues.number) {
                    Write-Host "? Found $ID in closed state. Attempt to cleanup? (Y/N): " -NoNewline
                    $userInput = Read-Host
                    $_.State = ($AllIssues | Where-Object {$_.number -eq $ID}).state
                    if($userInput -eq "Y") {
                        $result = Remove-FileTodo $_
                        if(-not($result)) {
                            Write-Error "Couldn't remove TODO from $($_.File)"
                            continue
                        }
                        [void]$CommitList.Add($_)
                    }
                }
            }
        } elseif($Command -eq 'Create') {
            $IssueList | Where-Object {$null -eq $_.ID} | ForEach-Object {
                Write-Host "? Attempt to create new git issue for [$($_.Title)]? (Y/N): " -NoNewline
                $userInput = Read-Host
                if($userInput -eq "Y") {
                    $NewIssueID = New-GitIssue $GitDirectory $_.Title $_.Body
                    if([int]$NewIssueID) {
                        $_.'ID' = $NewIssueID
                        $_.State = "open"
                        $result = Update-FileTodo $_
                        if(-not($result)) {
                            Write-Error "Couldn't update TODO in $($_.File)"
                            continue
                        }
                        [void]$CommitList.Add($_)
                    }
                }
            }
            if($CommitList.Count -gt 0 -and -not($NoAutoCommit)) {
                Write-Host "+ Pushing $($CommitList.Count) changes to GitHub repository."
                Invoke-CommitTodo $CommitList
            }
            
        }
    }
    
}

New-Alias igen Invoke-Genie