namespace TodoGenieLib.Models;

public class TodoFileModel {
    public string? File { get; set; }

    public List<TodoModel> Todos { get; set; } = [];
}