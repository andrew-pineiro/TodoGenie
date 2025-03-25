using System.Text.Json.Serialization;

namespace TodoGenieLib.Models;
public class TodoModel {
    public const int MAX_PREFIX_LEN = 4;
    public const int MAX_BODY_LEN = 5;

    
    public int LineNumber { get; set; }
    public string? FilePath { get; set; }
    public string? FullLine { get; set; }
    public string? Prefix { get; set; }
    public string? Keyword { get; set; }
    
    [JsonPropertyName("number")]
    public int Id { get; set; } 
    public required string Title { get; set; }
    public List<string> Body { get; set; } = [];
    public string? State { get; set; }
    public string? IssueUrl { get; set; }
}