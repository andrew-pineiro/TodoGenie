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
    public static bool TryGetValue<T>(T[] array, int index, out T value) {
        if (index >= 0 && index < array.Length) {
            value = array[index];
            return true;
        }
        value = default!;
        return false;
    } 
}