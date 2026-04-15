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

class _ChatbotViewState extends State<ChatbotView> with TickerProviderStateMixin {
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

  final Map<String, List<Map<String, dynamic>>> _detectedPlans = {};

  final List<Map<String, String>> _suggestions = [
    {'emoji': '📊', 'text': 'Lương 10 triệu nên chi tiêu thế nào?'},
    {'emoji': '💰', 'text': 'Lương 15 triệu, tôi nên phân bổ ra sao?'},
    {'emoji': '🎯', 'text': 'Thu nhập 8 triệu, kế hoạch chi tiêu hợp lý?'},
    {'emoji': '📈', 'text': 'Làm sao tiết kiệm được nhiều hơn mỗi tháng?'},
  ];

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
    _messageController.addListener(() => setState(() {}));
  }

  // ══════════════════════════════════════════════════════
  // DETECT income từ text người dùng
  // ══════════════════════════════════════════════════════
  int _detectIncomeFromText(String text) {
    final lower = text.toLowerCase();
    final patterns = [
      RegExp(r'(?:lương|thu nhập|kiếm|nhận|có)\s*(\d+(?:[,.]\d+)?)\s*(?:triệu|tr)', caseSensitive: false),
      RegExp(r'(\d+(?:[,.]\d+)?)\s*(?:triệu|tr)\s*(?:\/\s*tháng|mỗi tháng|một tháng|1 tháng)', caseSensitive: false),
      RegExp(r'(\d+(?:[,.]\d+)?)\s*(?:triệu|tr)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(lower);
      if (m != null) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
        if (v != null && v >= 1 && v <= 500) return (v * 1000000).toInt();
      }
    }
    return 0;
  }

  int _detectIncomeFromMessages() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser) continue;
      final income = _detectIncomeFromText(_messages[i].message);
      if (income > 0) return income;
    }
    return 0;
  }

  bool _isBudgetQuestion(String text) {
    final lower = text.toLowerCase();
    final keywords = ['lương', 'thu nhập', 'triệu', 'chi tiêu', 'kế hoạch', 'tiết kiệm', 'phân bổ', 'ngân sách'];
    return keywords.any((k) => lower.contains(k));
  }

  // ══════════════════════════════════════════════════════
  // BUILD MESSAGE GỬI CHO AI — ép format ngắn gọn
  // ══════════════════════════════════════════════════════
  String _buildPromptForAI(String userMsg) {
    if (!_isBudgetQuestion(userMsg)) return userMsg;

    final income = _detectIncomeFromText(userMsg);
    final incomeStr = income > 0
        ? '${income ~/ 1000000} triệu đồng'
        : 'thu nhập người dùng đề cập';

    return '''$userMsg

Trả lời NGẮN GỌN, tối đa 6 mục, đúng format sau:
- 1 câu tóm tắt ngắn
- Mỗi mục 1 dòng: "Tên mục: X triệu đồng" (số TRÒN, bội số 0.5 triệu)
- Tổng tất cả các mục = đúng $incomeStr (bắt buộc)
- 1 câu lời khuyên ngắn cuối''';
  }

  // ══════════════════════════════════════════════════════
  // DETECT plan items từ AI response — đơn giản, chính xác
  // ══════════════════════════════════════════════════════
  List<Map<String, dynamic>> _detectPlanItems(String text) {
    final iconMap = <String, String>{
      'nhà': '🏠', 'thuê': '🏠', 'sinh hoạt': '🏠',
      'ăn': '🍜', 'uống': '🍜', 'thực phẩm': '🍜',
      'đi lại': '🚗', 'di chuyển': '🚗', 'xăng': '🚗', 'giao thông': '🚗',
      'giải trí': '🎬', 'phim': '🎬',
      'tiết kiệm': '💰',
      'đầu tư': '📈',
      'học': '📚', 'giáo dục': '📚',
      'sức khoẻ': '💊', 'y tế': '💊', 'thuốc': '💊',
      'tiện ích': '💡', 'điện': '💡', 'nước': '💡', 'internet': '💡',
      'mua sắm': '🛍️',
      'dự phòng': '🛡️',
    };

    String getIcon(String name) {
      final lower = name.toLowerCase();
      for (final kv in iconMap.entries) {
        if (lower.contains(kv.key)) return kv.value;
      }
      return '📌';
    }

    // Parse số tiền từ string — trả về đơn vị đồng
    int? parseAmount(String raw) {
      // "X,X triệu" hoặc "X.X triệu" hoặc "X triệu"
      final mTrieu = RegExp(r'(\d+(?:[,.]\d+)?)\s*(?:triệu|tr)(?:\s*đồng)?', caseSensitive: false).firstMatch(raw);
      if (mTrieu != null) {
        final v = double.tryParse(mTrieu.group(1)!.replaceAll(',', '.'));
        if (v != null && v >= 0.1 && v <= 500) return (v * 1000000).round();
      }
      // "X,XXX,XXX đ" hoặc số lớn
      final mDong = RegExp(r'(\d[\d,.]+)\s*(?:đồng|đ|VND)?$', caseSensitive: false).firstMatch(raw.trim());
      if (mDong != null) {
        final cleaned = mDong.group(1)!.replaceAll(',', '').replaceAll('.', '');
        final v = int.tryParse(cleaned);
        if (v != null && v >= 100000 && v <= 500000000) return v;
      }
      return null;
    }

    final items = <Map<String, dynamic>>[];
    final seenNames = <String>{};

    // Tìm tất cả dòng có dạng "Tên: số tiền"
    final linePattern = RegExp(
      r'^[*\-•\s\d.)\s]*([^\n:*]{2,40}?)\s*(?:\(\d+%\))?\s*:\s*([^\n]{1,40})$',
      multiLine: true,
    );

    final skipWords = [
      'thu nhập', 'lương', 'tổng', 'còn lại', 'số dư', 'ví dụ',
      'lưu ý', 'ghi chú', 'tip', 'khuyên', 'mục tiêu', 'tháng',
    ];

    for (final m in linePattern.allMatches(text)) {
      var name = m.group(1)!
          .replaceAll(RegExp(r'\*+'), '')
          .replaceAll(RegExp(r'^[\d\s.)\-–•]+'), '')
          .trim();
      final amtStr = m.group(2) ?? '';

      if (name.length < 2 || name.length > 50) continue;
      if (skipWords.any((w) => name.toLowerCase().contains(w))) continue;

      final amt = parseAmount(amtStr);
      if (amt == null || amt <= 0) continue;

      final key = name.toLowerCase();
      if (seenNames.contains(key)) continue;
      seenNames.add(key);

      items.add({
        'category': name,
        'amount': amt,
        'icon': getIcon(name),
        'note': '',
        'percent': 0,
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
  // BOTTOM SHEET — lưu kế hoạch
  // ══════════════════════════════════════════════════════
  void _showSavePlanSheet(List<Map<String, dynamic>> rawItems, int detectedIncome) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Deep copy items để không mutate original
    final items = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();

    // Tính tổng gốc từ AI
    final aiTotal = items.fold<int>(0, (s, i) => s + (i['amount'] as int));

    // Nếu detect được income và AI total khác → scale lại để khớp
    if (detectedIncome > 0 && aiTotal > 0 && (detectedIncome - aiTotal).abs() > 10000) {
      final ratio = detectedIncome / aiTotal;
      for (final item in items) {
        // Round to nearest 500k for clean numbers
        final raw = ((item['amount'] as int) * ratio).round();
        item['amount'] = (raw / 500000).round() * 500000;
      }
      // Adjust last item to ensure exact total
      final newTotal = items.fold<int>(0, (s, i) => s + (i['amount'] as int));
      if (items.isNotEmpty && newTotal != detectedIncome) {
        items.last['amount'] = (items.last['amount'] as int) + (detectedIncome - newTotal);
      }
    }

    final controllers = <String, TextEditingController>{
      for (final item in items)
        item['category'] as String: TextEditingController(text: '${item['amount']}')
    };

    final incomeCtrl = TextEditingController(
        text: '${detectedIncome > 0 ? detectedIncome : items.fold<int>(0, (s, i) => s + (i['amount'] as int))}');

    final extraItems = <Map<String, String>>[];

    String fmt(dynamic v) {
      final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        int getIncome() => int.tryParse(incomeCtrl.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;

        int getTotal() {
          int t = controllers.values.fold(0, (s, c) => s + (int.tryParse(c.text.replaceAll(',', '').replaceAll('.', '')) ?? 0));
          t += extraItems.fold(0, (s, e) => s + (int.tryParse(e['amount']!.replaceAll(',', '').replaceAll('.', '')) ?? 0));
          return t;
        }

        final income    = getIncome();
        final total     = getTotal();
        final remaining = income - total;
        final isOver    = remaining < -1000;

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            )),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                const Text('💾', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Lưu vào kế hoạch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Chỉnh sửa rồi lưu theo ý bạn', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[700])),
                ),
              ]),
            ),

            // Thu nhập
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00CED1).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF00CED1), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Thu nhập / tháng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  SizedBox(width: 140,
                    child: TextField(
                      controller: incomeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: (_) => setS(() {}),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00CED1)),
                      decoration: const InputDecoration(
                        border: InputBorder.none, isDense: true,
                        suffixText: ' đ',
                        suffixStyle: TextStyle(color: Color(0xFF00CED1), fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // Thanh tổng
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOver ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isOver ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(isOver ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                      color: isOver ? Colors.red : Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    isOver ? '⚠️ Vượt ${fmt(remaining.abs())}đ so với thu nhập!'
                           : '✅ Còn lại ${fmt(remaining)}đ → vào Tiết kiệm',
                    style: TextStyle(fontSize: 12,
                        color: isOver ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500),
                  )),
                  Text('${fmt(total)}đ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                          color: isOver ? Colors.red : Colors.green)),
                ]),
              ),
            ),

            Divider(height: 1, color: Colors.grey[200]),

            // Danh sách
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                ...items.asMap().entries.map((e) {
                  final i    = e.key;
                  final item = e.value;
                  final cat  = item['category'] as String;
                  final ctrl = controllers[cat];
                  if (ctrl == null) return const SizedBox.shrink();
                  final colors = [
                    const Color(0xFF00CED1), const Color(0xFF4CAF50),
                    const Color(0xFFFF9800), const Color(0xFF8B5CF6),
                    const Color(0xFFE91E63), const Color(0xFFFF5722),
                    const Color(0xFF009688), const Color(0xFF2196F3),
                    const Color(0xFFFFC107), const Color(0xFF607D8B),
                  ];
                  final color = colors[i % colors.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(children: [
                        Text(item['icon'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(cat, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87))),
                        SizedBox(width: 120,
                          child: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            onChanged: (_) => setS(() {}),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                            decoration: InputDecoration(
                              border: InputBorder.none, isDense: true,
                              suffixText: ' đ',
                              suffixStyle: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setS(() { items.removeAt(i); controllers.remove(cat); }),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.grey[400]),
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),

                // Extra items
                ...extraItems.asMap().entries.map((e) {
                  final i = e.key; final item = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(children: [
                        const Text('📌', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(
                          onChanged: (v) => setS(() => item['name'] = v),
                          controller: TextEditingController(text: item['name'])
                            ..selection = TextSelection.collapsed(offset: item['name']!.length),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Tên mục mới...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                          ),
                        )),
                        SizedBox(width: 110,
                          child: TextField(
                            onChanged: (v) => setS(() => item['amount'] = v),
                            controller: TextEditingController(text: item['amount'])
                              ..selection = TextSelection.collapsed(offset: item['amount']!.length),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                            decoration: const InputDecoration(
                              border: InputBorder.none, isDense: true,
                              suffixText: ' đ',
                              suffixStyle: TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 11),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setS(() => extraItems.removeAt(i)),
                          child: Padding(padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.red[300])),
                        ),
                      ]),
                    ),
                  );
                }).toList(),

                // Nút thêm
                GestureDetector(
                  onTap: () => setS(() => extraItems.add({'name': '', 'amount': ''})),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00CED1).withOpacity(0.4), width: 1.5),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_rounded, color: Color(0xFF00CED1), size: 20),
                      SizedBox(width: 8),
                      Text('Thêm mục chi tiêu', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: Color(0xFF00CED1))),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            )),

            // Nút lưu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(children: [
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 12),
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 48, height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                      ),
                      child: Icon(Icons.close_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: isOver ? null : () {
                        final allControllers = Map<String, TextEditingController>.from(controllers);
                        final allItems = List<Map<String, dynamic>>.from(items);
                        for (final extra in extraItems) {
                          final name = extra['name']!.trim();
                          if (name.isEmpty) continue;
                          allControllers[name] = TextEditingController(text: extra['amount']!);
                          allItems.add({'category': name, 'amount': int.tryParse(extra['amount']!.replaceAll(',', '')) ?? 0, 'icon': '📌', 'note': '', 'percent': 0});
                        }
                        _savePlanToFirestore(ctx, allItems, allControllers, getIncome(), remaining);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isOver ? null : const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
                          color: isOver ? Colors.grey[300] : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isOver ? [] : [BoxShadow(color: const Color(0xFF00CED1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(isOver ? Icons.block_rounded : Icons.save_alt_rounded,
                              color: isOver ? Colors.grey[500] : Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(isOver ? 'Vượt ngân sách — không thể lưu' : 'Lưu kế hoạch',
                              style: TextStyle(color: isOver ? Colors.grey[500] : Colors.white,
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════
  // SAVE lên Firestore — tổng luôn = income
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

      final table = <Map<String, dynamic>>[];
      for (final item in items) {
        final cat = item['category'] as String;
        final amt = int.tryParse(controllers[cat]?.text.replaceAll(',', '').replaceAll('.', '') ?? '0') ?? 0;
        if (amt <= 0) continue;
        table.add({
          'category': cat,
          'amount':   amt,
          'percent':  income > 0 ? (amt / income * 100).round() : 0,
          'note':     item['note'] ?? '',
        });
      }

      // Phần còn dư → thêm/cộng vào Tiết kiệm
      if (remaining > 1000) {
        final idx = table.indexWhere((r) => (r['category'] as String).toLowerCase().contains('tiết kiệm'));
        if (idx != -1) {
          table[idx]['amount'] = (table[idx]['amount'] as int) + remaining;
          table[idx]['percent'] = income > 0 ? ((table[idx]['amount'] as int) / income * 100).round() : 0;
        } else {
          table.add({
            'category': 'Tiết kiệm',
            'amount':   remaining,
            'percent':  income > 0 ? (remaining / income * 100).round() : 0,
            'note':     'Phần còn lại sau chi tiêu',
          });
        }
      }

      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('plans').doc('current_plan')
          .set({
        'plan': {
          'recommended_income': income,
          'income_reason': 'Kế hoạch từ BuddyAI.',
          'summary': 'Kế hoạch dựa trên thu nhập ${(income / 1000000).toStringAsFixed(0)} triệu/tháng.',
          'expense_table': table,
          'tips': ['Chuyển tiền tiết kiệm ngay khi nhận lương.', 'Ghi chép chi tiêu hàng ngày.', 'Xem lại kế hoạch mỗi cuối tháng.'],
          'goal_plan': 'Duy trì kế hoạch này để kiểm soát tài chính hiệu quả.',
        },
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e'), backgroundColor: Colors.red));
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
      _messages.add(ChatMessage(id: _uuid.v4(), message: userMsg, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Wrap message với format instructions nếu là câu hỏi về budget
      final promptForAI = _buildPromptForAI(userMsg);

      final aiResponse = await _aiService.sendMessage(
        promptForAI,
        chatHistory: _messages.length > 1 ? _messages.sublist(0, _messages.length - 1) : [],
      );

      if (!mounted) return;
      final streamId = _uuid.v4();
      setState(() {
        _isTyping = false;
        _isStreaming = true;
        _streamingText = '';
        _streamingMessageId = streamId;
        _messages.add(ChatMessage(id: streamId, message: '', isUser: false, timestamp: DateTime.now()));
      });

      const chunkSize = 5;
      for (int i = 0; i < aiResponse.length; i += chunkSize) {
        await Future.delayed(const Duration(milliseconds: 12));
        if (!mounted) return;
        final chunk = aiResponse.substring(0, (i + chunkSize).clamp(0, aiResponse.length));
        setState(() {
          _streamingText = chunk;
          final idx = _messages.indexWhere((m) => m.id == streamId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(id: streamId, message: chunk, isUser: false, timestamp: _messages[idx].timestamp);
          }
        });
        if (i % 80 == 0) _scrollToBottom();
      }

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == streamId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(id: streamId, message: aiResponse, isUser: false, timestamp: _messages[idx].timestamp);
          }
        });
      }

      if (!mounted) return;

      final planItems = _detectPlanItems(aiResponse);
      final detectedIncome = _detectIncomeFromMessages();

      setState(() {
        _isStreaming = false;
        _streamingMessageId = null;
        if (planItems.isNotEmpty) {
          // Gắn income để sheet dùng
          for (final item in planItems) {
            item['_income'] = detectedIncome;
          }
          _detectedPlans[streamId] = planItems;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _isStreaming = false;
        _messages.add(ChatMessage(id: _uuid.v4(), message: 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại!', isUser: false, timestamp: DateTime.now()));
      });
    }
    if (mounted) _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _clearChat() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Xóa cuộc trò chuyện?'),
      content: const Text('Toàn bộ lịch sử sẽ bị xóa.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() { _messages.clear(); _detectedPlans.clear(); _hasStartedChat = false; });
          },
          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF212121) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final subColor = const Color(0xFF8E8EA0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('BuddyAI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, color: subColor, size: 20),
        ]),
        actions: [
          if (_lastDetectedPlan.isNotEmpty)
            GestureDetector(
              onTap: () {
                final income = (_lastDetectedPlan.isNotEmpty ? _lastDetectedPlan.first['_income'] as int? : null) ?? _detectIncomeFromMessages();
                _showSavePlanSheet(
                  List<Map<String, dynamic>>.from(_lastDetectedPlan.map((e) => Map<String, dynamic>.from(e))),
                  income,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 28, height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.save_alt_rounded, color: Colors.white, size: 14),
              ),
            ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: textColor, size: 20),
              onPressed: _clearChat,
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

  Widget _buildWelcomeScreen(bool isDark, Color textColor, Color subColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 48),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E5E5)),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(height: 20),
        Text('Tôi có thể giúp gì cho bạn?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text('Hỏi về tài chính, kế hoạch chi tiêu, tiết kiệm...',
            style: TextStyle(fontSize: 13, color: subColor), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
          children: _suggestions.map((s) => _buildSuggestionCard(s, isDark, textColor)).toList(),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildSuggestionCard(Map<String, String> s, bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => _sendMessage(s['text']!),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF3F3F3F) : const Color(0xFFE5E5E5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['emoji']!, style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(s['text']!, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildChatList(bool isDark, Color textColor, Color subColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingRow(isDark);
        final msg = _messages[index];
        if (msg.isUser) return _buildUserMessage(msg, isDark, textColor);
        return _buildAIMessage(msg, isDark, textColor, subColor,
            isStreaming: _isStreaming && msg.id == _streamingMessageId);
      },
    );
  }

  Widget _buildUserMessage(ChatMessage msg, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 48),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Flexible(
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: msg.message));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép'), duration: Duration(seconds: 1)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18), topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(msg.message, style: TextStyle(fontSize: 15, color: textColor, height: 1.5)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAIMessage(ChatMessage msg, bool isDark, Color textColor, Color subColor, {bool isStreaming = false}) {
    final planItems = _detectedPlans[msg.id];
    final hasPlan   = planItems != null && planItems.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E5E5)),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (msg.message.isEmpty && isStreaming)
            _buildTypingDots(isDark)
          else
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.message));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép'), duration: Duration(seconds: 1)));
              },
              child: _buildFormattedText(msg.message, textColor, isStreaming),
            ),

          // Nút lưu kế hoạch
          if (hasPlan && !isStreaming) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                final income = (planItems.isNotEmpty ? planItems.first['_income'] as int? : null) ?? _detectIncomeFromMessages();
                _showSavePlanSheet(
                  List<Map<String, dynamic>>.from(planItems.map((e) => Map<String, dynamic>.from(e))),
                  income,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFF00CED1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.save_alt_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('💾 Lưu ${planItems.length} mục vào kế hoạch',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ])),
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
            color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E5E5)),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
        ),
        Padding(padding: const EdgeInsets.only(top: 8), child: _buildTypingDots(isDark)),
      ]),
    );
  }

  Widget _buildTypingDots(bool isDark) => const SizedBox(height: 20, child: TypingIndicator());

  Widget _buildFormattedText(String text, Color textColor, bool isStreaming) {
    final lines   = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('## ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(line.substring(3), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(line.substring(4), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF00CED1), shape: BoxShape.circle))),
            Expanded(child: _buildInlineText(line.substring(2), textColor)),
          ])));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\. (.+)').firstMatch(line);
        if (match != null) {
          widgets.add(Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 22, height: 22, margin: const EdgeInsets.only(right: 8, top: 1),
                decoration: const BoxDecoration(color: Color(0xFF00CED1), shape: BoxShape.circle),
                child: Center(child: Text(match.group(1)!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
              Expanded(child: _buildInlineText(match.group(2)!, textColor)),
            ])));
        }
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 2), child: _buildInlineText(line, textColor)));
      }
    }

    if (isStreaming && text.isNotEmpty) widgets.add(_buildCursor());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildInlineText(String text, Color textColor) {
    final spans   = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) spans.add(TextSpan(text: text.substring(last, match.start), style: TextStyle(color: textColor, fontSize: 15, height: 1.6)));
      spans.add(TextSpan(text: match.group(1), style: TextStyle(color: textColor, fontSize: 15, height: 1.6, fontWeight: FontWeight.w700)));
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: TextStyle(color: textColor, fontSize: 15, height: 1.6)));
    if (spans.isEmpty) return Text(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.6));
    return RichText(text: TextSpan(children: spans), textAlign: TextAlign.left);
  }

  Widget _buildCursor() => const _BlinkingCursor();

  Widget _buildInputBar(bool isDark, Color textColor, Color subColor) {
    final hasText = _messageController.text.trim().isNotEmpty;
    final isBusy  = _isTyping || _isStreaming;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: isDark ? const Color(0xFF212121) : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF3F3F3F) : const Color(0xFFE5E5E5)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(
            controller: _messageController,
            focusNode: _focusNode,
            enabled: !isBusy,
            maxLines: 5, minLines: 1,
            textInputAction: TextInputAction.newline,
            style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
            decoration: InputDecoration(
              hintText: isBusy ? 'BuddyAI đang trả lời...' : 'Hỏi bất cứ điều gì...',
              hintStyle: TextStyle(color: subColor, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: GestureDetector(
              onTap: (hasText && !isBusy) ? () => _sendMessage(_messageController.text) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: (hasText && !isBusy) ? const Color(0xFF00CED1) : (isDark ? const Color(0xFF3F3F3F) : const Color(0xFFE5E5E5)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBusy ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  color: (hasText && !isBusy) ? Colors.white : subColor,
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

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
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
          decoration: BoxDecoration(color: const Color(0xFF00CED1), borderRadius: BorderRadius.circular(1)),
        ),
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}