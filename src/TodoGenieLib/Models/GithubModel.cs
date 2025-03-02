using System.Text.Json.Serialization;

namespace TodoGenieLib.Models;

public class GithubModel {
    public class GithubSendModel {
        [JsonPropertyName("title")]
        public required string Title { get; set; }
        [JsonPropertyName("body")]
        public string? Body { get; set; }
    }
}