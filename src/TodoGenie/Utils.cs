using TodoGenieLib.Functions;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

public static class Utils {
    public static void PrintUsage() {
        Console.WriteLine("USAGE: Invoke-Genie (list, prune, create) [--GitDirectory [string]] [--TestMode] [--TestDirectory [string]] [--NoAutoCommit] [--Unreported]");
    }
    public static void PrintHelp() {
        PrintUsage();
        Console.WriteLine("\nARGUMENTS");
        Console.WriteLine("\n---- Global ----\n");
        Console.WriteLine("--TestMode [-t] - Enables testing mode which runs through all subcommands in the specified -TestDirectory");
        Console.WriteLine("--TestDirectory [-td] - Directory to run tests in");
        Console.WriteLine("--GitDirectory [--dir, -d] - Directory to base TodoGenie in. Needs to have a .git folder");
        Console.WriteLine("\n---- List ----\n");
        Console.WriteLine("--Unreported [-u]- Shows only Todos that are unreported to Github");
        Console.WriteLine("\n---- Create ----\n");
        Console.WriteLine("--NoAutoCommit - Doesn't commit updated Todo to Github automatically.");
        Console.WriteLine("\n---- Prune ----\n");
        Console.WriteLine("NOT IMPLEMENTED");
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
                        //TODO: implement this argument
                    case "--testmode": case "-t":
                        //TODO: implement this argument
                    case "--testdirectory": case "-td":
                        //TODO: implement this argument
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