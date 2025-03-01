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
                    var newToken = token.Replace("/", Path.DirectorySeparatorChar.ToString());
                    IgnoredDirs.Add(newToken);
                    continue;
                }
                IgnoredFiles.Add(token);
            }
        }
        return ignoreFile;
    } 
    public IEnumerable<string> GetAllValidFiles(string dir) {
        if (!checkForGit(dir)) {
            Error.Critical($"no valid .git directory found in {dir}");
        }
        CheckGitIgnore(dir);
        var files = Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories);
        foreach(var file in files) {
            if (file.Contains(".git")) {
                continue;
            }
            if (IgnoredFiles.Any(f => f == file)) {
                continue;
            }
            if (IgnoredDirs.Any(file.Contains)) {
                continue;
            }
            Files.Add(file);
        }
        return Files;
    }
}