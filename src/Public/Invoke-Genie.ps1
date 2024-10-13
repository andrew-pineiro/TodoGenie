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
        ,
        [Alias('X')]
        [Parameter(
            HelpMessage = 'Excluded Directories (name only), comma seperated [ex: folder1,folder2,folder3]')]
        [string[]] $excludedDirs
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

    $MatchPattern = "^(.*)(TODO)(.*):\s*(.*)"
    # Maximum lines to absorb for body
    $MaxBodyLines = 3
    # Maximum characters to absorb for prefix (comment syntax)
    $MaxPrefixLength = 3
    $IssueList = New-Object System.Collections.ArrayList
    $Directory = switch ($testMode) {
        $true { $testDirectory }
        default {"*"}
    }
    $Items = Invoke-Command -ScriptBlock { git ls-files $Directory }

    foreach($item in $Items) {
        #TODO: Fix issue with multiple dirs excluding more than expected
        if(($excludedDirs | % {$item -like "$_/*"})) {
            Write-Debug "$item excluded"
            continue
        }
        if(-not(Test-Path $Item)) {
            Write-Debug "not found: ``$Item``"
            continue
        }
        
        Get-Content $item | Select-String -Pattern $MatchPattern -Context 0,$MaxBodyLines | Where-Object {$null -ne $_} | ForEach-Object {
            $lineNumber = $_.LineNumber
            $match = $_.Matches.Groups
            $bodyLineCount = $_.Context.PostContext.Count
            
            $rawBody = ''
            $rawPrefix = $match[1].Value.Trim()
            Write-Debug "$($item):$($lineNumber): ``$($match[0].Value.TrimStart())``"

            $issueStruct = @{
                Line     = $lineNumber
                File     = $item
                FullLine = $match[0].Value
                Prefix   = $rawPrefix.Length -gt $MaxPrefixLength ? $rawPrefix[0..2] : $rawPrefix
                Keyword  = $match[2].Value 
                ID       = $null
                Title    = $match[4].Value
                Body     = ''
                State    = ''
            }

            # BODY COLLECTION
            if($issueStruct.Prefix.Length -gt 0) {
                for($i = 0; $i -le $bodyLineCount; $i++) {
                    $line = $_.Context.PostContext[$i]
                    if(-not($line)) { continue }
                    if($line -match "$($issueStruct.Prefix)\s*$($issueStruct.Keyword)") { continue }

                    if($line.TrimStart().StartsWith($issueStruct.Prefix) -and $line.Length -gt 3) {
                        Write-Debug "$($item):$($lineNumber): LINE: $($line.TrimStart())"
                        Write-Debug "$($issueStruct.File):$($issueStruct.Line): Prefix Used: $($issueStruct.Prefix)"
                        Write-Debug "$($issueStruct.File):$($issueStruct.Line): Adding to body: $($line.Replace($issueStruct.Prefix, ''))"
                        
                        $rawBody += "$($line.Replace($issueStruct.Prefix, ''))`n"
                    }
                }
            }
            $issueStruct.Body = $rawBody.Trim()

            # ID COLLECTION
            $idMatch = $match[3].Value
            if($idMatch.Length -gt 0) {
                $idMatch = $idMatch | Select-String -Pattern "\(#(\d+)\)"
                if($idMatch) {
                    [int]$issueStruct.ID = $idMatch.Matches.Groups[1].Value
                    Write-debug "$($issueStruct.File):$($issueStruct.Line): ID FOUND: #$($issueStruct.ID)"
                }
                
            }
            if($issueStruct.Title.Length -lt 1) {
                Write-Debug "- $($issueStruct.File):$($issueStruct.Line): [invalid issue name]"
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
                $outMessage = "$([string]::IsNullOrEmpty($_.Prefix) ? $_.FullLine.Trim() : $_.FullLine.Trim().Replace($_.Prefix, ''))"
                Write-Host "+ $($_.File):$($_.Line): $outMessage"
                if(-not([string]::IsNullOrEmpty($_.Body))) {
                    ($_.Body.Split("`n") | % { 
                        Write-Host "`t+ $($_.Trim())" 
                    })
                }
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