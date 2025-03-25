using TodoGenieLib.Functions;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

public static class Utils {
    public static void PrintUsage() {
        Console.WriteLine("USAGE: todogenie (list, prune, create) [--GitDirectory (--dir, -D) [string]] [--exclude (-X) [string[]]] [--NoAutoCommit] [--Unreported (-U)]");
    }
    public static void PrintHelp() {
        PrintUsage();
        Console.WriteLine("\nARGUMENTS");
        Console.WriteLine("\n---- Global ----\n");
        Console.WriteLine("--Exclude [-X] - Directories to exclude");
        Console.WriteLine("--GitDirectory [--dir, -d] - Directory to base TodoGenie in. Needs to have a .git folder");
        Console.WriteLine("\n---- List ----\n");
        Console.WriteLine("--Unreported [-u]- Shows only Todos that are unreported to Github");
        Console.WriteLine("\n---- Create ----\n");
        Console.WriteLine("--NoAutoCommit - Doesn't commit updated Todo to Github automatically.");
        Console.WriteLine("\n---- Prune ----\n");
        Console.WriteLine("");
        Console.WriteLine("\n---- Config ----\n");
        Console.WriteLine("--ApiKey - Github Api token for creating issues. This will overwrite any existing token");


    }
    public static ConfigModel ParseArgs(string[] args) {
        ConfigModel config = new();

        int argCount = args.Length;
        if (argCount < 1) {
            config.GithubApiKey = ConfigFunctions.GetApiKey(config);
            return config;
        }

        var tempCommand = args[0].ToLower();
        if(new List<string>{"--help", "-h", "?"}.Contains(tempCommand)) {
            PrintHelp();
            Environment.Exit(0);
        }
        if(!new List<string>{"list", "prune", "create", "config"}.Contains(tempCommand)) {
            PrintUsage();
            Error.Critical("Expected one of the following commands: list, prune, create, config");
        }
        config.Command = tempCommand;
        for(int i = 0; i < argCount; i++) {
            try {
                switch(args[i].ToLower()) {
                    case "--apikey":
                        config.GithubApiKey = args[i+1];
                        break;
                    case "--gitdirectory": case "--dir": case "-d":
                        config.RootDirectory = args[i+1];
                        break;
                    case "--unreported": case "-u":
                        config.ShowUnreportedOnly = true;
                        break;
                    case "--exclude": case "-x":
                        foreach(var dir in args[i+1].Split(',')) {
                            config.ExcludedDirs.Add(dir);
                        }
                        break;
                    case "--noautocommit": case "-n":
                        config.NoAutoCommit = true;
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
        if(string.IsNullOrEmpty(config.GithubApiKey)) {
            config.GithubApiKey = ConfigFunctions.GetApiKey(config);
        }
        return config;
    }    
}