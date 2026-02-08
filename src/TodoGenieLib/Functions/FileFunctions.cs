using System.Text.RegularExpressions;
using TodoGenieLib.Models;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Functions;
public class FileFunctions {
    public static bool CheckForGit(string dir) {
        return Directory.Exists(Path.Join(dir, ".git"));
    }
    
    public static IEnumerable<string> EnumerateFiles(string path, HashSet<string> excludedDirectories)
    {
        var fileCollection = new List<string>();
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
                    TraverseDirectory(subDir, excludedDirectories, fileCollection);
                }
            }
            foreach (var file in Directory.GetFiles(directory))
            {
                fileCollection.Add(file);
            }
        }
        catch (UnauthorizedAccessException)
        {
            
        }
    }

    private static bool IsExcluded(string fullPath, HashSet<string> excludedDirectories)
    {
        DirectoryInfo dir = new(fullPath);
        while (dir != null)
        {
            //TODO: work on fixing excluded directories that are not in the root directory.
            if (excludedDirectories.Any(e => e.Equals(dir.Name) 
                || fullPath.Replace(Environment.CurrentDirectory, "")[1..].StartsWith(e)))
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
    private static HashSet<string> CheckGitIgnore(string dir) {
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
                var val = token;
                if(val.EndsWith('/'))
                {
                    val = val[..^1];
                }
                ignoredFiles.Add(val);
            }
        }
        return ignoredFiles;
    } 
    public static IEnumerable<string> GetAllValidFiles(string dir, HashSet<string> excludedDirs) {
        if (!CheckForGit(dir)) {
            Error.Critical($"no valid .git directory found in {dir}");
        }
        var ignoredFiles = CheckGitIgnore(dir);

        ignoredFiles.UnionWith(excludedDirs);
        
        var files = EnumerateFiles(dir, ignoredFiles);
        return files;
    }

}