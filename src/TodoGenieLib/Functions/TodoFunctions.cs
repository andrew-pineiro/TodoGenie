using TodoGenieLib.Models;
using System.Text.RegularExpressions;
using TodoGenieLib.Utils;

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
                    var rawPrefix = match.Groups[1].Value.Trim();

                    TodoModel model = new(){
                        LineNumber = lineNumber,
                        FilePath = filePath.Replace(rootDir+Path.DirectorySeparatorChar.ToString(), ""),
                        FullLine = match.Value,
                        Prefix = (rawPrefix.Length > TodoModel.MAX_PREFIX_LEN) ? rawPrefix[..TodoModel.MAX_PREFIX_LEN] : rawPrefix,
                        Keyword = match.Groups[2].Value,
                        Id = match.Groups[3].Value,
                        Title = match.Groups[4].Value,
                        Body = string.Empty,
                        State = string.Empty
                    };
                }
                lineNumber++;
            }
        } catch (Exception e) when (e is DirectoryNotFoundException || e is FileNotFoundException) {
            Error.Write($"File not found {filePath}");
        } catch (Exception e) {
            //log and crash if other exception besides not found
            Error.Critical($"Unexpected exception {e}");
        }
        
        return FileTodos;
    }
    public static TodoModel CreateTodoOnGithub(TodoModel model, string apiKey, string url, string endpoint) {
        HttpSender http = new();

        string body = $"**Created On:** {DateTime.Now.Date:U} <br />**Created By:** [TodoGenie]({GithubURL}) <br /><br />**Additional Comments:** <br/> {model.Body}";
        GithubModel.GithubSendModel gitModel = new() {
            Title = "[Automated] " + model.Title,
            Body = body
        };

        var res = http.Send(Crypt.Decrypt(apiKey), "POST", gitModel, url, endpoint);
        if(!res.IsSuccessStatusCode) {
            Error.Write($"Error creating Github issue: {res.ReasonPhrase}");
            return model;
        }
        var replyModel = res.Headers;
        if(replyModel.Location != null) {
            //parse id out of Location URL
            model.Id = replyModel.Location.ToString()[(replyModel.Location!.ToString().LastIndexOf('/')+1)..];

            //parse browser url from Location URL
            model.IssueUrl = replyModel.Location.ToString().Replace("api.", "").Replace("/repos", "");
        }
        return model;
         
    }
    public static void UpdateTodoInFile(TodoModel model) {
        if(string.IsNullOrEmpty(model.FilePath)) {
            Error.Write($"Unable to update Todo {model.Title} as FilePath does not exist");
            return;
        }

        var content = File.ReadAllLines(model.FilePath)
            //per line: check index + 1 (current line number) against known TODO line number
            //if found replace with (#id) and store line
            .Select((line, index) => index +1 == model.LineNumber
                ? line.Replace(model.Keyword!, $"{model.Keyword}(#{model.Id})")
                : line)
            .ToArray();

        File.WriteAllLines(model.FilePath, content);
    }
}