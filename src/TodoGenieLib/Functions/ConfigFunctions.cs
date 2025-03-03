using System.Text;
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
            var stream = File.Create(secretFile);
            string tempKey = string.Empty;
            while(string.IsNullOrEmpty(tempKey)) {
                Console.Write("Enter Github Api Key: ");
                tempKey = Console.ReadLine()!;
            }
            
            config.GithubApiKey = Crypt.Encrypt(tempKey);
   
            var contents = new UTF8Encoding(true).GetBytes("{ \"GithubApiKey\": \"" + config.GithubApiKey + "\" }");
   
            stream.Write(contents, 0, contents.Length);
            stream.Close();
        }    
        return config;
    }
}