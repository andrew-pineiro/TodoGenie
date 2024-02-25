function Remove-FileTodo {
    [CmdletBinding()]
    param(
        $IssueStruct
    )
    $ResolvedPath = (Resolve-Path $IssueStruct.File).Path
    if($ResolvedPath) {
        try {
            (Get-Content $ResolvedPath | Where-Object {$_ -ne $IssueStruct.FullLine}) |
                Set-Content $ResolvedPath -Force -ErrorAction:Stop
            return $true
        } catch {
            return $false
        }
    }
    return $false
}