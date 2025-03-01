namespace TodoGenieLib.Models;
public class TodoModel {
    public const int MAX_PREFIX_LEN = 3;

    
    public int LineNumber { get; set; }
    public string? FilePath { get; set; }
    public string? FullLine { get; set; }
    public string? Prefix { get; set; }
    public string? Keyword { get; set; }
    public string? Id { get; set; }
    public required string Title { get; set; }
    public string? Body { get; set; }
    public string? State { get; set; }
}