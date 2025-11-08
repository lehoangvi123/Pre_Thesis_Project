import 'dart:math';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TOTPService {
  // Generate a random secret key (32 characters)
  static String generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Save secret to local storage
  static Future<void> saveSecret(String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('totp_secret', secret);
  }

  // Get saved secret
  static Future<String?> getSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('totp_secret');
  }

  // Delete secret (when disabling 2FA)
  static Future<void> deleteSecret() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('totp_secret');
  }

  // Generate TOTP URI for QR code
  static String generateTOTPUri(String secret, String email) {
    return 'otpauth://totp/ExpenseTracker:$email?secret=$secret&issuer=ExpenseTracker';
  }

  // Verify TOTP code entered by user
  static bool verifyCode(String secret, String userCode) {
    try {
      // Get current timestamp
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Generate code for current time
      final code = OTP.generateTOTPCodeString(
        secret,
        now,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      // Compare with user's code
      return code == userCode;
    } catch (e) {
      print('Error verifying code: $e');
      return false;
    }
  }

  // Generate current TOTP code (for testing)
  static String generateCurrentCode(String secret) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return OTP.generateTOTPCodeString(
      secret,
      now,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }
}  