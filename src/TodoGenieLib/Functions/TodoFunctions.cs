using Models;
using System.Text.RegularExpressions;

namespace Functions;
public static class TodoFunctions {
    
    public static readonly string TodoRegex = @"^(.*)(TODO)(.*):\s*(.*)";

    public static List<TodoModel> GatherTodoForFile(string filePath) {
        List<TodoModel> FileTodos = new();
        FileFunctions file = new();
        var contents = file.ReadFile(filePath);
        int lineNumber = 1;
        foreach(var line in contents) {
            var match = Regex.Match(line, TodoRegex);
            if(match.Success) {
                TodoModel model = new();
                if(filePath.StartsWith(@".\") || filePath.StartsWith("./")) {
                    filePath = filePath.Substring(2);
                }
                model.FilePath = filePath;
                model.LineNumber = lineNumber;
                model.FullLine = match.Value;
                var rawPrefix = match.Groups[1].Value;
                model.Prefix = (rawPrefix.Length > TodoModel.MAX_PREFIX_LEN) ? rawPrefix.Substring(0,3) : rawPrefix;
                model.Keyword = match.Groups[2].Value;
                model.Id = match.Groups[3].Value;
                model.Title = match.Groups[4].Value;

                FileTodos.Add(model);
            }
            lineNumber++;
        }
        
        return FileTodos;
    }
}