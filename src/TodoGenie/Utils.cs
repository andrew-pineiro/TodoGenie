using TodoGenieLib.Functions;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

public static class Utils {
    public static ConfigModel ParseArgs(string[] args) {
        ConfigModel config = new();
        config = FileFunctions.SetupConfigDir(config);
        int argCount = args.Length;
        if (argCount < 1) {
            return config;
        }
        for(int i = 0; i < argCount; i++) {
            try {
                switch(args[i]) {
                    case "--command":
                        var tempCommand = args[i+1].ToLower();
                        if(!new List<string>{"list", "prune", "create", "config"}.Contains(tempCommand)) {
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
}