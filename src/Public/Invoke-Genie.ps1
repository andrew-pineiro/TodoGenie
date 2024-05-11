function Invoke-Genie {
    [CmdletBinding()]
    param (
        #TODO: Cleanup subcommands
        [ValidateSet('List','Prune','Create','Config')]
        [Parameter(Position=0, 
            HelpMessage = "Enter one of the subcommands to begin (List, Prune, Create)")]
        [Alias('c','cmd','cmds')]
        [string[]] $subCommands
        ,
        [Parameter(Position=1,
            HelpMessage = "Directory with the .git folder")]
        [Alias('d','dir')]
        [string] $gitDirectory = $PWD
        ,
        [Parameter(ParameterSetName = 'TestMode',
            HelpMessage = 'Enables test mode, which runs through all subcommands in the specified -TestDirectory')]
        [Alias('t','test')]
        [switch] $testMode
        ,
        [Parameter(ParameterSetName = 'TestMode',
            HelpMessage = 'Test directory to run -TestMode in. Defaults to test/')]
        [Alias('td', 'testdir')]
        [string] $testDirectory = "test/"
        ,
        [Parameter(
            HelpMessage = 'Avoids commiting the changes to the repo automatically')]
        [Alias('n')]
        [switch] $noAutoCommit
        ,
        [Parameter(
            HelpMessage = 'Shows the syntax/help message')]
        [Alias('h')]
        [switch] $help
        ,
        [Parameter(
            HelpMessage = 'Used to update ApiKey')]
        [string] $newApikey = ""
    )
    if($testMode -and $subCommands.Count -eq 0) {
        $subCommands = 'List', 'Prune', 'Create'
    }

    if($help -or $subCommands.Count -eq 0) {
        Show-HelpMessage
        break
    }
    if($subCommands.Count -eq 1 -and $subCommands[0] -eq "Config") {
        if($newApikey -ne "") {
            Update-ApiKey $newApikey
            Write-Host "+ updated apiKey successfully"
            break
        }
    }
    if(-not(Test-Path ($gitDirectory + $DirectorySeparator + ".git"))) {
        Write-Error "no valid .git directory found in $gitDirectory"
        break 1
    }

    $MatchPattern = "^(.*)(TODO)(.*):\s*(.*)$"
    $IssueList = New-Object System.Collections.ArrayList
    $Directory = switch ($testMode) {
        $true { $testDirectory }
        default {"*"}
    }
    $Items = Invoke-Command -ScriptBlock {git ls-files $Directory}

    foreach($item in $Items) {
        if(-not(Test-Path $Item)) {
            Write-Debug "not found: ``$Item``"
            continue
        }
        
        foreach($match in (Get-Content $Item | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_})) {
            $lineNumber = $Match.LineNumber
            $match = $match.Matches.Groups
            Write-Debug "$($item):$($lineNumber): ``$($match[0].Value)``"
            $issueStruct = @{
                Line     = $lineNumber
                File     = $item
                FullLine = $match[0].Value
                Prefix   = $match[1].Value
                Keyword  = $match[2].Value 
                ID       = $null
                Title    = $match[4].Value
                Body     = ''
                State    = ''
            }
            
            $idMatch = $match[3].Value
            if($idMatch.Length -gt 0) {
                $idMatch = $idMatch | Select-String -Pattern "\(#(\d+)\)"
                if($idMatch) {
                    [int]$issueStruct.ID = $idMatch.Matches.Groups[1].Value
                    Write-debug "$($issueStruct.File):$($issueStruct.Line): ID FOUND: #$($issueStruct.ID)"
                }
                
            }
            if($issueStruct.Title.Length -lt 1) {
                Write-Host "- $($issueStruct.File):$($issueStruct.Line): [invalid issue name]"
                continue
            }
            [void]$IssueList.Add($IssueStruct)
        }
    }
    if($IssueList.Count -eq 0) {
        Write-Host "- No TODOs found in $GitDirectory"
        break
    }
    foreach($command in $subCommands) {
        Write-Debug "------ $command ------"
        if($command -eq 'List') {
            $IssueList | ForEach-Object {
                $Line     = $_.Line
                $File     = $_.File
                $FullLine = $_.FullLine
                Write-Host "+ $($File):$($Line): $($FullLine.Trim())"
            }
        } elseif($command -eq 'Prune') {
            Write-Debug "Gathering all closed GitHub issues"
            $allIssues = Get-AllGitIssues $gitDirectory -State closed 
            $issueList | Where-Object {$null -ne $_.ID} | ForEach-Object {    
                if($_.ID -in $allIssues.number) {
                    Write-Host "? Found issue #$($_.ID) in closed state. Attempt to cleanup files? (Y/N): " -NoNewline:$(-not($TestMode))
                    if(-not($testMode)) {
                        $userInput = Read-Host
                        if($userInput -eq "Y") {
                            $_.State = "closed"
                            $result = Remove-FileTodo $_
                            if(-not($result)) {
                                Write-Error "Couldn't remove TODO from $($_.File)"
                                continue
                            }
                            Invoke-CommitTodo $_
                        }
                    }
                } 
            }
        } elseif($command -eq 'Create') {
            $issueList | Where-Object {$null -eq $_.ID} | ForEach-Object {
                Write-Host "? Attempt to create new git issue for [$($_.Title)]? (Y/N): " -NoNewline:$(-not($testMode))
                if(-not($testMode)) {
                    $userInput = Read-Host
                    if($userInput -eq "Y") {
                        $newIssueID = New-GitIssue $gitDirectory $_.Title $_.Body
                        if([int]$newIssueID) {
                            $_.'ID' = $newIssueID
                            $_.State = "open"
                            $result = Update-FileTodo $_
                            if(-not($result)) {
                                Write-Error "Couldn't update TODO in $($_.File)"
                                continue
                            }
                            Invoke-CommitTodo $_
                        }
                    }
                } 
            }        
        }
    }
    
}

New-Alias igen Invoke-Genie