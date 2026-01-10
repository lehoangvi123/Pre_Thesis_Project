import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class TestMicScreen extends StatefulWidget {
  @override
  _TestMicScreenState createState() => _TestMicScreenState();
}

class _TestMicScreenState extends State<TestMicScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Nhấn mic để nói...';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => setState(() => _status = status),
        onError: (error) => setState(() => _status = 'Lỗi: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
          localeId: 'vi_VN',
          listenFor: Duration(seconds: 10),
        );
      } else {
        setState(() => _status = 'Không thể khởi tạo mic');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Microphone'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _text,
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Trạng thái: $_status',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 40),
            FloatingActionButton.extended(
              onPressed: _listen,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              label: Text(_isListening ? 'Đang nghe...' : 'Bắt đầu'),
              backgroundColor: _isListening ? Colors.red : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}