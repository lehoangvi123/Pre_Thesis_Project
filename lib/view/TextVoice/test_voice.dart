import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TestVoiceScreen extends StatefulWidget {
  @override
  _TestVoiceScreenState createState() => _TestVoiceScreenState();
}

class _TestVoiceScreenState extends State<TestVoiceScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Nhấn nút để nói...';

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
          localeId: 'vi_VN',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Voice')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_text, style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            FloatingActionButton(
              onPressed: _listen,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
              backgroundColor: _isListening ? Colors.red : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}