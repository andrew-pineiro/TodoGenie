function Remove-FileTodo {
    [CmdletBinding()]
    param(
        $issueStruct
    )
    $resolvedPath = (Resolve-Path $IssueStruct.File).Path
    if($resolvedPath) {
        try {
            (Get-Content $resolvedPath | Where-Object {$_ -ne $issueStruct.FullLine}) |
                Set-Content $resolvedPath -Force -ErrorAction:Stop
            return $true
        } catch {
            return $false
        }
    }
    return $false
}