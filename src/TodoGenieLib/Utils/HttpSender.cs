using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;

namespace TodoGenieLib.Utils;
public class HttpSender
{
    public HttpResponseMessage Send<T>(string apiKey, string method, T body, string baseAddress, string endpoint)
    {
        HttpClient sender = new()
        {
            BaseAddress = new Uri(baseAddress)
        };
        sender.DefaultRequestHeaders.Accept.Clear();
        sender.DefaultRequestHeaders.Accept.Add(
            new MediaTypeWithQualityHeaderValue("application/vnd.github.text+json")
            );
        sender.DefaultRequestHeaders.Add("User-Agent", "todogenie-v1.0");
        sender.DefaultRequestHeaders.Add("X-Github-Api-Version", "2022-11-28");
        sender.DefaultRequestHeaders.Add("Authorization", "Bearer " + apiKey);

        var _method = new HttpMethod(method);
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
        return response;
    }

}