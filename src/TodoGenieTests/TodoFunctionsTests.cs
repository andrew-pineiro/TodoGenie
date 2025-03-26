using System.Threading.Tasks;
using TodoGenieLib.Functions;

namespace TodoGenieTests;
public class TodoFunctionsTests
{
    private readonly string _rootPath;

    public TodoFunctionsTests()
    {
        _rootPath = Path.Combine(Directory.GetParent(AppContext.BaseDirectory)!.Parent!.Parent!.Parent!.FullName, "Tests");
    }

    [Theory]
    [InlineData("SingleLineTodo.tst")]
    [InlineData("MultiLineTodo.tst")]
    public async Task ListTodos_ShouldReturnNotEmpty(string fileName)
    {
        string path = Path.Combine(_rootPath, fileName);
        var todo = await TodoFunctions.GetTodoFromFile(path, Directory.GetCurrentDirectory());

        Assert.NotEmpty(todo);
    }
}