using System.Text;
using System.Text.Json;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Functions;

public static class ConfigFunctions {
    public static ConfigModel SetupConfigDir(ConfigModel config) {
        if(!Directory.Exists(config.ConfigDirectory) && !string.IsNullOrEmpty(config.ConfigDirectory)) {
            Directory.CreateDirectory(config.ConfigDirectory);
        }
        string secretFile = Path.Join(config.ConfigDirectory, config.SecretFileName); 
        if(!File.Exists(secretFile)) {
            string tempKey = string.Empty;
            while(string.IsNullOrEmpty(tempKey)) {
                Console.Write("Enter Github Api Key: ");
                tempKey = Console.ReadLine()!;
            }
            
            config.GithubApiKey = Crypt.Encrypt(tempKey);
   
            var stream = File.Create(secretFile);
            var contents = new UTF8Encoding(true).GetBytes("{ \"GithubApiKey\": \"" + config.GithubApiKey + "\" }");
   
            stream.Write(contents, 0, contents.Length);
            stream.Close();
        }    
        return config;
    }
    public static void SetConfig(ConfigModel config) {
        string secretFile = Path.Join(config.ConfigDirectory, config.SecretFileName); 
        File.WriteAllText(secretFile, "{ \"GithubApiKey\": \"" + Crypt.Encrypt(config.GithubApiKey) + "\" }");
    }
    public static string GetApiKey(ConfigModel config) {
        var contents = File.ReadAllText(Path.Join(config.ConfigDirectory,config.SecretFileName));
        string returnKey = string.Empty;
        try {
            var tempConfig = JsonSerializer.Deserialize<ConfigModel>(contents);
            returnKey = tempConfig!.GithubApiKey;

        } catch (Exception e) {
            Error.Critical($"Unable to set ApiKey from File {e.Message}");
        }
        if(string.IsNullOrEmpty(returnKey)) {
            Error.Critical($"Unable to set ApiKey from File.");
        }
        return returnKey;
    }
}