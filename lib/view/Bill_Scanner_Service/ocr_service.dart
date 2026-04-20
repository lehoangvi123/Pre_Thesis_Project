// lib/service/ocr_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker    _picker         = ImagePicker();

  void dispose() => _textRecognizer.close();

  // ─────────────────────────────────────────────────────────
  // PUBLIC: Scan receipt
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> scanReceipt({bool fromCamera = true}) async {
    try {
      final XFile? picked = fromCamera
          ? await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 90,
              preferredCameraDevice: CameraDevice.rear)
          : await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 90);

      if (picked == null) return {'success': false, 'error': 'Không chọn ảnh'};

      final inputImage = InputImage.fromFile(File(picked.path));
      final recognized = await _textRecognizer.processImage(inputImage);
      final rawText    = recognized.text;

      debugPrint('=== OCR RAW ===\n$rawText\n===============');
      if (rawText.trim().isEmpty)
        return {'success': false, 'error': 'Không đọc được text từ ảnh'};

      final result     = _parseReceipt(rawText);
      result['raw_text'] = rawText;
      result['success']  = true;
      return result;
    } catch (e) {
      return {'success': false, 'error': 'Lỗi xử lý ảnh: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────
  // CORE PARSER — chỉ lấy total, category luôn là Ăn uống
  // ─────────────────────────────────────────────────────────
  Map<String, dynamic> _parseReceipt(String rawText) {
    final lines = rawText.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final total = _extractTotal(lines);

    return {
      'store_name'    : null,
      'items'         : [],
      'subtotal'      : null,
      'service_charge': null,
      'total_amount'  : total,
      'category'      : 'Ăn uống',
      'confidence'    : null,
    };
  }

  // ─────────────────────────────────────────────────────────
  // EXTRACT TOTAL
  // ─────────────────────────────────────────────────────────
  double? _extractTotal(List<String> lines) {
    // Tính max amount để validate — total phải >= max item price
    final allAmounts = <double>[];
    for (final l in lines) {
      final v = _extractMoneyFromLine(l);
      if (v != null && v >= 1000) allAmounts.add(v);
    }
    final maxItem = allAmounts.isEmpty ? 0.0
        : allAmounts.reduce((a, b) => a > b ? a : b);

    final keywords = [
      RegExp(r'\btotal\b',       caseSensitive: false),
      RegExp(r'\breceivable\b',  caseSensitive: false),
      RegExp(r'\bthành tiền\b',  caseSensitive: false),
      RegExp(r'\btổng cộng\b',   caseSensitive: false),
      RegExp(r'\btổng tiền\b',   caseSensitive: false),
      RegExp(r'\btổng\b',        caseSensitive: false),
    ];

    double? best;
    for (final pattern in keywords) {
      for (int i = 0; i < lines.length; i++) {
        if (!pattern.hasMatch(lines[i])) continue;

        double? candidate;
        final same = _extractMoneyAfterColon(lines[i]);
        if (same != null && same >= 1000) candidate = same;
        if (candidate == null && i + 1 < lines.length) {
          final next = _extractMoneyFromLine(lines[i + 1]);
          if (next != null && next >= 1000) candidate = next;
        }

        if (candidate != null && candidate >= maxItem * 0.9) {
          if (best == null || candidate > best) best = candidate;
        }
      }
    }

    if (best != null) {
      debugPrint('✅ Total found: $best');
      return best;
    }

    debugPrint('⚠️ Fallback to largest amount');
    return _fallbackLargestAmount(lines);
  }

  // ─────────────────────────────────────────────────────────
  // MONEY HELPERS
  // ─────────────────────────────────────────────────────────

  double? _extractMoneyAfterColon(String line) {
    String part = line;
    final colonIdx = line.lastIndexOf(':');
    if (colonIdx != -1 && colonIdx < line.length - 1) {
      part = line.substring(colonIdx + 1).trim();
    }
    return _extractMoneyFromLine(part);
  }

  double? _extractMoneyFromLine(String line) {
    double? best;

    // "813.750" hoặc "1,228,500"
    final p1 = RegExp(r'\d{1,3}(?:[.,]\d{3})+');
    for (final m in p1.allMatches(line)) {
      final raw = m.group(0)!.replaceAll('.', '').replaceAll(',', '');
      final v   = double.tryParse(raw);
      if (v != null && v >= 100 && (best == null || v > best)) best = v;
    }

    // "813 750" (space làm thousand sep — OCR màn hình LCD)
    final p2 = RegExp(r'\b(\d{3})\s(\d{3})\b');
    for (final m in p2.allMatches(line)) {
      final v = double.tryParse('${m.group(1)}${m.group(2)}');
      if (v != null && v >= 10000 && (best == null || v > best)) best = v;
    }

    // Số liền 4–8 chữ số
    if (best == null) {
      final p3 = RegExp(r'\b\d{4,8}\b');
      for (final m in p3.allMatches(line)) {
        final v = double.tryParse(m.group(0)!);
        if (v != null && v >= 1000 && (best == null || v > best)) best = v;
      }
    }
    return best;
  }

  double? _fallbackLargestAmount(List<String> lines) {
    final skipPattern = RegExp(
      r'date|time|table|b\d+|account|no\.|cashier|for transfer|name:|powered|thank',
      caseSensitive: false,
    );
    final startIdx = (lines.length * 0.4).floor();
    double? best;
    for (final line in lines.sublist(startIdx)) {
      if (skipPattern.hasMatch(line)) continue;
      final amt = _extractMoneyFromLine(line);
      if (amt != null && amt >= 10000 && (best == null || amt > best)) best = amt;
    }
    return best;
  }

  // ─────────────────────────────────────────────────────────
  // FORMAT
  // ─────────────────────────────────────────────────────────
  String formatMoney(dynamic amount) {
    if (amount == null) return '0đ';
    final n = (amount is double) ? amount.toInt() : (amount as int);
    return n.toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},') +
        'đ';
  }
}