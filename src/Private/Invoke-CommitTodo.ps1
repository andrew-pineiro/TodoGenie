function Invoke-CommitTodo {
    [CmdletBinding()]
    param (
        $IssueList,
        $RootDirectory
    )

    Push-Location $RootDirectory
    foreach($Issue in $IssueList) {
        try {
            switch($Issue.State) {
                "closed" {$CommitWord = "Removed"}
                default {$CommitWord = "Added"}
            }
            $commitMsg = "$CommitWord $($Issue.Keyword)(#$($Issue.ID)): $($Issue.Title)"
            Invoke-Command -ScriptBlock { git add $Issue.File} -ErrorAction:Stop
            Invoke-Command -ScriptBlock { git commit -m "$commitMsg"} -ErrorAction:Stop
            Invoke-Command -ScriptBlock { git push } -ErrorAction:Stop
        } catch {
            Write-Error $_
            break 1
        }
    }   
}