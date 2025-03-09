using TodoGenieLib.Utils;
using TodoGenieLib.Functions;
using TodoGenieLib.Models;
using TodoGenieLib.Repositories;

ConfigModel config = Utils.ParseArgs(args);
Error.LogDirectory = $"{config.RootDirectory}\\.logs";

TodoFunctions todoFuncs = new();
List<TodoFileModel> todos = [];
GithubRepository gh = new();
var endpoint = FileFunctions.GetGithubEndpoint(config.RootDirectory);
if(string.IsNullOrEmpty(endpoint)) {
    Error.Critical("no endpoint");
}
gh.GetAllGithubIssues(config.GithubApiKey, endpoint);
return;
var files = FileFunctions.GetAllValidFiles(config.RootDirectory!, config.ExcludedDirs);
if(config.Command != "config") {
    foreach(var file in files) {
        todos.Add(new TodoFileModel() {
            File = file,
            Todos = TodoFunctions.GetTodoFromFile(file, config.RootDirectory!).Result
        }); 
    }    
}
switch(config.Command) {
    case "list":
        foreach(var todoFile in todos) {
            foreach(var todo in todoFile.Todos) {
                if(config.ShowUnreportedOnly && !string.IsNullOrEmpty(todo.Id))
                    continue;
                
                Console.WriteLine(todo.FilePath + ":" + Convert.ToString(todo.LineNumber) + ": " + todo.Prefix!.Trim() + todo.Keyword!.Trim() + todo.Id + ": " + todo.Title);    
            }
        }
        break;
    case "create":
        config.GithubEndpoint = FileFunctions.GetGithubEndpoint(config.RootDirectory);

        if(string.IsNullOrEmpty(config.GithubEndpoint)) {
            Error.Critical("Unable to set API endpoint from .git config file.");
        }
        if(string.IsNullOrEmpty(config.GithubApiKey)) {
            Error.Critical("No Github Api Key found.");
        }
        foreach(var todoFile in todos) {
            foreach(var todo in todoFile.Todos.Where(t => string.IsNullOrEmpty(t.Id))) {
                string? reply = string.Empty;
                
                while(string.IsNullOrEmpty(reply)) {
                    Console.Write($"Create TODO [{todo.Title}] in Github? (Y/N): ");
                    reply = Console.ReadLine();
                }

                if(!reply.Equals("Y", StringComparison.CurrentCultureIgnoreCase)) {
                    continue;
                }
                Console.WriteLine("Creating TODO...");
                if (string.IsNullOrEmpty(todo.Id)) {
                    var res = TodoFunctions.CreateTodo(todo, config);

                    if (string.IsNullOrEmpty(res.Id)) {
                        continue;
                    }

                    Console.WriteLine($"Created Issue: {res.Id} [{res.IssueUrl}]");
                    
                    TodoFunctions.UpdateTodoInFile(res);
                    Console.WriteLine($"Updated TODO in File {res.FilePath}");
                }
            }
        }
        break;
    case "config":
        if(string.IsNullOrEmpty(config.GithubApiKey)) {
            Error.Critical("Must specify --apiKey when using `config` command");
        }
        ConfigFunctions.SetConfig(config);
        break;
    case "prune":
    default:
        Error.Critical($"Command not implemented: {config.Command}");
        break;
}
