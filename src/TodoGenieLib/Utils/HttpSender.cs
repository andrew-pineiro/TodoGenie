using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using TodoGenieLib.Models;

namespace TodoGenieLib.Utils;
public class HttpSender
{
    public HttpResponseMessage Send<T>(string apiKey, string method, GithubModel body, string baseAddress, string endpoint)
    {
        HttpClient sender = new()
        {
            BaseAddress = new Uri(baseAddress)
        };
        sender.DefaultRequestHeaders.Accept.Clear();
        sender.DefaultRequestHeaders.Accept.Add(
            new MediaTypeWithQualityHeaderValue("application/vnd.github+json")
            );
        sender.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Authorization", "Bearer " + apiKey);
        sender.DefaultRequestHeaders.Add("X-Github-Api-Version", "2022-11-28");
        var _method = new HttpMethod(method);
        Console.WriteLine($"DEBUG: Sending HTTP {method} Request to {baseAddress}{endpoint}: {body.Title} - {body.Body}");
        HttpResponseMessage response = _method.ToString().ToUpper() switch
        {
            "GET" => sender.GetAsync(endpoint).Result,
            "POST" => sender.PostAsJsonAsync(endpoint, body,
                                new System.Text.Json.JsonSerializerOptions { DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull }
                                ).Result,
            "PUT" => sender.PutAsJsonAsync(endpoint, body,
                                new System.Text.Json.JsonSerializerOptions { DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull }
                                ).Result,
            "DELETE" => sender.DeleteAsync(endpoint).Result,
            _ => throw new NotImplementedException(),
        };
        Console.WriteLine($"DEBUG: {response.StatusCode} {response.Content}");
        return response;
    }

}