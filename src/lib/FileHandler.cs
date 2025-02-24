using System.IO;
using System.Text.RegularExpressions;

public class FileHandler {
    private static List<string> IgnoredFiles = new();
    private static List<string> IgnoredDirs = new();
    private static List<string> Files = new();
    private bool checkForGit(string dir) {
        return Directory.Exists(Path.Join(dir, ".git"));
    }
    private string checkGitIgnore(string dir) {
        string ignoreFile = string.Empty;
        var files = Directory.EnumerateFiles(dir, ".gitignore", SearchOption.AllDirectories);
        foreach(var file in files) {
            ignoreFile = file;
        }
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
            if(token.IndexOf('/') >= 0) {
                var newToken = token.Replace("/", Path.DirectorySeparatorChar.ToString());
                IgnoredDirs.Add(newToken);
                continue;
            }
            IgnoredFiles.Add(token);
        }
        return ignoreFile;
    } 
    public System.Collections.Generic.IEnumerable<string> GetAllValidFiles(string dir) {
        if (!checkForGit(dir)) {
            Error.Critical($"no valid .git directory found in {dir}");
        }
        checkGitIgnore(dir);
        var files = Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories);
        foreach(var file in files) {
            if (file.Contains(".git")) {
                continue;
            }
            if (IgnoredFiles.Any(f => f == file)) {
                continue;
            }
            //TODO: Look to improve this as it will exclude ANY path with the dir name
            //      It should look to only exclude based on wild card. For example with "bin/"
            //      It should exclude ROOT_DIR/bin/* as opposed to excluding ROOT_DIR/src/bin/* as well
            if (IgnoredDirs.Any(d => file.Contains(d))) {
                continue;
            }
            Files.Add(file);
        }
        return Files;
    }
    public string ReadFile(string filePath) {
        return File.ReadAllText(filePath);
    }
}