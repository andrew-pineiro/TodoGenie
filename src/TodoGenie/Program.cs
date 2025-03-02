using TodoGenieLib.Utils;
using TodoGenieLib.Functions;

const string ROOT_DIR = "C:\\Users\\Chill\\Repositories\\TodoGenie";

Error.LogDirectory = $"{ROOT_DIR}\\.logs";

//TODO: store apiToken in file
string token = string.Empty;
try {
    token = File.ReadAllText($"{ROOT_DIR}\\token.secret")
} catch (Exception e) {
    Error.Critical($"Unable to find Github Token: {e.Message}");
}

//TODO: gather project details from .git
string url = "https://api.github.com";
string endpoint = "/repos/andrew-pineiro/TodoGenie/issues";

if(args.Length < 1 || string.IsNullOrEmpty(args[0])) {
    Console.WriteLine($"Usage: .\\{AppDomain.CurrentDomain.FriendlyName} [git directory]");
    Error.Critical("insufficent arguments supplied");
}

FileFunctions funcs = new();
var dir = ".";
var files = funcs.GetAllValidFiles(dir);

foreach(var file in files) {
    //TODO: split listing, creating, and pruning into sub commands. Currently it goes file by file and does all.
    //TODO: allow for directory exclusions
    //TODO: work on arg parsing
    //TODO: match args to powershell version

    var todos = TodoFunctions.GetTodoFromFile(file, dir);
    foreach(var todo in todos) {
        Console.WriteLine(todo.FilePath + ":" + Convert.ToString(todo.LineNumber) + ": " + todo.Prefix!.Trim() + todo.Keyword!.Trim() + todo.Id + ": " + todo.Title);    
    }

    foreach(var todo in todos.Where(t => string.IsNullOrEmpty(t.Id))) {
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
            var res = TodoFunctions.CreateTodoOnGithub(todo, token, url, endpoint);
            if (string.IsNullOrEmpty(res.Id)) {
                Error.Write($"Could not create Git issue");
            }
            Console.WriteLine($"Created Issue: {res.Id} [{res.IssueUrl}]");
            
            TodoFunctions.UpdateTodoInFile(res);
            Console.WriteLine($"Updated TODO in File {res.FilePath}");
        }
    }
}