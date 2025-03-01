using TodoGenieLib.Utils;
using TodoGenieLib.Functions;

Error.LogDirectory = "C:\\Users\\Chill\\Repositories\\TodoGenie\\.logs";
//TODO: store in file
string token = "ZwBpAHQAaAB1AGIAXwBwAGEAdABfADEAMQBBAFkAQQA1AFcASwBBADAAZwB5AFcAZQAxADAAeQBuAGkATQBxAGwAXwBjAEIAZQBJAG4ASgA4AFgAagBJADcAOABaAHQAYgB1AFkAdgBRAGUANQByADYAUAA1AHIAYgBrAFkAZwBYAFAAYgBuAE0AaABsAFEAbwBXAEMAbABjAEsAMgBEAEEAMwBPAEMASQBaADIAaQBvAE4AeAB3AFQA";

//TODO: gather from .git
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
    var todos = TodoFunctions.GetTodoFromFile(file, dir);
    foreach(var todo in todos) {
        Console.WriteLine(todo.FilePath + ":" + Convert.ToString(todo.LineNumber) + ": " + todo.Prefix!.Trim() + todo.Keyword!.Trim() + todo.Id + ": " + todo.Title);    
    }
    foreach(var todo in todos.Where(t => string.IsNullOrEmpty(t.Id))) {
        Console.Write($"Create TODO [{todo.Title}] in Github? (Y/N): ");
        string? reply = Console.ReadLine();
        if(reply != "Y") {
            continue;
        }
        Console.WriteLine("Creating TODO...");
        if (string.IsNullOrEmpty(todo.Id)) {
            var res = TodoFunctions.CreateTodoOnGithub(todo, token, url, endpoint);
            if (res != System.Net.HttpStatusCode.OK) {
                Error.Write($"Http error {res}");
            }
        }
    }
}