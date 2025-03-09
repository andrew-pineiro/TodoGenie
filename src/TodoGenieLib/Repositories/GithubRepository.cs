using TodoGenieLib.Models;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Repositories;

public class GithubRepository {
    private static readonly string GithubURL = "https://github.com/andrew-pineiro/TodoGenie";
    private static readonly string BaseUrl = "https://api.github.com";
    public TodoModel CreateTodoOnGithub(TodoModel model, string apiKey, string endpoint) {
        HttpSender http = new();

        string body = $"**Created On:** {DateTime.Now.Date:U} <br />**Created By:** [TodoGenie]({GithubURL}) <br /><br />**Additional Comments:** <br/> {model.Body}";
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
            model.Id = replyModel.Location.ToString()[(replyModel.Location!.ToString().LastIndexOf('/')+1)..];

            //parse browser url from Location URL
            model.IssueUrl = replyModel.Location.ToString().Replace("api.", "").Replace("/repos", "");
        }
        return model;
         
    }
}