using TodoGenieLib.Utils;
using TodoGenieLib.Functions;
using TodoGenieLib.Models;
using TodoGenieLib.Repositories;

ConfigModel config = Utils.ParseArgs(args);
Error.LogDirectory = $"{config.RootDirectory}\\.logs";

TodoFunctions todoFuncs = new();
List<TodoFileModel> todos = [];
GithubRepository gh = new();

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
                if(config.ShowUnreportedOnly && todo.Id > 0)
                    continue;
                
                Console.WriteLine(todo.FilePath + ":" + Convert.ToString(todo.LineNumber) + ": " + todo.Prefix!.Trim() + todo.Keyword!.Trim() + (todo.Id > 0 ? "(#"+todo.Id+")" : "") + ": " + todo.Title);    
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
            foreach(var todo in todoFile.Todos.Where(t => t.Id == 0)) {
                string? reply = string.Empty;
                
                while(string.IsNullOrEmpty(reply)) {
                    Console.Write($"Create TODO [{todo.Title}] in Github? (Y/N): ");
                    reply = Console.ReadLine();
                }

                if(!reply.Equals("Y", StringComparison.CurrentCultureIgnoreCase)) {
                    continue;
                }
                Console.WriteLine("Creating TODO...");
                if (todo.Id == 0) {
                    var res = TodoFunctions.CreateTodo(todo, config);

                    if (res.Id == 0) {
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
        config.GithubEndpoint = FileFunctions.GetGithubEndpoint(config.RootDirectory) + "?state=closed";
        if(string.IsNullOrEmpty(config.GithubEndpoint)) {
            Error.Critical("Unable to retrieve endpoint for Api");
        }

        var issues = gh.GetAllGithubIssues(config);
        foreach(var todoFiles in todos) {
            foreach(var todo in todoFiles.Todos.Where(t => t.Id != 0)) {
                if(issues.Any(i => i.Id == todo.Id)) {
                    string reply = string.Empty;
                    while(string.IsNullOrEmpty(reply)) {
                        Console.Write($"Found issue #{todo.Id} in closed state. Attempt to cleanup files? (Y/N): ");
                        reply = Console.ReadLine()!;
                    }
                    if(!reply.Equals("Y", StringComparison.CurrentCultureIgnoreCase)) {
                       continue;
                    }
                    
                    TodoFunctions.RemoveTodoInFile(todo);
                }
            }
        }
        break;
    default:
        Error.Critical($"Command not implemented: {config.Command}");
        break;
}
