public static class Error {
    public static string LogDirectory { get; set; } = string.Empty;
    private static string getCurrTime() {
        return DateTime.Now.ToString("u");
    }
    public static void Log(string message) {
        if(string.IsNullOrEmpty(LogDirectory) || !Directory.Exists(LogDirectory)) {
            return;
        }
        var logFile = Path.Join(LogDirectory, $"{DateTime.Now.Date.ToString("yyyy-MM-dd")}-todogenie.log");
        if(!File.Exists(logFile)) {
            using (StreamWriter sw = File.CreateText(logFile))
            {
                sw.WriteLine($"[{getCurrTime()}] {message}");
            }
            return;
        }
        using (StreamWriter sw = File.AppendText(logFile)) {
            sw.WriteLine($"[{getCurrTime()}] {message}");
        }
    }
    public static void WriteConsole(string message) {
        Console.WriteLine($"ERROR: {message}");
    }
    public static void Write(string message) {
        message = "ERROR: " + message;
        Log(message);
        Console.WriteLine($"{message}");
    }
    public static void Critical(string message) {
        message = "CRITICAL: " + message;
        Log(message);
        Console.WriteLine($"{message}");
        System.Environment.Exit(1);
    }
}