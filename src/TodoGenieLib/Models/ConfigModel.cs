namespace TodoGenieLib.Models;

public class ConfigModel {
    public string GithubApiKey { get; set; } = string.Empty;
    public string RootDirectory { get; set; } = Environment.CurrentDirectory;
    public string SecretFileName { get; set; } = "secrets.json";
    public string ConfigDirectory { get; set; } = Path.Join(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),".todogenie");
    public string Command { get; set; } = "list";
    public List<string> ExcludedDirs { get; set; } = [];
}