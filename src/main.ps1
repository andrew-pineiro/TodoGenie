[CmdletBinding()]
param (
    [string[]] $Directories = ".",
    [switch] $NoUpdateTodo
)
try { gh --version > $null } catch { throw "GitHub Powershell Module Not Available"}

$MatchPattern = "^\s*#\s*TODO\s*: (.+)"
$NewCount = 0
$CloseCount = 0

if($Directories.Count -le 0) {
    throw "not enough arguments supplied"
}

if($Directories -eq "." -or $Directories -eq "*") {
    $Directories = (Get-ChildItem -Recurse $PWD | Where-Object {$_.PSIsContainer -eq $false}).FullName
}

foreach($Path in $Directories) {
    $FoundMatches = Get-Content $Path | Select-String -Pattern $MatchPattern | Where-Object {$null -ne $_}
    foreach($Match in $FoundMatches.Line) {
        $Match = $Match.Trim()
        $IssueTitle = $Match.Substring(1)
        if($IssueTitle.Length -lt 3) {
            throw "invalid issue name: $IssueTitle"
        }
        if(-not((gh issue list --state all) -like "*$IssueTitle*")) {
            try {
                Write-Host "Found [$IssueTitle], create issue in repo? (Y/N): " -NoNewline
                $Response = Read-Host
                if($Response -ne "Y") {
                    break
                }
                $Reply = gh issue create --title "[Automated] $IssueTitle" --body "Created On: $(Get-Date)"
                if([System.Uri]::IsWellFormedUriString($Reply, 'Absolute')) {
                    $NewIssueId = $Reply.Substring($Reply.LastIndexOf('/')+1) 
                    if(-not([int]$NewIssueID)) {
                        throw "invalid issue id $NewIssueID; error occured."
                    }
                    Write-Host "Github issue [$IssueTitle] created. ID: $NewIssueID"
                    
                    if(-not($NoUpdateTodo)) {
                        $NewLine = "#$IssueTitle (#$NewIssueID)"
                        (Get-Content $Path) -replace $Match, $NewLine | Set-Content $Path -Force
                    }
                }
                $NewCount++
            } catch {
                throw $_
            }
        } elseif((gh issue list --state closed) -like "*$IssueTitle*") {
            #TODO: Implement checking for closed issues (#27)
            Write-Host "Found [$IssueTitle] in closed state, attempt to clean up TODO's? (Y/N): " -NoNewline
            $Response = Read-Host
            if($Response -ne "Y") {
                break
            }
            
            try {
                (Get-Content $Path) -replace $Match, $null | Set-Content $Path -Force
                Write-Host "Removed [$Match] from $Path"
                $CloseCount++
            } catch {
                throw $_
            }
        } else {
            echo "open issue found: $IssueTitle"
        }
    }
}

if($NewCount + $CloseCount -eq 0) {
    Write-Host "No updated TODO's found"
}
