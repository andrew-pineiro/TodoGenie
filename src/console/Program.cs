﻿FileHandler handler = new();
Error.LogDirectory = "C:\\Users\\Chill\\Repositories\\TodoGenie\\.logs";
if(args.Length < 1) {
    Console.WriteLine("Usage: .\\TodoGenie.exe [git directory]");
    Error.Write("insufficent arguments supplied");
}
var dir = args[0];

var files = handler.GetAllValidFiles(dir);
foreach(var file in files) {
    var todo = Todo.GatherTodoForFile(handler.ReadFile(file));
    if(!string.IsNullOrEmpty(todo)) { Console.WriteLine(todo); }
}