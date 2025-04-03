using System.Text.RegularExpressions;
using TodoGenieLib.Models;
using TodoGenieLib.Repositories;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Functions;
public class TodoFunctions {
    
    private static readonly string TodoRegex = @"^(.*)(TODO|FIXME)(.*):\s*(.*)";
    private static readonly string[] ValidPrefix = ["//", "#", "REM", "'", "*", "<--"];
    public static async Task<List<TodoModel>> GetTodoFromFile(string filePath, string rootDir) {
        List<TodoModel> FileTodos = [];
        try {
            var contents = await File.ReadAllLinesAsync(filePath);
            for(int i = 0; i < contents.Length; i++) {
                var match = Regex.Match(contents[i], TodoRegex);
                if(match.Success) {
                    var rawPrefix = match.Groups[1].Value.Trim();
                    var rawidString = match.Groups[3].Value.Replace("#", "").Replace("(", "").Replace(")", "");
                    if(!int.TryParse(rawidString, out int rawId)) rawId = 0;
                    TodoModel model = new(){
                        LineNumber = i+1,
                        FilePath = filePath.Replace(rootDir+Path.DirectorySeparatorChar.ToString(), ""),
                        FullLine = match.Value,
                        Prefix = (rawPrefix.Length > TodoModel.MAX_PREFIX_LEN) ? rawPrefix[..TodoModel.MAX_PREFIX_LEN] : rawPrefix,
                        Keyword = match.Groups[2].Value,
                        Id = rawId,
                        Title = match.Groups[4].Value
                    };
                    if(!ValidPrefix.Contains(model.Prefix.Trim())) {
                        model.Prefix = "";
                    }
                    if(model.Title.Length < 5) {
                        continue;
                    }

                    //BODY COLLECTION
                    int tempBodyIndex = i+1;
                    int bodyCount = 0;
                    while (SystemRepository.TryGetValue(contents, tempBodyIndex, out string val)
                            && !string.IsNullOrEmpty(model.Prefix) 
                            && contents[tempBodyIndex].Trim().StartsWith(model.Prefix)
                            && bodyCount < TodoModel.MAX_BODY_LEN)
                    {
                        model.Body.Add(val.Trim());
                        
                        bodyCount++;
                        tempBodyIndex++;
                    }
                    FileTodos.Add(model);
                }
            }
        } catch (Exception e) when (e is DirectoryNotFoundException || e is FileNotFoundException) {
            Error.Write($"File not found {filePath}");
        } catch (Exception e) {
            //log and crash if other exception besides not found
            Error.Critical($"Unexpected exception {e}");
        }
        
        return FileTodos;
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
    public static void RemoveTodoInFile(TodoModel model) {
        if(string.IsNullOrEmpty(model.FilePath)) {
            Error.Write($"Unable to update Todo {model.Title} as FilePath does not exist");
            return;
        }

        var content = File.ReadAllLines(model.FilePath)
                .Select((line, index) => index+1 == model.LineNumber
                    ? line.Replace(model.FullLine!, "")
                    : line)
                .ToArray();
        
        File.WriteAllLines(model.FilePath, content);
    }
    public static TodoModel CreateTodo(TodoModel todo, ConfigModel config) {
        GithubRepository ghRepo = new();
        return ghRepo.CreateTodoOnGithub(todo, config.GithubApiKey, config.GithubEndpoint);
    }
    public static void CommitTodo(TodoModel todo) {
        SystemRepository.ExecuteGitCommand($"add {todo.FilePath}");
        SystemRepository.ExecuteGitCommand($"commit -m \"Added TODO #{todo.Id}\"");
        SystemRepository.ExecuteGitCommand("push");
    }
}
