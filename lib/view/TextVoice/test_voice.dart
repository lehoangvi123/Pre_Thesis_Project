// lib/view/TextVoice/test_voice.dart
// FIXED VERSION - Không còn freeze UI

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// Import services
import './voice_parser_service.dart';
import './AI_Service.dart';
import '../../service/TransactionService.dart';
import 'Voice_confirm_dialog.dart';

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
  bool _isSaving = false;
  
  // TransactionService instance
  final _transactionService = TransactionService();
  
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
          if (mounted) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            _showError('Lỗi: ${error.errorMsg}');
          }
        },
      );
      
      if (mounted) {
        setState(() => _hasPermission = available);
      }
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
        if (mounted) {
          setState(() {
            _text = result.recognizedWords;
            _confidence = result.confidence;
          });
        }
      },
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 3),
      partialResults: true,
      localeId: 'vi_VN',
    );
  }
  
  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
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
      
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      
      if (result == null) {
        _showError('Không thể phân tích. Vui lòng thử lại.');
        return;
      }
      
      // Show confirmation dialog
      if (mounted) {
        _showConfirmDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
  
  // ✨ SAVE TRANSACTION - FIXED với proper async handling
  Future<void> _saveTransaction(Map<String, dynamic> data) async {
    if (!mounted) return;
    
    setState(() => _isSaving = true);
    
    try {
      print('💾 [Voice] Starting save...');
      
      // ⚡ Run in background - không block UI
      final success = await _transactionService.saveVoiceTransaction(
        type: data['type'],
        amount: data['amount'],
        categoryName: data['category'],
        note: data['note'] ?? '',
        date: data['date'],
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Save timeout after 30s');
          return false;
        },
      );
      
      if (!mounted) return;
      
      setState(() => _isSaving = false);
      
      if (success) {
        _showSuccess('✅ Đã lưu giao dịch thành công!');
        
        // Reset
        setState(() {
          _text = '';
          _confidence = 0.0;
        });
        
        // Delay ngắn để user đọc message
        await Future.delayed(Duration(milliseconds: 500));
        
        // Navigate back
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showError('❌ Lỗi khi lưu giao dịch');
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isSaving = false);
      print('❌ [Voice] Save error: $e');
      _showError('Lỗi: ${e.toString()}');
    }
  }
  
  void _showError(String msg) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showSuccess(String msg) {
    if (!mounted) return;
    
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
        duration: Duration(seconds: 2),
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent back if saving
        if (_isSaving) {
          _showError('Đang lưu giao dịch, vui lòng đợi...');
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Test Voice Recognition',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            if (!_isSaving && !_isProcessing)
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
        body: Stack(
          children: [
            SingleChildScrollView(
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
                                  ? '✅ Sẵn sàng'
                                  : '❌ Chưa có quyền',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isListening ? Colors.red : Colors.green,
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
                              'Văn bản:',
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
                          _text.isEmpty ? 'Nhấn mic để bắt đầu...' : _text,
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
                          onPressed: (_isListening || _isSaving) ? null : _startListening,
                          icon: Icon(Icons.mic, color: Colors.white),
                          label: Text(
                            'Bắt đầu',
                            style: TextStyle(
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
                          label: Text('Dừng'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_text.isEmpty || _isProcessing || _isSaving) ? null : _analyze,
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
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
                              'Hướng dẫn:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('• "Nhận lương 10 tỷ"', style: TextStyle(fontSize: 13)),
                        Text('• "Mua cà phê 35k"', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading overlay - IMPROVED
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Card(
                    margin: EdgeInsets.all(40),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Đang lưu giao dịch...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Vui lòng đợi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
