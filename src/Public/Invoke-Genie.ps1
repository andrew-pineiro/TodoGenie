function Invoke-Genie {
    [CmdletBinding()]
    param (
        #TODO: Cleanup subcommands
        [ValidateSet('List','Prune','Create','Config')]
        [Parameter(Position=0, 
            HelpMessage = "Enter one of the subcommands to begin (List, Prune, Create)")]
        [Alias('c','cmd','cmds')]
        [string[]] $SubCommands
        ,
        [Parameter(Position=1,
            HelpMessage = "Directory with the .git folder")]
        [Alias('d','dir')]
        [string] $GitDirectory = $PWD
        ,
        [Parameter(ParameterSetName = 'TestMode',
            HelpMessage = 'Enables test mode, which runs through all subcommands in the specified -TestDirectory')]
        [Alias('t','test')]
        [switch] $TestMode
        ,
        [Parameter(ParameterSetName = 'TestMode',
            HelpMessage = 'Test directory to run -TestMode in. Defaults to test/')]
        [Alias('td', 'testdir')]
        [string] $TestDirectory = "test/"
        ,
        [Parameter(
            HelpMessage = 'Avoids commiting the changes to the repo automatically')]
        [Alias('n')]
        [switch] $NoAutoCommit
        ,
        [Parameter(
            HelpMessage = 'Shows the syntax/help message')]
        [Alias('h')]
        [switch] $Help
        ,
        [Parameter(
            HelpMessage = 'Used to update ApiKey')]
        [string] $NewApikey = ""
    )
    if($TestMode -and $SubCommands.Count -eq 0) {
        $SubCommands = 'List', 'Prune', 'Create'
    }

    if($Help -or $SubCommands.Count -eq 0) {
        Show-HelpMessage
        break
    }
    if($SubCommands.Count -eq 1 -and $SubCommands[0] -eq "Config") {
        if($NewApikey -ne "") {
            Update-ApiKey $NewApikey
            Write-Host "+ updated apiKey successfully"
            break
        }
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
        if(-not(Test-Path $Item)) {
            Write-Debug "not found: ``$Item``"
            continue
        }
        
        foreach($Match in (Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_})) {
            $LineNumber = $Match.LineNumber
            $Match = $Match.Matches.Groups
            Write-Debug "$($Item):$($LineNumber): ``$($Match[0].Value)``"
            $IssueStruct = @{
                Line     = $LineNumber
                File     = $Item
                FullLine = $Match[0].Value
                Prefix   = $Match[1].Value
                Keyword  = $Match[2].Value 
                ID       = $null
                Title    = $Match[4].Value
                Body     = ''
                State    = ''
            }
            
            $IDMatch = $Match[3].Value
            if($IDMatch.Length -gt 0) {
                $IDMatch = $IDMatch | Select-String -Pattern "\(#(\d+)\)"
                if($IDMatch) {
                    [int]$IssueStruct.ID = $IDMatch.Matches.Groups[1].Value
                    Write-debug "$($IssueStruct.File):$($IssueStruct.Line): ID FOUND: #$($IssueStruct.ID)"
                }
                
            }
            if($IssueStruct.Title.Length -lt 1) {
                Write-Host "- $($IssueStruct.File):$($IssueStruct.Line): [invalid issue name]"
                continue
            }
            [void]$IssueList.Add($IssueStruct)
        }
    }
    if($IssueList.Count -eq 0) {
        Write-Host "- No TODOs found in $GitDirectory"
        break
    }
    foreach($Command in $SubCommands) {
        Write-Debug "------ $Command ------"
        if($Command -eq 'List') {
            $IssueList | ForEach-Object {
                $Line     = $_.Line
                $File     = $_.File
                $FullLine = $_.FullLine
                Write-Host "+ $($File):$($Line): $($FullLine.Trim())"
            }
        } elseif($Command -eq 'Prune') {
            Write-Debug "Gathering all closed GitHub issues"
            $AllIssues = Get-AllGitIssues $GitDirectory -State closed 
            $IssueList | Where-Object {$null -ne $_.ID} | ForEach-Object {    
                if($_.ID -in $AllIssues.number) {
                    Write-Host "? Found issue #$($_.ID) in closed state. Attempt to cleanup files? (Y/N): " -NoNewline:$(-not($TestMode))
                    if(-not($TestMode)) {
                        $userInput = Read-Host
                        if($userInput -eq "Y") {
                            $_.State = ($AllIssues | Where-Object {$_.number -eq $_.ID}).state
                            $result = Remove-FileTodo $_
                            if(-not($result)) {
                                Write-Error "Couldn't remove TODO from $($_.File)"
                                continue
                            }
                            [void]$CommitList.Add($_)
                        }
                    }
                } 
            }
        } elseif($Command -eq 'Create') {
            $IssueList | Where-Object {$null -eq $_.ID} | ForEach-Object {
                Write-Host "? Attempt to create new git issue for [$($_.Title)]? (Y/N): " -NoNewline:$(-not($TestMode))
                if(-not($TestMode)) {
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
            }
            if($CommitList.Count -gt 0 -and -not($NoAutoCommit)) {
                Write-Host "+ Pushing $($CommitList.Count) changes to GitHub repository."
                Invoke-CommitTodo $CommitList
            }
            
        }
    }
    
}

New-Alias igen Invoke-Genie