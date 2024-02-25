function Update-FileTodo {
    [CmdletBinding()]
    param(
        $IssueStruct
    )
    $ResolvedPath = (Resolve-Path $IssueStruct.File).Path
    if($ResolvedPath) {
        try {
            $NewLine = "$($IssueStruct.Prefix)$($IssueStruct.Keyword)(#$($IssueStruct.ID)): $($IssueStruct.Title)"
            (Get-Content $ResolvedPath) -replace $IssueStruct.FullLine, $NewLine | 
                Set-Content $ResolvedPath -Force -ErrorAction:Stop
            return $true
        } catch {
            return $false
        }
    }
    return $false
}