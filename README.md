# PSIssueCreator

## Purpose
Generate GitHub issues based off of your commented TODO's, natively in Windows. Works for all programming style comments. 

Only tested in Windows operating system.

## Setup

Move all files in repository to any of the `$env:PSModulePath` directories under the name `PSIssueCreator`. Once you reload powershell, you can type `Get-Module PSIssueCreator` to pull in the command `Invoke-IssueCreator`. This command needs to be run in a directory that contains a `.git` folder.

## Contributors
* Andrew Pineiro