// lib/view/Function/AI_Chatbot/chatbot_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chat_message_model.dart';
import '../../../service/ai_assistant_service.dart';
import 'typing_indicator.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({Key? key}) : super(key: key);

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView>
    with TickerProviderStateMixin {
  final AIAssistantService _aiService = AIAssistantService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Uuid _uuid = Uuid();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _isStreaming = false;
  String _streamingText = '';
  String? _streamingMessageId;
  bool _hasStartedChat = false;

  // Lưu detected plan per message id
  final Map<String, List<Map<String, dynamic>>> _detectedPlans = {};

  final List<Map<String, String>> _suggestions = [
    {'emoji': '📊', 'text': 'Lương 10 triệu nên chi tiêu thế nào?'},
    {'emoji': '💰', 'text': 'Làm sao để tiết kiệm nhiều hơn?'},
    {'emoji': '📈', 'text': 'Phân tích chi tiêu tháng này'},
    {'emoji': '🎯', 'text': 'Lập kế hoạch tài chính cho người mới đi làm'},
  ];

  // Lấy plan từ message AI cuối cùng (để hiện nút Lưu trên AppBar)
  List<Map<String, dynamic>> get _lastDetectedPlan {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (!msg.isUser && _detectedPlans.containsKey(msg.id)) {
        return _detectedPlans[msg.id]!;
      }
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    // Trigger rebuild khi gõ text → nút submit active đúng
    _messageController.addListener(() => setState(() {}));
  }

  // ══════════════════════════════════════════════════════
  // DETECT mục chi tiêu + số tiền từ AI response
  // ══════════════════════════════════════════════════════
  List<Map<String, dynamic>> _detectPlanItems(String text) {
    // ── Bảng mapping: từ khóa nhỏ → danh mục lớn ──────────
    final categoryMapping = <String, String>{
      // Ăn uống
      'thực phẩm': 'Ăn uống', 'ăn uống': 'Ăn uống', 'ăn ngoài': 'Ăn uống',
      'tiệc': 'Ăn uống', 'café': 'Ăn uống', 'cà phê': 'Ăn uống',
      // Hóa đơn tiện ích
      'điện': 'Hóa đơn tiện ích', 'nước': 'Hóa đơn tiện ích',
      'gas': 'Hóa đơn tiện ích', 'thuê nhà': 'Nhà ở', 'tiền nhà': 'Nhà ở',
      'internet': 'Dịch vụ & Internet', 'điện thoại': 'Dịch vụ & Internet',
      'streaming': 'Dịch vụ & Internet', 'netflix': 'Dịch vụ & Internet',
      // Di chuyển
      'xăng': 'Di chuyển', 'xe': 'Di chuyển', 'grab': 'Di chuyển',
      'bảo dưỡng': 'Di chuyển', 'vận chuyển': 'Di chuyển',
      // Giải trí
      'du lịch': 'Giải trí', 'phim': 'Giải trí', 'game': 'Giải trí',
      'thể thao': 'Giải trí & Thể thao', 'gym': 'Giải trí & Thể thao',
      'mua sắm': 'Mua sắm', 'quần áo': 'Mua sắm', 'quà': 'Mua sắm',
      // Sức khỏe
      'y tế': 'Sức khỏe', 'bệnh viện': 'Sức khỏe', 'thuốc': 'Sức khỏe',
      'bảo hiểm': 'Bảo hiểm & Dự phòng',
      // Học tập
      'học phí': 'Học tập & Phát triển', 'sách': 'Học tập & Phát triển',
      'khóa học': 'Học tập & Phát triển',
      // Tiết kiệm
      'tiết kiệm': 'Tiết kiệm', 'đầu tư': 'Đầu tư',
      'tiết kiệm ngắn hạn': 'Tiết kiệm', 'tiết kiệm dài hạn': 'Tiết kiệm',
    };

    final iconMap = <String, String>{
      'Ăn uống': '🍜', 'Hóa đơn tiện ích': '💡', 'Nhà ở': '🏠',
      'Dịch vụ & Internet': '📱', 'Di chuyển': '🚗',
      'Giải trí': '🎬', 'Giải trí & Thể thao': '🎯',
      'Mua sắm': '🛍️', 'Sức khỏe': '💊',
      'Bảo hiểm & Dự phòng': '🛡️', 'Học tập & Phát triển': '📚',
      'Tiết kiệm': '💰', 'Đầu tư': '📈',
      'Chi phí cần thiết': '🏠', 'Chi phí linh hoạt': '🎯',
      'Tiết kiệm và Đầu tư': '💰',
    };

    String getIcon(String name) {
      if (iconMap.containsKey(name)) return iconMap[name]!;
      final lower = name.toLowerCase();
      for (final kv in iconMap.entries) {
        if (lower.contains(kv.key.toLowerCase())) return kv.value;
      }
      return '📌';
    }

    // Tìm danh mục lớn phù hợp cho 1 keyword nhỏ
    String mapToCategory(String keyword) {
      final lower = keyword.toLowerCase().trim();
      for (final kv in categoryMapping.entries) {
        if (lower.contains(kv.key)) return kv.value;
      }
      return '';
    }

    // Parse số tiền
    double? parseAmount(String raw) {
      raw = raw.trim();
      final bigNum = RegExp(r'(\d[\d\.]+\d)\s*(?:đồng|đ|VND)?', caseSensitive: false)
          .firstMatch(raw);
      if (bigNum != null) {
        final cleaned = bigNum.group(1)!.replaceAll('.', '');
        final v = double.tryParse(cleaned);
        if (v != null && v >= 10000) return v;
      }
      final triMatch = RegExp(r'(\d+(?:[,\.]\d+)?)\s*(?:triệu|tr)', caseSensitive: false)
          .firstMatch(raw);
      if (triMatch != null) {
        final v = double.tryParse(triMatch.group(1)!.replaceAll(',', '.'));
        if (v != null) return v * 1000000;
      }
      return null;
    }

    // ── BƯỚC 1: Tìm các mục LỚN có số tiền ────────────────
    // VD: "1. **Chi phí cần thiết (50%):** 7.500.000 đồng"
    final bigItems = <String, double>{};  // category → amount
    final p1 = RegExp(
      r'\d+\.\s*\*{0,2}([^\*\n\d]{3,60})\*{0,2}\s*[:\-–]\s*([\d\.]+\s*(?:đồng|đ|triệu|tr|VND)?)',
      caseSensitive: false,
    );
    for (final m in p1.allMatches(text)) {
      final rawName = m.group(1)!
          .replaceAll(RegExp(r'\(\d+[-–]?\d*%\)'), '')
          .replaceAll('**', '').replaceAll(RegExp(r'[:\-–]'), '')
          .replaceAll(RegExp(r'\s+'), ' ').trim();
      final amt = parseAmount(m.group(2) ?? '');
      if (rawName.length >= 3 && amt != null && amt > 0) {
        bigItems[rawName] = amt;
      }
    }

    // ── BƯỚC 2: Tìm các mục NHỎ và gom vào danh mục lớn ──
    // VD: "* Thực phẩm, ăn uống: 2.000.000 đồng"
    // VD: "- Điện, nước, gas: 3.000.000 đồng"
    final subGroups = <String, double>{};  // bigCategory → total amount
    final p2 = RegExp(
      r'[*\-•]\s*([^:\n]{3,80})\s*[:\-–]\s*([\d\.]+\s*(?:đồng|đ|triệu|tr)?)',
      caseSensitive: false,
    );
    for (final m in p2.allMatches(text)) {
      final rawKeywords = m.group(1) ?? '';
      final amt = parseAmount(m.group(2) ?? '');
      if (amt == null || amt <= 0) continue;

      // Tách nhiều keyword (VD: "điện, nước, gas")
      final keywords = rawKeywords.split(RegExp(r'[,/;]'));
      String bigCat = '';
      for (final kw in keywords) {
        bigCat = mapToCategory(kw);
        if (bigCat.isNotEmpty) break;
      }
      if (bigCat.isEmpty) continue;

      subGroups[bigCat] = (subGroups[bigCat] ?? 0) + amt;
    }

    // ── BƯỚC 3: Merge kết quả ──────────────────────────────
    final merged = <String, double>{};

    // Ưu tiên mục LỚN nếu có
    merged.addAll(bigItems);

    // Nếu không có mục lớn → dùng mục nhỏ đã gom
    if (merged.isEmpty && subGroups.isNotEmpty) {
      merged.addAll(subGroups);
    }

    // Nếu có cả hai → cập nhật amount từ subGroups vào bigItems
    // (sub items thường chi tiết hơn → ưu tiên nếu khác biệt > 10%)
    if (bigItems.isNotEmpty && subGroups.isNotEmpty) {
      for (final kv in subGroups.entries) {
        if (!merged.containsKey(kv.key)) {
          merged[kv.key] = kv.value;
        }
      }
    }

    // Convert sang List
    final seenNames = <String>{};
    final items = <Map<String, dynamic>>[];
    for (final kv in merged.entries) {
      final name = kv.key;
      if (seenNames.contains(name.toLowerCase())) continue;
      seenNames.add(name.toLowerCase());
      items.add({
        'category': name,
        'amount':   kv.value.toInt(),
        'icon':     getIcon(name),
        'note':     '',
        'percent':  0,
      });
    }

    // Tính %
    if (items.isNotEmpty) {
      final total = items.fold<int>(0, (s, i) => s + (i['amount'] as int));
      if (total > 0) {
        for (final item in items) {
          item['percent'] = ((item['amount'] as int) / total * 100).round();
        }
      }
    }

    return items;
  }

  // ══════════════════════════════════════════════════════
  // BOTTOM SHEET chỉnh sửa & lưu kế hoạch
  // ══════════════════════════════════════════════════════
  void _showSavePlanSheet(List<Map<String, dynamic>> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Controllers cho từng item
    final controllers = {
      for (final item in items)
        item['category'] as String:
            TextEditingController(text: '${item['amount']}')
    };
    // Income controller
    final totalAmt = items.fold<int>(0, (s, i) => s + (i['amount'] as int));
    final incomeCtrl = TextEditingController(text: '$totalAmt');

    String _fmt(dynamic v) {
      final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          int getIncome() =>
              int.tryParse(incomeCtrl.text.replaceAll(',', '')) ?? 0;

          int getTotal() => controllers.values.fold(0, (s, c) =>
              s + (int.tryParse(c.text.replaceAll(',', '')) ?? 0));

          final income    = getIncome();
          final total     = getTotal();
          final remaining = income - total;
          final isOver    = remaining < 0;

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              )),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(children: [
                  const Text('💾', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Lưu vào kế hoạch',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Chỉnh sửa rồi lưu theo ý bạn',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.grey[200], shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey[700]),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              // Thanh thu nhập + tổng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  // Thu nhập
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CED1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00CED1).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF00CED1), size: 18),
                      const SizedBox(width: 8),
                      const Text('Thu nhập / tháng',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: incomeCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setS(() {}),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00CED1)),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            suffixText: 'đ',
                            suffixStyle: TextStyle(
                                color: Color(0xFF00CED1),
                                fontWeight: FontWeight.bold),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),

                  // Tổng chi + còn lại
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOver
                          ? Colors.red.withOpacity(0.08)
                          : Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isOver
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(
                        isOver
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        color: isOver ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        isOver
                            ? 'Vượt quá ${_fmt(remaining.abs())}đ'
                            : 'Còn lại ${_fmt(remaining)}đ → vào Tiết kiệm',
                        style: TextStyle(
                            fontSize: 12,
                            color: isOver ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500),
                      )),
                      Text('Tổng: ${_fmt(total)}đ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOver ? Colors.red : Colors.green)),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey[200]),

              // Danh sách mục chỉnh sửa
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final cat  = item['category'] as String;
                  final ctrl = controllers[cat]!;
                  final colors = [
                    const Color(0xFF00CED1), const Color(0xFF4CAF50),
                    const Color(0xFFFF9800), const Color(0xFF8B5CF6),
                    const Color(0xFFE91E63), const Color(0xFFFF5722),
                    const Color(0xFF009688), const Color(0xFF2196F3),
                  ];
                  final color = colors[i % colors.length];

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        // Icon + tên
                        Text(item['icon'] as String,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(cat,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87))),

                        // Input số tiền
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            onChanged: (_) => setS(() {}),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              suffixText: 'đ',
                              suffixStyle: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        // Xóa item
                        GestureDetector(
                          onTap: () => setS(() => items.removeAt(i)),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.remove_circle_outline_rounded,
                                size: 18, color: Colors.grey[400]),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              )),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(children: [
                  Divider(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  Row(children: [
                    // Huỷ
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 48, height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[200]!),
                        ),
                        child: Icon(Icons.close_rounded,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Lưu kế hoạch
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _savePlanToFirestore(
                          ctx,
                          items,
                          controllers,
                          getIncome(),
                          remaining,
                        ),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00CED1),
                                  Color(0xFF8B5CF6)
                                ]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFF00CED1).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_alt_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Lưu kế hoạch',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // SAVE lên Firestore
  // ══════════════════════════════════════════════════════
  Future<void> _savePlanToFirestore(
    BuildContext ctx,
    List<Map<String, dynamic>> items,
    Map<String, TextEditingController> controllers,
    int income,
    int remaining,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Build expense_table
      final table = <Map<String, dynamic>>[];
      for (final item in items) {
        final cat = item['category'] as String;
        final amt = int.tryParse(
                controllers[cat]?.text.replaceAll(',', '') ?? '0') ??
            0;
        table.add({
          'category': cat,
          'amount':   amt,
          'percent':  income > 0 ? (amt / income * 100).round() : 0,
          'note':     item['note'] ?? '',
        });
      }

      // Nếu còn dư → thêm vào Tiết kiệm
      if (remaining > 0) {
        final idx = table.indexWhere(
            (r) => (r['category'] as String).toLowerCase().contains('tiết kiệm'));
        if (idx != -1) {
          table[idx]['amount'] =
              (table[idx]['amount'] as int) + remaining;
          table[idx]['percent'] =
              income > 0
                  ? (table[idx]['amount'] as int) ~/ income * 100
                  : 0;
        } else {
          table.add({
            'category': 'Tiết kiệm',
            'amount':   remaining,
            'percent':  income > 0 ? (remaining / income * 100).round() : 0,
            'note':     'Phần còn lại sau chi tiêu',
          });
        }
      }

      final plan = {
        'recommended_income': income,
        'income_reason':
            'Thu nhập do người dùng nhập từ gợi ý BuddyAI.',
        'summary':
            'Kế hoạch được tạo từ gợi ý của BuddyAI dựa trên thu nhập ${income ~/ 1000000} triệu/tháng.',
        'expense_table': table,
        'tips': [
          'Chuyển tiền tiết kiệm ngay khi nhận lương.',
          'Ghi chép chi tiêu hàng ngày để kiểm soát tốt hơn.',
          'Xem lại kế hoạch mỗi cuối tháng.',
        ],
        'goal_plan':
            'Duy trì kế hoạch này để đạt mục tiêu tài chính trong 3-6 tháng.',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plans')
          .doc('current_plan')
          .set({
        'plan':      plan,
        'formData':  {},
        'createdAt': FieldValue.serverTimestamp(),
        'source':    'buddyai',
      });

      if (ctx.mounted) Navigator.pop(ctx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Đã lưu kế hoạch! Vào tab Plan để xem.'),
          ]),
          backgroundColor: const Color(0xFF00CED1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi lưu: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ══════════════════════════════════════════════════════
  // SEND MESSAGE
  // ══════════════════════════════════════════════════════
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping || _isStreaming) return;

    final userMsg = text.trim();
    _messageController.clear();
    _focusNode.unfocus();

    if (!mounted) return;
    setState(() {
      _hasStartedChat = true;
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        message: userMsg,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      String aiResponse = await _aiService.sendMessage(
        userMsg,
        chatHistory: _messages.length > 1
            ? _messages.sublist(0, _messages.length - 1)
            : [],
      );

      if (!mounted) return;

      final streamId = _uuid.v4();
      setState(() {
        _isTyping = false;
        _isStreaming = true;
        _streamingText = '';
        _streamingMessageId = streamId;
        _messages.add(ChatMessage(
          id: streamId,
          message: '',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      for (int i = 0; i < aiResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 8));
        if (!mounted) return;
        setState(() {
          _streamingText = aiResponse.substring(0, i + 1);
          final idx =
              _messages.indexWhere((m) => m.id == streamId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(
              id: streamId,
              message: _streamingText,
              isUser: false,
              timestamp: _messages[idx].timestamp,
            );
          }
        });
        if (i % 40 == 0) _scrollToBottom();
      }

      if (!mounted) return;

      // Detect plan items sau khi stream xong
      final planItems = _detectPlanItems(aiResponse);
      setState(() {
        _isStreaming = false;
        _streamingMessageId = null;
        if (planItems.isNotEmpty) {
          _detectedPlans[streamId] = planItems;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _isStreaming = false;
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          message: 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    if (mounted) _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text('Toàn bộ lịch sử sẽ bị xóa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _detectedPlans.clear();
                _hasStartedChat = false;
              });
            },
            child:
                const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF212121) : Colors.white;
    final textColor =
        isDark ? Colors.white : const Color(0xFF0D0D0D);
    final subColor = isDark
        ? const Color(0xFF8E8EA0)
        : const Color(0xFF8E8EA0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BuddyAI',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: subColor, size: 20),
          ],
        ),
        actions: [
          // Nút lưu kế hoạch — hiện khi có plan detect được
          if (_lastDetectedPlan.isNotEmpty)
            GestureDetector(
              onTap: () => _showSavePlanSheet(
                List<Map<String, dynamic>>.from(
                  _lastDetectedPlan.map((e) => Map<String, dynamic>.from(e)))),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.save_alt_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: textColor, size: 20),
              onPressed: _clearChat,
              tooltip: 'Cuộc trò chuyện mới',
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _hasStartedChat
              ? _buildChatList(isDark, textColor, subColor)
              : _buildWelcomeScreen(isDark, textColor, subColor),
        ),
        _buildInputBar(isDark, textColor, subColor),
      ]),
    );
  }

  // ── Welcome screen ────────────────────────────────────
  Widget _buildWelcomeScreen(
      bool isDark, Color textColor, Color subColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 48),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2F2F2F)
                : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(
                color: isDark
                    ? const Color(0xFF444444)
                    : const Color(0xFFE5E5E5)),
          ),
          child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(height: 20),
        Text('Tôi có thể giúp gì cho bạn?',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text('Hỏi về tài chính, lập kế hoạch chi tiêu, tiết kiệm...',
            style: TextStyle(fontSize: 13, color: subColor),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: _suggestions
              .map((s) => _buildSuggestionCard(s, isDark, textColor))
              .toList(),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildSuggestionCard(
      Map<String, String> s, bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => _sendMessage(s['text']!),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2F2F2F)
              : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF3F3F3F)
                  : const Color(0xFFE5E5E5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(s['emoji']!, style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(s['text']!,
              style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Chat list ─────────────────────────────────────────
  Widget _buildChatList(
      bool isDark, Color textColor, Color subColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingRow(isDark);
        }
        final msg = _messages[index];
        if (msg.isUser) {
          return _buildUserMessage(msg, isDark, textColor);
        } else {
          return _buildAIMessage(msg, isDark, textColor, subColor,
              isStreaming:
                  _isStreaming && msg.id == _streamingMessageId);
        }
      },
    );
  }

  // ── User message ──────────────────────────────────────
  Widget _buildUserMessage(
      ChatMessage msg, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.message));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Đã sao chép'),
                    duration: Duration(seconds: 1)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2F2F2F)
                      : const Color(0xFFF4F4F4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(msg.message,
                    style: TextStyle(
                        fontSize: 15, color: textColor, height: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI message + nút Lưu kế hoạch ────────────────────
  Widget _buildAIMessage(
      ChatMessage msg, bool isDark, Color textColor, Color subColor,
      {bool isStreaming = false}) {
    final planItems = _detectedPlans[msg.id];
    final hasPlan   = planItems != null && planItems.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        Container(
          width: 30, height: 30,
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2F2F2F)
                : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(
                color: isDark
                    ? const Color(0xFF444444)
                    : const Color(0xFFE5E5E5)),
          ),
          child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14))),
        ),

        // Content
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Message text
            if (msg.message.isEmpty && isStreaming)
              _buildTypingDots(isDark)
            else
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: msg.message));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã sao chép'),
                          duration: Duration(seconds: 1)));
                },
                child: _buildFormattedText(
                    msg.message, textColor, isStreaming),
              ),

            // ── NÚT LƯU KẾ HOẠCH ─────────────────────
            if (hasPlan && !isStreaming) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    _showSavePlanSheet(List<Map<String, dynamic>>.from(
                        planItems.map((e) =>
                            Map<String, dynamic>.from(e)))),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF00CED1),
                      Color(0xFF8B5CF6),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF00CED1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.save_alt_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '💾 Lưu ${planItems.length} mục vào kế hoạch',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildTypingRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2F2F2F)
                : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(
                color: isDark
                    ? const Color(0xFF444444)
                    : const Color(0xFFE5E5E5)),
          ),
          child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14))),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _buildTypingDots(isDark),
        ),
      ]),
    );
  }

  Widget _buildTypingDots(bool isDark) =>
      const SizedBox(height: 20, child: TypingIndicator());

  // ── Formatted text ────────────────────────────────────
  Widget _buildFormattedText(
      String text, Color textColor, bool isStreaming) {
    final lines   = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(line.substring(3),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(line.substring(4),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00CED1),
                      shape: BoxShape.circle)),
            ),
            Expanded(
                child: _buildInlineText(
                    line.substring(2), textColor)),
          ]),
        ));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\. (.+)').firstMatch(line);
        if (match != null) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(right: 8, top: 1),
                decoration: const BoxDecoration(
                    color: Color(0xFF00CED1),
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(match.group(1)!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                  child: _buildInlineText(
                      match.group(2)!, textColor)),
            ]),
          ));
        }
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _buildInlineText(line, textColor),
        ));
      }
    }

    if (isStreaming && text.isNotEmpty) widgets.add(_buildCursor());

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets);
  }

  Widget _buildInlineText(String text, Color textColor) {
    final spans   = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int last      = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, match.start),
            style: TextStyle(
                color: textColor, fontSize: 15, height: 1.6)));
      }
      spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w700)));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
          text: text.substring(last),
          style: TextStyle(
              color: textColor, fontSize: 15, height: 1.6)));
    }

    if (spans.isEmpty) {
      return Text(text,
          style: TextStyle(
              color: textColor, fontSize: 15, height: 1.6));
    }
    return RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.left);
  }

  Widget _buildCursor() => const _BlinkingCursor();

  // ── Input bar ─────────────────────────────────────────
  Widget _buildInputBar(
      bool isDark, Color textColor, Color subColor) {
    final hasText =
        _messageController.text.trim().isNotEmpty;
    final isBusy = _isTyping || _isStreaming;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: isDark ? const Color(0xFF212121) : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2F2F2F)
              : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF3F3F3F)
                  : const Color(0xFFE5E5E5)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: !isBusy,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                  color: textColor, fontSize: 15, height: 1.4),
              decoration: InputDecoration(
                hintText: isBusy
                    ? 'BuddyAI đang trả lời...'
                    : 'Hỏi bất cứ điều gì...',
                hintStyle: TextStyle(color: subColor, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: GestureDetector(
              onTap: (hasText && !isBusy)
                  ? () => _sendMessage(_messageController.text)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: (hasText && !isBusy)
                      ? const Color(0xFF00CED1)
                      : (isDark
                          ? const Color(0xFF3F3F3F)
                          : const Color(0xFFE5E5E5)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBusy
                      ? Icons.stop_rounded
                      : Icons.arrow_upward_rounded,
                  color: (hasText && !isBusy)
                      ? Colors.white
                      : subColor,
                  size: 18,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// ── Blinking cursor ───────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _controller.value,
        child: Container(
          width: 2, height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
              color: const Color(0xFF00CED1),
              borderRadius: BorderRadius.circular(1)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}