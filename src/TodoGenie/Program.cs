using TodoGenieLib.Utils;
using TodoGenieLib.Functions;
using System.Text.Json;
using System.Text;

const string ROOT_DIR = "C:\\Users\\Chill\\Repositories\\TodoGenie";
const string CONFIG_DIR = "C:\\Users\\Chill\\.todogenie";
const string SECRET_FILE = "secrets.json";

Error.LogDirectory = $"{ROOT_DIR}\\.logs";
    
if(args.Length < 1 || string.IsNullOrEmpty(args[0])) {
    Console.WriteLine($"Usage: .\\{AppDomain.CurrentDomain.FriendlyName} [git directory]");
    Error.Critical("insufficent arguments supplied");
}

ConfigModel config = new();

//TODO: move this to the library
if(!Directory.Exists(CONFIG_DIR)) {

    Directory.CreateDirectory(CONFIG_DIR);
    var stream = File.Create(Path.Join(CONFIG_DIR, SECRET_FILE));
    string tempKey = string.Empty;
    while(string.IsNullOrEmpty(tempKey)) {
        Console.Write("Github Api Token: ");
        tempKey = Console.ReadLine()!;
    }
    config.GithubApiKey = Crypt.Encrypt(tempKey);

    var contents = new UTF8Encoding(true).GetBytes("{ \"GithubApiKey\": \"" + config.GithubApiKey + "\" }");
    stream.Write(contents, 0, contents.Length);
    stream.Close();
}

//TODO: only check for token if using create/prune commands
try {

    var rawConfigFile = File.ReadAllText(Path.Join(CONFIG_DIR, SECRET_FILE));
    config = JsonSerializer.Deserialize<ConfigModel>(rawConfigFile)!;

} 
    catch (Exception e) 
{
    Error.Critical($"Unable to set Github Token: {e.Message}");
}

if(string.IsNullOrEmpty(config.GithubApiKey)) {
    Error.Critical("Api Key is not valid");
}

//TODO: gather project details from .git
string url = "https://api.github.com";
string endpoint = "/repos/andrew-pineiro/TodoGenie/issues";


FileFunctions funcs = new();
var dir = args[0];
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