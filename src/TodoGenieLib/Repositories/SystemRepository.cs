using System.Diagnostics;
using TodoGenieLib.Utils;

namespace TodoGenieLib.Repositories;

public class SystemRepository() {
    public static void ExecuteGitCommand(string cmd) {
        var os = Environment.OSVersion.Platform;
        ProcessStartInfo startInfo = new() {FileName = "git", Arguments = cmd};
        Process proc = new Process(){ StartInfo = startInfo };
        proc.Start();
    }
}