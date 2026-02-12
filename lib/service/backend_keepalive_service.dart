import 'dart:async';
import 'package:http/http.dart' as http;

class BackendKeepAliveService {
  static Timer? _timer;
  static const String _backendUrl = 'https://buddy-budget-system-backend.onrender.com/health'; // ✅ Thay URL của bạn
  
  // ✅ Start keep-alive khi app mở
  static void start() {
    if (_timer != null && _timer!.isActive) return;
    
    // Ping ngay lập tức
    _ping();
    
    // Ping mỗi 10 phút
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _ping();
    });
    
    print('🔥 Backend Keep-Alive started');
  }
  
  // ✅ Stop keep-alive khi app đóng
  static void stop() {
    _timer?.cancel();
    _timer = null;
    print('❄️ Backend Keep-Alive stopped');
  }
  
  static Future<void> _ping() async {
    try {
      final response = await http.get(Uri.parse(_backendUrl)).timeout(
        const Duration(seconds: 5),
      );
      
      if (response.statusCode == 200) {
        print('✅ Backend is alive');
      } else {
        print('⚠️ Backend returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Keep-alive failed: $e');
    }
  }
}