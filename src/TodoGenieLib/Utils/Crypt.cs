using System.Text;

namespace TodoGenieLib.Utils;

public class Crypt {
    
    public static string Decrypt(string val) {
        var base64EncodedBytes = Convert.FromBase64String(val);
        return Encoding.ASCII.GetString(base64EncodedBytes); 
    }
    public static string Encrypt(string val) {
        return Convert.ToBase64String(Encoding.ASCII.GetBytes(val));
    }
}