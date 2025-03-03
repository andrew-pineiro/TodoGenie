using TodoGenieLib.Utils;
using TodoGenieLib.Functions;
using TodoGenieLib.Models;
    
// if(args.Length < 1 || string.IsNullOrEmpty(args[0])) {
//     Console.WriteLine($"Usage: .\\{AppDomain.CurrentDomain.FriendlyName} [git directory]");
//     Console.WriteLine("ERROR: Insufficent arguments supplied");
//     Environment.Exit(1);
// }

ConfigModel config = Utils.ParseArgs(args);
Error.LogDirectory = $"{config.RootDirectory}\\.logs";

FileFunctions funcs = new();
List<TodoFileModel> todos = [];

var files = funcs.GetAllValidFiles(config.RootDirectory!, config.ExcludedDirs);
if(config.Command != "config") {
    foreach(var file in files) {
        //TODO: allow for directory exclusions
        //TODO: match args to powershell version
        todos.Add(new TodoFileModel() {
            File = file,
            Todos = TodoFunctions.GetTodoFromFile(file, config.RootDirectory!)
        }); 
    }    
}
switch(config.Command) {
    case "list":
        foreach(var todoFile in todos) {
            foreach(var todo in todoFile.Todos) {
                Console.WriteLine(todo.FilePath + ":" + Convert.ToString(todo.LineNumber) + ": " + todo.Prefix!.Trim() + todo.Keyword!.Trim() + todo.Id + ": " + todo.Title);    
            }
        }
        break;
    case "create":
        //TODO: gather project details from .git
        string url = "https://api.github.com";
        string endpoint = FileFunctions.GetGithubEndpoint(config.RootDirectory);

        if(string.IsNullOrEmpty(endpoint)) {
            Error.Critical("Unable to set Github API endpoint from .git config file.");
        }
        if(string.IsNullOrEmpty(config.GithubApiKey)) {
            Error.Critical("Api Key is not valid");
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
                    var res = TodoFunctions.CreateTodoOnGithub(todo, config.GithubApiKey!, url, endpoint);

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
        FileFunctions.SetConfig(config);
        break;
    case "prune":
    default:
        Error.Critical($"Command not implemented: {config.Command}");
        break;
}
