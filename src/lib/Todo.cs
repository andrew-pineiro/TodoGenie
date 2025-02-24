using models;
using System.Text.RegularExpressions;
public static class Todo {
    
    public static readonly string TodoRegex = @"^(.*)(TODO)(.*):\s*(.*)";

    public static string GatherTodoForFile(string contents) {
        TodoModel model = new();
        var match = Regex.Match(contents , TodoRegex);
        return match.Value;
    }
}