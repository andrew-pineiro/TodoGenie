using System.Text;
using System.Text.RegularExpressions;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Functions;
public class FileFunctions {
    private List<string> IgnoredFiles = new();
    private List<string> IgnoredDirs = new();
    private List<string> Files = new();
    private bool checkForGit(string dir) {
        return Directory.Exists(Path.Join(dir, ".git"));
    }
    private string CheckGitIgnore(string dir) {
        string ignoreFile = string.Empty;
        var files = Directory.EnumerateFiles(dir, ".gitignore", SearchOption.AllDirectories);
        foreach(var file in files) {
            ignoreFile = file;
        }
        if(!string.IsNullOrEmpty(ignoreFile)) {
            var buf = File.ReadAllText(ignoreFile);
            
            foreach(var token in buf.Split('\n')) {
                //Ignore comments
                if(token.StartsWith("#")) {
                    continue;
                }
                //Ignore explicit included items
                if(token.StartsWith('!')) {
                    continue;
                }
                //Handle directories seperately
                if(token.Contains('/')) {
                    var newToken = token.Replace("/", "");
                    IgnoredDirs.Add(newToken);
                    continue;
                }
                IgnoredFiles.Add(token);
            }
        }
        return ignoreFile;
    } 
    public IEnumerable<string> GetAllValidFiles(string dir, List<string> excludedDirs) {
        if (!checkForGit(dir)) {
            Error.Critical($"no valid .git directory found in {dir}");
        }
        CheckGitIgnore(dir);
        var files = Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories);
        foreach(var file in files) {
            if (excludedDirs.Any(file.Contains)) {
                continue;
            }
            if (file.Contains(".git") ||
                    IgnoredFiles.Any(f => f == file ||
                        IgnoredDirs.Any(file.Contains))) {
                continue;
            }
            Files.Add(file);
        }
        return Files;
    }
    public static string GetGithubEndpoint(string rootDir) {
        string endpoint = string.Empty;
        var content = File.ReadAllLines(Path.Join(rootDir, ".git", "config"));
        foreach(var line in content) {
            var match = Regex.Match(line, @"url = https?://github.com/(.+)/(.+).git");
            if(match.Success) {
                endpoint = $"/repos/{match.Groups[1].Value}/{match.Groups[2].Value}/issues";
                break;
            }
        }
        return endpoint;
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
        throw new NotImplementedException();
    }
}