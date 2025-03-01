using TodoGenieLib.Models;
using System.Text.RegularExpressions;
using TodoGenieLib.Utils;
using System.Net;

namespace TodoGenieLib.Functions;
public static class TodoFunctions {
    
    private static readonly string TodoRegex = @"^(.*)(TODO)(.*):\s*(.*)";
    private static readonly string GithubURL = "https://github.com/andrew-pineiro/TodoGenie";

    public static List<TodoModel> GetTodoFromFile(string filePath, string rootDir) {
        List<TodoModel> FileTodos = [];
        try {
            var contents = File.ReadAllLines(filePath);
            int lineNumber = 1;
            
            foreach(var line in contents) {
                var match = Regex.Match(line, TodoRegex);
                if(match.Success) {
                    _ = filePath.Replace($".{Path.DirectorySeparatorChar}", "");
                    _ = rootDir.Replace($".{Path.DirectorySeparatorChar}", "");
                    var rawPrefix = match.Groups[1].Value.Trim();

                    TodoModel model = new(){
                        LineNumber = lineNumber,
                        FilePath = filePath.Replace(rootDir, ""),
                        FullLine = match.Value,
                        Prefix = (rawPrefix.Length > TodoModel.MAX_PREFIX_LEN) ? rawPrefix[..TodoModel.MAX_PREFIX_LEN] : rawPrefix,
                        Keyword = match.Groups[2].Value,
                        Id = match.Groups[3].Value,
                        Title = match.Groups[4].Value,
                        Body = string.Empty,
                        State = string.Empty
                    };

                    FileTodos.Add(model);
                }
                lineNumber++;
            }
        } catch (Exception e) when (e is DirectoryNotFoundException || e is FileNotFoundException) {
            Error.Write($"file not found {filePath}");
        } catch (Exception e) {
            Error.Critical($"unexpected exception {e}");
        }
        
        return FileTodos;
    }
    public static HttpStatusCode CreateTodoOnGithub(TodoModel model, string apiKey, string url, string endpoint) {
        HttpSender http = new();

        string body = $"**Created On:** {DateTime.Now.Date:U} <br />**Created By:** [TodoGenie]({GithubURL}) <br /><br />**Additional Comments:** <br/> {model.Body}";
        GithubModel gitModel = new() {
            Title = "[Automated] " + model.Title,
            Body = body
        };
        //FIXME: keep getting 400 reply...
        var res = http.Send<GithubModel>(Crypt.Decrypt(apiKey), "POST", gitModel, url, endpoint);
        Console.WriteLine($"DEBUG: {res}");
        return res.StatusCode;
         
    }
}