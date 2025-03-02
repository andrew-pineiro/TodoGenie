using System.Text;

namespace TodoGenieLib.Utils;

public class Crypt {
    
    public static string Decrypt(string val) {
        var base64EncodedBytes = Convert.FromBase64String(val);
        return Encoding.UTF8.GetString(base64EncodedBytes, 0, base64EncodedBytes.Length);
    }
}