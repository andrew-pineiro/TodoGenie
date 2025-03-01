using TodoGenieLib.Utils;
using TodoGenieLib.Functions;

FileFunctions funcs = new();
Error.LogDirectory = "C:\\Users\\Chill\\Repositories\\TodoGenie\\.logs";
if(args.Length < 1 || string.IsNullOrEmpty(args[0])) {
    Console.WriteLine($"Usage: .\\{AppDomain.CurrentDomain.FriendlyName} [git directory]");
    Error.Critical("insufficent arguments supplied");
}
var dir = args[0];

var files = funcs.GetAllValidFiles(dir);
foreach(var file in files) {
    var todos = TodoFunctions.GatherTodoForFile(file);
    foreach(var todo in todos) {
        Console.WriteLine(todo.FilePath + ":" + Convert.ToString(todo.LineNumber) + ": " + todo.Prefix!.Trim() + todo.Keyword!.Trim() + todo.Id + ": " + todo.Title);    
    }
}