namespace models;
public class TodoModel {
    
    // $issueStruct = @{
    //     Line     = $lineNumber
    //     File     = $item
    //     FullLine = $match[0].Value
    //     Prefix   = $rawPrefix.Length -gt $MaxPrefixLength ? [string]$rawPrefix[0..2] : [string]$rawPrefix
    //     Keyword  = $match[2].Value 
    //     ID       = $null
    //     Title    = $match[4].Value
    //     Body     = ''
    //     State    = ''
    // }
    public int LineNumber { get; set; }
    public string? FilePath { get; set; }
    public string? FullLine { get; set; }
    public string? Prefix { get; set; }
    public string? Keyword { get; set; }
    public int Id { get; set; }
    public string? Title { get; set; }
    public string? Body { get; set; }
    public string? State { get; set; }
}