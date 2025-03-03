using System.Text.RegularExpressions;
using TodoGenieLib.Models;

namespace TodoGenieLib.Functions;
public class FileFunctions {
    public static bool CheckForGit(string dir) {
        return Directory.Exists(Path.Join(dir, ".git"));
    }
    public static HashSet<string> CheckGitIgnore(string dir) {
        string ignoreFile = string.Empty;
        HashSet<string> ignoredFiles = [".git"];
        var files = Directory.EnumerateFiles(dir, ".gitignore", SearchOption.AllDirectories);
        foreach(var file in files) {
            ignoreFile = file;
        }
        if(!string.IsNullOrEmpty(ignoreFile)) {
            var buf = File.ReadAllText(ignoreFile);
            
            foreach(var token in buf.Split('\n')) {
                if(token.StartsWith('#') || token.StartsWith('!') || string.IsNullOrEmpty(token)) {
                    continue;
                }
                ignoredFiles.Add(token.Replace("/", ""));
            }
        }
        return ignoredFiles;
    } 
    public static IEnumerable<string> EnumerateFiles(string path, HashSet<string> excludedDirectories)
    {
        var fileCollection = new List<string>(); // Using List instead of ConcurrentBag since we control recursion
        TraverseDirectory(path, excludedDirectories, fileCollection);
        return fileCollection;
    }

    private static void TraverseDirectory(string directory, HashSet<string> excludedDirectories, List<string> fileCollection)
    {
        try
        {
            foreach (var subDir in Directory.GetDirectories(directory))
            {
                if (!IsExcluded(subDir, excludedDirectories))
                {
                    TraverseDirectory(subDir, excludedDirectories, fileCollection); // Recursively process allowed directories
                }
            }
            foreach (var file in Directory.GetFiles(directory))
            {
                fileCollection.Add(file);
            }
        }
        catch (UnauthorizedAccessException)
        {
            // Skip directories we can't access
        }
    }

    private static bool IsExcluded(string fullPath, HashSet<string> excludedDirectories)
    {
        DirectoryInfo dir = new DirectoryInfo(fullPath);

        while (dir != null)
        {
            if (excludedDirectories.Any(e => e.Contains(dir.Name)))
                return true;

            dir = dir.Parent!;
        }

        return false;
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

}