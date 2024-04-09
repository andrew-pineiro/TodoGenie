function Invoke-PushTodo {
    try {
        $Result = Invoke-Command -ScriptBlock { git log --branches --not --remotes } -ErrorAction:Stop
        if($Result.Length -gt 0) {
            Invoke-Command -ScriptBlock { git push } -ErrorAction:Stop
        }
    } catch {
        Write-Error $_
        break 1
    }
}