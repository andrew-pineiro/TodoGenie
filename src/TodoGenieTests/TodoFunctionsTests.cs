using TodoGenieLib.Functions;
using TodoGenieLib.Models;

namespace TodoGenieTests;
public class TodoFunctionsTests
{
    private readonly string _rootPath;

    public TodoFunctionsTests()
    {
        //TODO: improve how the root path is collected
        _rootPath = Path.Combine(Directory.GetParent(AppContext.BaseDirectory)!.Parent!.Parent!.Parent!.FullName, "Tests");
    }

    [Theory]
    [InlineData("SingleLineTodo.tst")]
    [InlineData("MultiLineTodo.tst")]
    public async Task ListTodos_ShouldReturnNotEmpty(string fileName)
    {
        string path = Path.Combine(_rootPath, fileName);
        var todos = await TodoFunctions.GetTodoFromFile(path, _rootPath);

        Assert.NotEmpty(todos);
        Assert.True(todos.Count == 2);
    }

    [Theory]
    [InlineData("MultiLineTodo.tst")]
    public async Task ListTodos_BodyCollectionNotEmpty(string fileName)
    {
        string path = Path.Combine(_rootPath, fileName);
        List<TodoModel> todos = await TodoFunctions.GetTodoFromFile(path, _rootPath);

        Assert.True(todos.Count == 2);

        foreach (TodoModel todoModel in todos)
        {
            Assert.NotEmpty(todoModel.Body);
        }
    }

    [Theory]
    [InlineData("SingleLineTodo.tst")]
    [InlineData("MultiLineTodo.tst")]
    public async Task CreateTodos_ShouldNotReturnEmpty(string fileName)
    {
        string path = Path.Combine(_rootPath, fileName);
        List<TodoModel> todos = await TodoFunctions.GetTodoFromFile(path, _rootPath);

        Assert.True(todos.Where(t => t.Id == 0).Count() == 1);

        foreach (var todo in todos.Where(t => t.Id == 0))
        {
            Assert.Equal(0, todo.Id);
        }
    }

    [Theory]
    [InlineData("SingleLineTodo.tst")]
    [InlineData("MultiLineTodo.tst")]
    public async Task PruneTodos_ShouldNotReturnEmpty(string fileName)
    {
        string path = Path.Combine(_rootPath, fileName);
        List<TodoModel> todos = await TodoFunctions.GetTodoFromFile(path, _rootPath);

        Assert.True(todos.Where(t => t.Id > 0).Count() == 1);

        foreach (var todo in todos.Where(t => t.Id > 0))
        {
            Assert.NotEqual(0, todo.Id);
        }
    }
}