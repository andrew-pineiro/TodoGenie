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
    $Match = (Get-Content $_ | Select-String -Pattern $MatchPattern).Line
    if($Match) {
        $IssueTitle = $Match.Substring($Match.IndexOf(':')+2)
        $IssueTitle
        gh issue create --title $IssueTitle
    }

}