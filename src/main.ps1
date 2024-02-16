[CmdletBinding()]
param (
    [string[]] $Path
)
try { gh --version > $null } catch { throw "GitHub Powershell Module Not Available"}

$MatchPattern = "^\s*#TODO: (.+)"

if($Path -eq "." -or $Path -eq "*") {
    $Path = (Get-ChildItem -Recurse $PWD | Where-Object {$_.PSIsContainer -eq $false}).FullName
}
$Path | ForEach-Object {
    Get-Content $_ | Select-String -Pattern $MatchPattern | ForEach-Object {
        $Match = $_.Line
        $IssueTitle = $Match.Substring($Match.IndexOf(':')+2)
        if(-not((gh issue list) -like "*$IssueTitle*")) {
            gh issue create --title "[Automated] $IssueTitle" --body "Created On: $(Get-Date)"
            Write-Host "Issue $IssueTitle Created"
        } else {
            #TODO: Implement checking for closed issues
        }
    }

}