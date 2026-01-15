// lib/view/TextVoice/test_voice.dart
// FILE NÀY THAY THẾ test_voice.dart CŨ

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// Import services
import './voice_parser_service.dart';
import './AI_Service.dart';
import './Voice_Confirm_Dialog.dart'; // CHÚ Ý: V hoa, c thường

class TestVoiceView extends StatefulWidget {
  const TestVoiceView({Key? key}) : super(key: key);

  @override
  State<TestVoiceView> createState() => _TestVoiceViewState();
}

class _TestVoiceViewState extends State<TestVoiceView> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0.0;
  bool _hasPermission = false;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }
  
  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    
    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          _showError('Lỗi: ${error.errorMsg}');
        },
      );
      
      setState(() => _hasPermission = available);
    }
  }
  
  void _startListening() async {
    if (!_speech.isAvailable) {
      _showError('Speech recognition không khả dụng');
      return;
    }
    
    setState(() {
      _isListening = true;
      _text = '';
      _confidence = 0.0;
    });
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _text = result.recognizedWords;
          _confidence = result.confidence;
        });
      },
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 3),
      partialResults: true,
      localeId: 'vi_VN',
    );
  }
  
  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }
  
  void _analyze() async {
    if (_text.isEmpty) {
      _showError('Chưa có văn bản để phân tích');
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      // Try AI first (optional)
      Map<String, dynamic>? result = await AIService.analyzeVoice(_text);
      
      // Fallback to rule-based
      if (result == null) {
        result = VoiceParserService.parseVoiceInput(_text);
      }
      
      setState(() => _isProcessing = false);
      
      if (result == null) {
        _showError('Không thể phân tích. Vui lòng thử lại.');
        return;
      }
      
      // Show confirmation dialog
      _showConfirmDialog(result);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Lỗi: $e');
    }
  }
  
  void _showConfirmDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceconfirmDialog(
        data: data,
        onConfirm: (confirmedData) {
          _saveTransaction(confirmedData);
        },
      ),
    );
  }
  
  void _saveTransaction(Map<String, dynamic> data) {
    // TODO: Kết nối với provider của bạn
    print('💾 Saving transaction: $data');
    
    // Example:
    // final provider = Provider.of<TransactionProvider>(context, listen: false);
    // provider.addTransaction(
    //   type: data['type'],
    //   amount: data['amount'],
    //   category: data['category'],
    //   note: data['note'],
    //   date: data['date'],
    // );
    
    _showSuccess('✅ Đã lưu giao dịch thành công!');
    
    // Reset
    setState(() {
      _text = '';
      _confidence = 0.0;
    });
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Test Voice Recognition',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _text = '';
                _confidence = 0.0;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isListening ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 64,
                    color: _isListening ? Colors.red : Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isListening 
                        ? '🎙️ Đang nghe...' 
                        : _hasPermission 
                            ? '✅ Đã có quyền microphone'
                            : '❌ Chưa có quyền microphone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isListening ? Colors.red : Colors.green,
                    ),
                  ),
                  if (_isListening)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Trạng thái: listening',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Text display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'Văn bản nhận dạng:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    _text.isEmpty ? 'Nhấn nút mic để bắt đầu...' : _text,
                    style: TextStyle(
                      fontSize: 18,
                      color: _text.isEmpty ? Colors.grey[400] : Colors.black,
                      fontWeight: _text.isEmpty ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  if (_confidence > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(Icons.analytics, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Độ chính xác: ${(_confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? null : _startListening,
                    icon: Icon(Icons.mic, color: Colors.white),
                    label: Text(
                      'Bắt đầu ghi âm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isListening ? _stopListening : null,
                    icon: Icon(Icons.stop),
                    label: Text(
                      'Dừng lắng nghe',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: _isListening ? Colors.red : Colors.grey[300]!,
                      ),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _text.isEmpty || _isProcessing ? null : _analyze,
                    icon: _isProcessing 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      'Phân tích',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Hướng dẫn test:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTip('1️⃣ Nhấn "Bắt đầu ghi âm"'),
                  _buildTip('2️⃣ Nói rõ ràng vào mic'),
                  _buildTip('   • "Mua cà phê 30 nghìn"'),
                  _buildTip('   • "Chi tiền ăn 50k"'),
                  _buildTip('   • "Nhận lương 10 triệu"'),
                  _buildTip('3️⃣ Nhấn "Phân tích"'),
                  _buildTip('4️⃣ Kiểm tra và xác nhận'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
      ),
    );
  }
}