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
  // CORE PARSER
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
  // Nhóm 1 (cao): grand total, tổng cộng, tổng tiền, thành tiền...
  // Nhóm 2 (trung): total, tổng, thanh toán, phải trả...
  // Fallback: số lớn nhất ở nửa dưới bill
  // ─────────────────────────────────────────────────────────
  double? _extractTotal(List<String> lines) {
    final normalized = lines.map(_normalize).toList();

    // Tính max amount để validate
    final allAmounts = <double>[];
    for (final l in lines) {
      final v = _extractMoneyFromLine(l);
      if (v != null && v >= 1000) allAmounts.add(v);
    }
    final maxItem = allAmounts.isEmpty ? 0.0
        : allAmounts.reduce((a, b) => a > b ? a : b);

    // ── Nhóm 1: Ưu tiên cao ──────────────────────────────
    final highPriority = [
      RegExp(r'grand\s*total',              caseSensitive: false),
      RegExp(r't[oô]ng\s*c[o\u00f4]ng',    caseSensitive: false), // tổng cộng
      RegExp(r't[oô]ng\s*ti[e\u1ec1]n',    caseSensitive: false), // tổng tiền
      RegExp(r'th[a\u00e0]nh\s*ti[e\u1ec1]n', caseSensitive: false), // thành tiền
      RegExp(r'amount\s*due',               caseSensitive: false),
      RegExp(r'total\s*amount',             caseSensitive: false),
      RegExp(r'total\s*due',                caseSensitive: false),
      RegExp(r'total\s*bill',               caseSensitive: false),
      RegExp(r'receivable',                 caseSensitive: false),
      RegExp(r'tong\s*cong',                caseSensitive: false), // OCR mất dấu
      RegExp(r'tong\s*tien',                caseSensitive: false),
      RegExp(r'thanh\s*tien',               caseSensitive: false),
    ];

    // ── Nhóm 2: Ưu tiên trung ────────────────────────────
    final medPriority = [
      RegExp(r'\btotal\b',                  caseSensitive: false),
      RegExp(r'\bt[oô]ng\b',               caseSensitive: false), // tổng
      RegExp(r'\btong\b',                   caseSensitive: false), // OCR mất dấu
      RegExp(r'c[o\u00f4]ng\s*ti[e\u1ec1]n', caseSensitive: false), // cộng tiền
      RegExp(r'ti[e\u1ec1]n\s*thanh\s*to[a\u00e1]n', caseSensitive: false),
      RegExp(r'thanh\s*to[a\u00e1]n',       caseSensitive: false), // thanh toán
      RegExp(r'ph[a\u1ea3]i\s*tr[a\u1ea3]', caseSensitive: false), // phải trả
      RegExp(r'kh[a\u00e1]ch\s*tr[a\u1ea3]', caseSensitive: false), // khách trả
      RegExp(r'payment',                    caseSensitive: false),
      RegExp(r'thanh\s*toan',               caseSensitive: false), // OCR mất dấu
      RegExp(r'phai\s*tra',                 caseSensitive: false),
    ];

    double? best;

    for (final group in [highPriority, medPriority]) {
      double? groupBest;
      for (final pattern in group) {
        for (int i = 0; i < normalized.length; i++) {
          if (!pattern.hasMatch(normalized[i])) continue;

          double? candidate;

          // 1. Số trên cùng dòng (sau : hoặc cuối dòng)
          candidate = _extractMoneyAfterColon(lines[i]);
          if (candidate != null && candidate < 1000) candidate = null;

          // 2. Số ở cuối dòng (không cần dấu :)
          if (candidate == null) {
            final endAmt = _extractMoneyFromLine(lines[i]);
            if (endAmt != null && endAmt >= 1000) candidate = endAmt;
          }

          // 3. Số ở dòng kế tiếp
          if (candidate == null && i + 1 < lines.length) {
            final next = _extractMoneyFromLine(lines[i + 1]);
            if (next != null && next >= 1000) candidate = next;
          }

          // Validate >= 90% maxItem
          if (candidate != null && candidate >= maxItem * 0.9) {
            if (groupBest == null || candidate > groupBest) {
              groupBest = candidate;
            }
          }
        }
      }

      // Tìm thấy ở nhóm cao → dừng, không xuống nhóm thấp hơn
      if (groupBest != null) {
        best = groupBest;
        break;
      }
    }

    if (best != null) {
      debugPrint('✅ Total found: $best');
      return best;
    }

    debugPrint('⚠️ Fallback to largest amount');
    return _fallbackLargestAmount(lines);
  }

  // Chuẩn hóa dòng: lowercase, bỏ ký tự rác, bỏ space thừa
  String _normalize(String line) {
    return line
        .toLowerCase()
        .replaceAll(RegExp(r'[*\-–—_=|:()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

    // "813.750" hoặc "1,228,500" hoặc "775,000đ"
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