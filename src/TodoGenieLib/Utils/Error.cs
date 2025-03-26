namespace TodoGenieLib.Utils;
public static class Error {
    public static string LogDirectory { get; set; } = string.Empty;
    private static string GetCurrTime() {
        return DateTime.Now.ToString("u");
    }
    public static void Log(string message) {
        if(string.IsNullOrEmpty(LogDirectory) || !Directory.Exists(LogDirectory)) {
            return;
        }
        var logFile = Path.Join(LogDirectory, $"{DateTime.Now.Date:yyyy-MM-dd}-todogenie.log");
        if(!File.Exists(logFile)) {
            using StreamWriter sw = File.CreateText(logFile);
            sw.WriteLine($"[{GetCurrTime()}] {message}");
            return;
        }
        using (StreamWriter sw = File.AppendText(logFile)) {
            sw.WriteLine($"[{GetCurrTime()}] {message}");
        }
    }
    public static void WriteConsole(string message) {
        Console.WriteLine($"ERROR: {message}");
    }
    public static void Write(string message) {
        message = "ERROR: " + message;
        Log(message);
        throw new Exception(message);
    }
    public static void Critical(string message) {
        message = "CRITICAL: " + message;
        Log(message);
        Console.WriteLine($"{message}");
        Environment.Exit(1);
    }
}