function Invoke-CommitTodo {
    [CmdletBinding()]
    param (
        $issue,
        $rootDirectory
    )

    try {
        Push-Location $rootDirectory
        switch($issue.State) {
            "closed" {$commitWord = "Removed"}
            default {$commitWord = "Added"}
        }
        $commitMsg = "$commitWord $($issue.Keyword)(#$($issue.ID)): $($issue.Title)"
        
        if($(Invoke-Command -ScriptBlock { git status }) -notlike "nothing to commit") {
            Write-Host "Existing changes present in .git directory. Push new TODO anyway? (Y/N): " -NoNewline
            $response = Read-Host
            if($response -ne "Y") { 
                Pop-Location
                break 
            }
        } 

        Invoke-Command -ScriptBlock { git add $issue.File} -ErrorAction:Stop
        Invoke-Command -ScriptBlock { git commit -m "$commitMsg"} -ErrorAction:Stop
        Invoke-Command -ScriptBlock { git push } -ErrorAction:Stop
        
    } catch {
        Write-Error $_
        break 1
    } finally {
        Pop-Location
    }
    
}