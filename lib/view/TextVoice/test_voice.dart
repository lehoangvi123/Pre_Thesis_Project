import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class TestVoiceScreen extends StatefulWidget {
  TestVoiceScreen({Key? key}) : super(key: key);

  @override
  State<TestVoiceScreen> createState() => _TestVoiceScreenState();
}

class _TestVoiceScreenState extends State<TestVoiceScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Nhấn nút mic để bắt đầu...';
  String _status = 'Chưa khởi tạo';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.microphone.status;
    
    setState(() {
      if (status.isGranted) {
        _status = '✅ Đã có quyền microphone';
      } else if (status.isDenied) {
        _status = '⚠️ Chưa có quyền microphone';
      } else if (status.isPermanentlyDenied) {
        _status = '❌ Quyền bị từ chối vĩnh viễn';
      }
    });

    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      setState(() {
        _status = result.isGranted 
            ? '✅ Đã cấp quyền' 
            : '❌ Người dùng từ chối quyền';
      });
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      var permissionStatus = await Permission.microphone.status;
      if (!permissionStatus.isGranted) {
        setState(() => _status = '❌ Cần cấp quyền microphone');
        await _checkPermission();
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          print('🎤 Status: $status');
          setState(() => _status = 'Trạng thái: $status');
        },
        onError: (error) {
          print('❌ Error: $error');
          setState(() {
            _status = 'Lỗi: ${error.errorMsg}';
            _isListening = false;
          });
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _status = '🎤 Đang nghe... Hãy nói gì đó';
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              _confidence = result.confidence;
              
              if (result.finalResult) {
                _status = '✅ Hoàn thành! Độ chính xác: ${(_confidence * 100).toInt()}%';
              }
            });
          },
          localeId: 'vi_VN',
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } else {
        setState(() => _status = '❌ Speech recognition không khả dụng');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      setState(() => _status = '⏸️ Đã dừng nghe');
    }
  }

  void _reset() {
    setState(() {
      _text = 'Nhấn nút mic để bắt đầu...';
      _status = '🔄 Đã reset';
      _confidence = 0.0;
      _isListening = false;
    });
    _speech.stop();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Voice Recognition'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: _isListening ? Colors.red[50] : Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 60,
                      color: _isListening ? Colors.red : Colors.blue,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Card(
              elevation: 4,
              child: Container(
                constraints: BoxConstraints(minHeight: 200),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Văn bản nhận dạng:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _text,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_confidence > 0)
                      LinearProgressIndicator(
                        value: _confidence,
                        backgroundColor: Colors.grey[300],
                        color: _confidence > 0.8 ? Colors.green : Colors.orange,
                        minHeight: 8,
                      ),
                    if (_confidence > 0)
                      SizedBox(height: 8),
                    if (_confidence > 0)
                      Text(
                        'Độ chính xác: ${(_confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            ElevatedButton(
              onPressed: _listen,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _isListening ? 'Dừng lắng nghe' : 'Bắt đầu ghi âm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Reset',
                style: TextStyle(fontSize: 16),
              ),
            ),

            SizedBox(height: 32),

            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[900]),
                        SizedBox(width: 8),
                        Text(
                          'Hướng dẫn test:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1️⃣ Nhấn "Bắt đầu ghi âm"'),
                    Text('2️⃣ Nói rõ ràng vào mic'),
                    Text('3️⃣ Thử các câu:'),
                    Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('   • "Mua cà phê 30 nghìn"'),
                          Text('   • "Chi tiền ăn 50000"'),
                          Text('   • "Đổ xăng 200 nghìn"'),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('4️⃣ Kiểm tra độ chính xác'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}