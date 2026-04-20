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

    final storeName = _extractStoreName(lines);
    final items     = _extractLineItems(lines);   // [{name, amount}]
    final subtotal  = _extractLabeled(lines, [RegExp(r'^\s*sub\b', caseSensitive: false), RegExp(r'subtotal', caseSensitive: false)]);
    final svc       = _extractLabeled(lines, [RegExp(r'^\s*svc\b', caseSensitive: false), RegExp(r'service charge', caseSensitive: false)]);
    final total     = _extractTotal(lines);
    final category  = _guessCategory(rawText);
    final conf      = _calcConfidence(total, storeName, items);

    return {
      'store_name'   : storeName,
      'items'        : items,
      'subtotal'     : subtotal,
      'service_charge': svc,
      'total_amount' : total,
      'category'     : category,
      'confidence'   : conf,
    };
  }

  // ─────────────────────────────────────────────────────────
  // EXTRACT LINE ITEMS (các món)
  // Pattern thường gặp:
  //   "1. Cover Charge"      ← tên món (có số đầu)
  //   "1 x 100.000đ  100.000đ"  ← qty × giá  tổng
  // hoặc:
  //   "Crystal Aviation   305,000"  ← tên + giá cùng dòng
  // ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _extractLineItems(List<String> lines) {
    final items = <Map<String, dynamic>>[];
    final stopPattern = RegExp(
      r'\bsub\b|\bsubtotal\b|\bsvc\b|\bservice\b|\btotal\b|\btổng\b|'
      r'\breceivable\b|\bthank\b|\bpowered\b|\bdouble check\b|'
      r'\bfor transfer\b|\baccount\b|\bvpbank\b|\bname:\b',
      caseSensitive: false,
    );
    final skipMeta = RegExp(
      r'\bdate\b|\btime\b|\btable\b|\bcashier\b|\bno of guests\b|'
      r'^\d{1,2}[/:]\d{2}|\bdistrict\b|\bhcmc\b',
      caseSensitive: false,
    );
    // Dòng qty: "2 x 255,000" hoặc "1 x 100.000đ"
    final qtyLinePattern = RegExp(r'^\d+\s*[xX×]\s*[\d.,]+');

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];

      // Dừng khi gặp Sub/Total section
      if (stopPattern.hasMatch(line)) break;
      if (skipMeta.hasMatch(line)) { i++; continue; }

      // Case 1: dòng có số thứ tự đầu → tên món
      final numberedName = RegExp(r'^(\d+)\.\s+(.+)$');
      final nm = numberedName.firstMatch(line);
      if (nm != null) {
        final name = nm.group(2)!.trim();
        // Dòng tiếp theo thường là qty × price  lineTotal
        double? amount;
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          if (qtyLinePattern.hasMatch(nextLine) || stopPattern.hasMatch(nextLine) == false) {
            // Lấy số CUỐI (lineTotal) hoặc số lớn nhất trong dòng qty
            amount = _extractMoneyFromLine(nextLine);
            if (amount != null) i++; // bỏ qua dòng qty
          }
        }
        if (amount == null) {
          // Thử lấy số từ chính dòng tên (một số bill gộp)
          amount = _extractMoneyAfterColon(line);
        }
        if (name.isNotEmpty) {
          items.add({'name': name, 'amount': amount});
        }
        i++;
        continue;
      }

      // Case 2: dòng qty → bỏ qua (đã xử lý ở case 1)
      if (qtyLinePattern.hasMatch(line)) { i++; continue; }

      // Case 3: "Tên món    giá" cùng 1 dòng (không có số thứ tự)
      final amt = _extractMoneyFromLine(line);
      if (amt != null && amt >= 1000) {
        final name = line
            .replaceAll(RegExp(r'\d{1,3}(?:[.,]\d{3})+'), '')
            .replaceAll(RegExp(r'\b\d{4,}\b'), '')
            .replaceAll(RegExp(r'[đ₫d]\s*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'^[\d.\s]+'), '')
            .trim();
        if (name.length >= 2) {
          items.add({'name': _capitalize(name), 'amount': amt});
        }
      }

      i++;
    }

    return items;
  }

  // ─────────────────────────────────────────────────────────
  // EXTRACT LABELED VALUE (Sub, Svc, Total…)
  // ─────────────────────────────────────────────────────────
  double? _extractLabeled(List<String> lines, List<RegExp> patterns) {
    for (final pattern in patterns) {
      for (int i = 0; i < lines.length; i++) {
        if (!pattern.hasMatch(lines[i])) continue;
        // Số từ cùng dòng (sau dấu :)
        final same = _extractMoneyAfterColon(lines[i]);
        if (same != null && same >= 100) return same;
        // Số từ dòng tiếp theo
        if (i + 1 < lines.length) {
          final next = _extractMoneyFromLine(lines[i + 1]);
          if (next != null && next >= 100) return next;
        }
      }
    }
    return null;
  }

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
      RegExp(r'\btotal\b', caseSensitive: false),
      RegExp(r'\breceivable\b', caseSensitive: false),
      RegExp(r'\bthành tiền\b', caseSensitive: false),
      RegExp(r'\btổng cộng\b', caseSensitive: false),
      RegExp(r'\btổng tiền\b', caseSensitive: false),
      RegExp(r'\btổng\b', caseSensitive: false),
    ];

    // Tìm TẤT CẢ candidates → lấy giá trị LỚN NHẤT
    // Tránh nhầm "Total" column header (chỉ có giá 1 món)
    // với grand total ở cuối bill
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

        // Chỉ chấp nhận nếu candidate >= 90% maxItem
        // (loại bỏ "Total" column header chỉ có giá 1 món)
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

  /// Lấy số sau dấu :
  double? _extractMoneyAfterColon(String line) {
    String part = line;
    final colonIdx = line.lastIndexOf(':');
    if (colonIdx != -1 && colonIdx < line.length - 1) {
      part = line.substring(colonIdx + 1).trim();
    }
    return _extractMoneyFromLine(part);
  }

  /// Lấy số tiền lớn nhất từ một dòng text
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
  // STORE NAME
  // ─────────────────────────────────────────────────────────
  String? _extractStoreName(List<String> lines) {
    final skipPattern = RegExp(
      r'\d{3,}|total|tổng|date|time|^\s*table|cashier|sub|svc|'
      r'receipt|invoice|for transfer|account|vpbank|'
      r'district|hcmc|hà nội|powered|thank|come again|double check|'
      r'^b\d+$|^\d+$|lưu png',
      caseSensitive: false,
    );
    for (final line in lines.take(6)) {
      final cleaned = line
          .replaceAll(RegExp(r'^[-*•_=\s]+'), '')
          .replaceAll(RegExp(r'[-*•_=\s]+$'), '')
          .trim();
      if (cleaned.length < 2) continue;
      if (skipPattern.hasMatch(cleaned)) continue;
      if (cleaned.split(RegExp(r'\s+')).length > 6) continue;
      return cleaned;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // CATEGORY & HELPERS
  // ─────────────────────────────────────────────────────────
  String _guessCategory(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'cocktail|bar|beer|wine|café|coffee|trà|bia|cà phê|mocktail|aviation|chamber').hasMatch(t))
      return 'Giải trí & xã hội';
    if (RegExp(r'restaurant|nhà hàng|food|ăn|phở|cơm|bún|lẩu|pizza|burger').hasMatch(t))
      return 'Ăn uống';
    if (RegExp(r'grab|taxi|parking|xăng|fuel|bus|xe').hasMatch(t))
      return 'Di chuyển';
    if (RegExp(r'pharmacy|thuốc|clinic|hospital|y tế').hasMatch(t))
      return 'Sức khoẻ';
    if (RegExp(r'supermarket|mart|shop|store|mua').hasMatch(t))
      return 'Mua sắm cá nhân';
    return 'Khác';
  }

  double _calcConfidence(double? total, String? store, List items) {
    if (total == null) return 0.3;
    double s = 0.5;
    if (store != null) s += 0.2;
    if (items.isNotEmpty) s += 0.2;
    if (items.length > 2) s += 0.1;
    return s.clamp(0.0, 1.0);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String formatMoney(dynamic amount) {
    if (amount == null) return '0đ';
    final n = (amount is double) ? amount.toInt() : (amount as int);
    return n.toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},') +
        'đ';
  }
}