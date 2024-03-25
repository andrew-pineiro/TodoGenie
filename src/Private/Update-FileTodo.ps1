function Update-FileTodo {
    [CmdletBinding()]
    param(
        $issueStruct
    )
    $resolvedPath = (Resolve-Path $issueStruct.File).Path
    if($resolvedPath) {
        try {
            $newLine = "$($issueStruct.Prefix)$($issueStruct.Keyword)(#$($issueStruct.ID)): $($issueStruct.Title)"
            (Get-Content $resolvedPath) -replace $issueStruct.FullLine, $newLine | 
                Set-Content $resolvedPath -Force -ErrorAction:Stop
            return $true
        } catch {
            return $false
        }
    }
    return $false
}