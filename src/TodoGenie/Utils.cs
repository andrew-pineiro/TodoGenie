using System.Text;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

public static class Utils {
    public static ConfigModel ParseArgs(string[] args) {
        ConfigModel config = new();
        config = SetupConfigDir(config);
        int argCount = args.Length;
        if (argCount < 1) {
            return config;
        }
        for(int i = 0; i < argCount; i++) {
            try {
                switch(args[i]) {
                    case "--command":
                        var tempCommand = args[i+1].ToLower();
                        if(!new List<string>{"list", "prune", "create"}.Contains(tempCommand)) {
                            Error.Critical("Expected one of the following commands: list, prune, create, config");
                        }
                        config.Command = tempCommand;
                        break;
                    case "--apiKey":
                        config.GithubApiKey = args[i+1];
                        break;
                    case "--rootdir":
                        config.RootDirectory = args[i+1];
                        break;
                    case "--exclude":
                        foreach(var dir in args[i+1].Split(',')) {
                            config.ExcludedDirs.Add(dir);
                        }
                        break;
                    default:
                        break;
                }
            } catch (Exception e) when (e is IndexOutOfRangeException)  {
                Error.Critical($"No valid argument specified for {args[i]}");
            } catch (Exception e) {
                Error.Critical($"Could not parse args {e.Message}");
            }
        }
        return config;
    }
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
    public static void SetConfig(ConfigModel config) {
        //TODO: setup saving to config file
        return;
    }
    public static string GetGithubEndpoint(string rootDir) {
        string endpoint = string.Empty;
        //TODO: get project info for api url from .git directory.

        return endpoint;
    }
}