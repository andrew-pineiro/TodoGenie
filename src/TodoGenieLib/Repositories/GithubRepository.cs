using System.Net.Http.Json;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Repositories;

public class GithubRepository {
    private static readonly string GithubURL = "https://github.com/andrew-pineiro/TodoGenie";
    private static readonly string BaseUrl = "https://api.github.com";
    public TodoModel CreateTodoOnGithub(TodoModel model, string apiKey, string endpoint) {
        HttpSender http = new();
        string rawBody = String.Join("\n", model.Body).Replace(model.Prefix!, "");
        string body = $"**Created On:** {DateTime.Now.Date:U} <br />**Created By:** [TodoGenie]({GithubURL}) <br />**File:** {model.FilePath} <br />**Line #:** {model.LineNumber} <br /><br />**Additional Comments:** <br/> {rawBody}";
        GithubModel.GithubSendModel gitModel = new() {
            Title = "[Automated] " + model.Title,
            Body = body
        };

        var res = http.Send(Crypt.Decrypt(apiKey), "POST", gitModel, BaseUrl, endpoint);
        if(!res.IsSuccessStatusCode) {
            Error.Write($"Error creating Github issue: {res.ReasonPhrase}");
            return model;
        }
        var replyModel = res.Headers;
        if(replyModel.Location != null) {
            //parse id out of Location URL
            model.Id = int.Parse(replyModel.Location.ToString()[(replyModel.Location!.ToString().LastIndexOf('/')+1)..]);

            //parse browser url from Location URL
            model.IssueUrl = replyModel.Location.ToString().Replace("api.", "").Replace("/repos", "");
        }
        return model;
         
    }

    public List<TodoModel> GetAllGithubIssues(ConfigModel config) {
        List<TodoModel> issues = [];
        HttpSender http = new();
        var res = http.Send(Crypt.Decrypt(config.GithubApiKey), "GET", "", BaseUrl, config.GithubEndpoint);
        var content = res.Content.ReadFromJsonAsync<List<TodoModel>>().Result;
        if(!res.IsSuccessStatusCode || content!.Count == 0) {
            Error.Critical($"Could not retrieve Github issues. Status: {res.StatusCode}");
        }
        return content!;
    }
}