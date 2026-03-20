// lib/view/AnalysisView.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './Transaction.dart';
import './HomeView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';
import './AddSavingGoalView.dart';
import './analysis_widgets.dart';
import './Spend_rule_view.dart';
import './Plan_form_screen.dart';
import './Plan_entry_view.dart';
import './Plan_form_data.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({Key? key}) : super(key: key);
  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  Map<String, dynamic>? _savedPlan;
  Map<String, dynamic>? _savedFormData;
  bool _isGenerating = false;

  static const _backendUrl =
      'https://buddy-budget-system-backend.onrender.com/api/chat';

  void _onPlanCreated(Map<String, dynamic> plan, Map<String, dynamic> formData) {
    setState(() { _savedPlan = plan; _savedFormData = formData; });
  }

  void _resetPlan() {
    setState(() { _savedPlan = null; _savedFormData = null; });
  }

  String _fmt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // ── Build prompt ─────────────────────────────────────
  String _buildPrompt(Map<String, dynamic> d) {
    final cityLabel = PlanFormData.cityName(d['city'] ?? 'HCM');
    final occLabel  = PlanFormData.occupationLabel(
        d['occupation'] ?? 'Employee', d['customOccupation'] ?? '');

    final livMap = {
      'WithFamily': 'Ở cùng gia đình (không tốn tiền thuê)',
      'Renting':    'Thuê nhà/phòng trọ',
      'OwnHouse':   'Có nhà riêng (không tốn tiền thuê)',
      'Dormitory':  'Ký túc xá / lưu xá (chi phí thấp)',
      'Boarding':   'Nhà trọ sinh viên',
      'NoHouse':    'Chưa có nhà ở cố định',
    };

    final goalMap = {
      'Emergency': 'Quỹ dự phòng', 'BuyHouse': 'Mua nhà',
      'BuyCar': 'Mua xe', 'Travel': 'Du lịch', 'Invest': 'Đầu tư',
      'Retire': 'Hưu trí sớm', 'Education': 'Học tập / Du học',
      'Wedding': 'Đám cưới', 'Business': 'Khởi nghiệp', 'Health': 'Quỹ y tế',
    };

    final goals = (d['savingGoals'] as List? ?? [d['savingGoal'] ?? 'Emergency'])
        .map((g) => goalMap[g] ?? g.toString()).join(', ');

    final hasDebt    = d['hasDebt'] as bool? ?? false;
    final hasSavings = d['hasSavings'] as bool? ?? false;
    final married    = d['maritalStatus'] == 'Married';
    final stability  = d['incomeStability'] ?? 'Stable';
    final sources    = (d['incomeSources'] as List? ?? []).join(', ');

    // ✅ Thu nhập hiện tại & mong muốn
    final currentSalary = (d['currentSalary'] as num?)?.toDouble() ?? 0;
    final targetSalary  = (d['targetSalary']  as num?)?.toDouble() ?? 0;
    final currentSalaryText = currentSalary > 0
        ? '${_fmt(currentSalary)}đ/tháng'
        : 'Chưa cung cấp';
    final targetSalaryText = targetSalary > 0
        ? '${_fmt(targetSalary)}đ/tháng'
        : 'Chưa cung cấp';

    return '''Bạn là chuyên gia tư vấn tài chính cá nhân tại Việt Nam. Hãy lập kế hoạch tài chính cá nhân dựa trên thông tin sau:

THÔNG TIN NGƯỜI DÙNG:
- Nghề nghiệp: $occLabel
- Độ tuổi: ${d['ageRange'] ?? '22-30'}
- Hôn nhân: ${married ? 'Đã kết hôn' : 'Độc thân'}
- Thành phố: $cityLabel
- Chỗ ở: ${livMap[d['livingStatus']] ?? d['livingStatus']}
- Thu nhập ổn định: $stability
- Nguồn thu: ${sources.isEmpty ? 'Chưa rõ' : sources}
- Thu nhập hiện tại: $currentSalaryText
- Thu nhập mong muốn: $targetSalaryText
- Có con: ${d['hasChildren'] ?? 'Chưa có con'}
- Phương tiện: ${d['transport'] ?? 'Xe máy'}
- Thói quen ăn uống: ${d['eatingHabit'] ?? '50% nấu, 50% ăn ngoài'}
- Chi tiêu hiện tại: ${d['currentSpending'] ?? 'Chưa rõ'}
- Bảo hiểm y tế: ${d['insurance'] ?? 'Chưa có bảo hiểm'}
- Có nợ: ${hasDebt ? 'Có (${_fmt(d['debtAmount'])}đ)' : 'Không'}
- Có tiết kiệm: ${hasSavings ? 'Có' : 'Chưa có'}
- Mục tiêu tài chính: $goals

BẢNG LƯƠNG THAM KHẢO THỰC TẾ 2024:
- Sinh viên / thực tập: 3 - 6 triệu/tháng
- Nhân viên mới (HCM/HN): 8 - 15 triệu/tháng
- Kỹ sư IT (HCM): 15 - 35 triệu/tháng
- Freelancer: 10 - 30 triệu/tháng
- Bác sĩ / Y dược: 15 - 35 triệu/tháng
- Giáo viên: 7 - 12 triệu/tháng
- Kinh doanh: 12 - 40 triệu/tháng

BẢNG GIÁ THUÊ NHÀ THỰC TẾ 2024:
- TP. Hồ Chí Minh: phòng trọ 2-3tr, căn hộ mini 4-6tr, chung cư 7-12tr
- Hà Nội: phòng trọ 2-3tr, căn hộ mini 3-5tr, chung cư 6-10tr
- Đà Nẵng: phòng trọ 1.5-2.5tr, căn hộ 3-5tr
- Tỉnh khác: phòng trọ 1-2tr, căn hộ 2-4tr

YÊU CẦU QUAN TRỌNG:
- Nếu user đã cung cấp "Thu nhập hiện tại" → dùng con số đó làm cơ sở, KHÔNG tự đoán
- Nếu có "Thu nhập mong muốn" → đề xuất lộ trình đạt được
- Nếu cả 2 đều chưa cung cấp → dùng bảng tham khảo ở trên để ước tính
- Tổng expense_table phải BẰNG recommended_income
- Nếu ở cùng gia đình hoặc có nhà riêng → KHÔNG có khoản Nhà ở
- Không dùng chữ "AI" trong bất kỳ text nào

Trả về JSON hợp lệ (KHÔNG markdown, KHÔNG backtick):
{
  "recommended_income": <số nguyên, đơn vị đồng>,
  "income_reason": "<lý do ngắn gọn 1 câu>",
  "summary": "<nhận xét 2 câu về tình hình tài chính>",
  "expense_table": [
    {"category": "Nhà ở", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Ăn uống", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Di chuyển", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Hóa đơn tiện ích", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Mua sắm cá nhân", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Giải trí & xã hội", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Tiết kiệm", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Đầu tư & học tập", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Quỹ dự phòng", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"}
    ${hasDebt ? ',{"category": "Trả nợ hàng tháng", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Thanh toán đều đặn"}' : ''}
    ${married ? ',{"category": "Chi phí gia đình", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Chi phí sinh hoạt chung"}' : ''}
  ],
  "tips": [
    "<lời khuyên 1 - cụ thể, thiết thực>",
    "<lời khuyên 2 - cụ thể, thiết thực>",
    "<lời khuyên 3 - cụ thể, thiết thực>"
  ],
  "goal_plan": "<lộ trình 2-3 câu để đạt mục tiêu $goals>"
}''';
  }

  // ── Fallback khi backend lỗi ─────────────────────────
  Map<String, dynamic> _fallbackPlan(Map<String, dynamic> d) {
    final city       = d['city'] as String? ?? 'HCM';
    final occupation = d['occupation'] as String? ?? 'Employee';
    final living     = d['livingStatus'] as String? ?? 'Renting';
    final hasDebt    = d['hasDebt'] as bool? ?? false;
    final married    = d['maritalStatus'] == 'Married';

    // ✅ Ưu tiên dùng thu nhập user nhập
    final inputSalary = (d['currentSalary'] as num?)?.toDouble() ?? 0;

    final baseIncome = <String, double>{
      'Student': 5000000, 'Employee': 12000000, 'Freelancer': 15000000,
      'Business': 18000000, 'Doctor': 22000000, 'Teacher': 10000000,
      'Engineer': 15000000, 'Other': 10000000,
    };
    final cityMult = <String, double>{
      'HCM': 1.0, 'Hanoi': 0.95, 'DaNang': 0.85,
      'HaiPhong': 0.85, 'BinhDuong': 0.90,
    };

    // Nếu user đã nhập → dùng luôn, không override
    final baseRec = (baseIncome[occupation] ?? 12000000) * (cityMult[city] ?? 0.80);
    final rec = inputSalary > 0 ? inputSalary : baseRec;

    final rentByCity = <String, double>{
      'HCM': 3800000, 'Hanoi': 3200000, 'DaNang': 2800000,
      'HaiPhong': 2500000, 'BinhDuong': 2500000,
    };
    double rent = 0;
    if (living == 'Renting')   rent = rentByCity[city] ?? 2000000;
    if (living == 'Boarding')  rent = 1500000;
    if (living == 'Dormitory') rent = 800000;

    final food    = (rec * (occupation == 'Student' ? 0.22 : 0.18)).roundToDouble();
    final trans   = (rec * 0.08).roundToDouble();
    final bills   = (rec * 0.05).roundToDouble();
    final shop    = (rec * 0.06).roundToDouble();
    final ent     = (rec * 0.05).roundToDouble();
    final saving  = (rec * 0.20).roundToDouble();
    final invest  = (rec * (occupation == 'Student' ? 0.05 : 0.10)).roundToDouble();
    final emerg   = (rec * 0.05).roundToDouble();
    final family  = married ? (rec * 0.05).roundToDouble() : 0.0;
    final debtPay = hasDebt  ? (rec * 0.10).roundToDouble() : 0.0;

    final cityName = PlanFormData.cityName(city);
    final occLabel = PlanFormData.occupationLabel(
        occupation, d['customOccupation'] ?? '');

    final List<Map<String, dynamic>> table = [
      if (rent > 0)
        {'category': 'Nhà ở', 'amount': rent,
          'percent': (rent/rec*100).round(), 'note': 'Chi phí chỗ ở tại $cityName'},
      {'category': 'Ăn uống', 'amount': food,
        'percent': (food/rec*100).round(), 'note': 'Ăn sáng, trưa, tối'},
      {'category': 'Di chuyển', 'amount': trans,
        'percent': (trans/rec*100).round(), 'note': 'Xăng xe, Grab, xe buýt'},
      {'category': 'Hóa đơn tiện ích', 'amount': bills,
        'percent': (bills/rec*100).round(), 'note': 'Điện, nước, internet'},
      {'category': 'Mua sắm cá nhân', 'amount': shop,
        'percent': (shop/rec*100).round(), 'note': 'Quần áo, đồ dùng'},
      {'category': 'Giải trí & xã hội', 'amount': ent,
        'percent': (ent/rec*100).round(), 'note': 'Cà phê, phim, bạn bè'},
      {'category': 'Tiết kiệm', 'amount': saving,
        'percent': (saving/rec*100).round(), 'note': 'Chuyển ngay đầu tháng'},
      {'category': 'Đầu tư & học tập', 'amount': invest,
        'percent': (invest/rec*100).round(), 'note': 'Khóa học, sách, cổ phiếu'},
      {'category': 'Quỹ dự phòng', 'amount': emerg,
        'percent': (emerg/rec*100).round(), 'note': 'Tình huống bất ngờ'},
      if (hasDebt)
        {'category': 'Trả nợ hàng tháng', 'amount': debtPay,
          'percent': (debtPay/rec*100).round(), 'note': 'Thanh toán đều đặn'},
      if (married)
        {'category': 'Chi phí gia đình', 'amount': family,
          'percent': (family/rec*100).round(), 'note': 'Chi phí sinh hoạt chung'},
    ];

    return {
      'recommended_income': rec,
      'income_reason': 'Mức phù hợp với $occLabel tại $cityName',
      'summary':
          'Với hoàn cảnh của bạn tại $cityName, kế hoạch được xây dựng '
          'để cân bằng chi tiêu và đạt mục tiêu tài chính. '
          'Ưu tiên tiết kiệm ngay từ đầu tháng để tạo thói quen tốt.',
      'expense_table': table,
      'tips': [
        'Chuyển ${_fmt(saving)}đ vào tài khoản tiết kiệm ngay khi nhận lương',
        'Ghi chép chi tiêu hàng ngày bằng Budget Buddy để theo dõi tốt hơn',
        'Xem lại kế hoạch mỗi đầu tháng và điều chỉnh nếu cần',
      ],
      'goal_plan':
          'Duy trì tiết kiệm ${_fmt(saving)}đ/tháng đều đặn. '
          'Sau 3-6 tháng xây dựng quỹ dự phòng đủ 3 tháng chi tiêu, '
          'sau đó tăng dần tỷ lệ đầu tư để đạt mục tiêu dài hạn.',
    };
  }

  // ── Generate plan ─────────────────────────────────────
  Future<void> _generate(Map<String, dynamic> formData) async {
    setState(() => _isGenerating = true);

    Map<String, dynamic> plan;

    try {
      final prompt = _buildPrompt(formData);

      final res = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': prompt,
          'chatHistory': [],
          'financialContext': '',
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body    = jsonDecode(res.body);
        final rawText = body['message'] as String? ?? '';
        final cleaned = rawText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        plan = jsonDecode(cleaned) as Map<String, dynamic>;
        print('✅ Plan generated (${body['provider']})');
      } else {
        print('⚠️ Backend error ${res.statusCode}, using fallback');
        plan = _fallbackPlan(formData);
      }
    } catch (e) {
      print('⚠️ Backend unreachable: $e — using fallback');
      plan = _fallbackPlan(formData);
    }

    if (mounted) {
      setState(() => _isGenerating = false);
      _onPlanCreated(plan, formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_savedPlan == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: PlanEntryView(
            onPlanCreated: _onPlanCreated,
            isGenerating: _isGenerating,
            onGenerate: _generate,
          ),
        ),
        bottomNavigationBar: _SharedBottomNavBar(
          activeIndex: 1,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    } else {
      return _PlanResultScreen(
        plan:     _savedPlan!,
        formData: _savedFormData!,
        onReset:  _resetPlan,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────
// RESULT SCREEN
// ─────────────────────────────────────────────────────────
class _PlanResultScreen extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> formData;
  final VoidCallback onReset;

  const _PlanResultScreen({
    required this.plan,
    required this.formData,
    required this.onReset,
  });

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  String _fmt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _summaryCard(isDark),
                const SizedBox(height: 16),
                _incomeCard(isDark),
                const SizedBox(height: 16),
                _expenseTable(isDark),
                const SizedBox(height: 16),
                _tipsCard(isDark),
                const SizedBox(height: 16),
                _goalCard(isDark),
                const SizedBox(height: 16),
                _spendRuleBtn(context),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _SharedBottomNavBar(activeIndex: 1, isDark: isDark),
    );
  }

  Widget _buildHeader(BuildContext ctx, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kế hoạch của bạn',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Được tạo tự động',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ])),
        GestureDetector(
          onTap: onReset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, size: 15,
                  color: isDark ? Colors.grey[300] : Colors.grey[700]),
              const SizedBox(width: 4),
              Text('Tạo lại', style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _summaryCard(bool isDark) {
    final summary = plan['summary'] as String? ?? '';
    if (summary.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00CED1), Color(0xFF48D1CC)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Nhận xét', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Text(summary, style: const TextStyle(
            color: Colors.white, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _incomeCard(bool isDark) {
    final rec    = (plan['recommended_income'] as num?)?.toDouble() ?? 0;
    final reason = plan['income_reason'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.trending_up, color: _teal, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Mức thu nhập phù hợp',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Text('${_fmt(rec)} đ / tháng',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _teal)),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(reason, style: TextStyle(
              fontSize: 13, color: Colors.grey[500], height: 1.4)),
        ],
      ]),
    );
  }

  Widget _expenseTable(bool isDark) {
    final rows = (plan['expense_table'] as List?) ?? [];
    final rowColors = [
      const Color(0xFF00CED1), const Color(0xFF4CAF50), const Color(0xFFFF9800),
      const Color(0xFF2196F3), const Color(0xFFE91E63), const Color(0xFF9C27B0),
      const Color(0xFFFF5722), const Color(0xFF009688), const Color(0xFFFFC107),
      const Color(0xFF607D8B), const Color(0xFFE53935), const Color(0xFF8BC34A),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.table_chart_rounded,
                  color: _purple, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Kế hoạch chi tiêu chi tiết',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(children: [
            Expanded(flex: 5, child: Text('DANH MỤC', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.grey, letterSpacing: 0.5))),
            Expanded(flex: 4, child: Text('SỐ TIỀN', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.grey, letterSpacing: 0.5),
                textAlign: TextAlign.right)),
            SizedBox(width: 8),
            SizedBox(width: 38, child: Text('%', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.grey, letterSpacing: 0.5),
                textAlign: TextAlign.center)),
          ]),
        ),
        ...rows.asMap().entries.map((e) {
          final i       = e.key;
          final row     = e.value as Map;
          final amount  = (row['amount']  as num?)?.toDouble() ?? 0;
          final percent = (row['percent'] as num?)?.toInt()    ?? 0;
          final color   = rowColors[i % rowColors.length];
          final isLast  = i == rows.length - 1;

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(flex: 5, child: Text(row['category'] ?? '',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))),
                  Expanded(flex: 4, child: Text('${_fmt(amount)} đ',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: color),
                      textAlign: TextAlign.right)),
                  const SizedBox(width: 8),
                  Container(
                    width: 38, height: 22,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text('$percent%',
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700, color: color))),
                  ),
                ]),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        backgroundColor:
                            isDark ? Colors.grey[700] : Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                    if ((row['note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(row['note'].toString(),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ]),
                ),
              ]),
            ),
            if (!isLast)
              Divider(height: 1, thickness: 0.5,
                  color: isDark ? Colors.grey[700] : Colors.grey[100]),
          ]);
        }).toList(),
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _teal.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.calculate_rounded, color: _teal, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Tổng thu nhập / tháng',
                style: TextStyle(fontWeight: FontWeight.w600,
                    color: _teal, fontSize: 13))),
            Text(
                '${_fmt((plan['recommended_income'] as num?)?.toDouble() ?? 0)} đ',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: _teal, fontSize: 15)),
          ]),
        ),
      ]),
    );
  }

  Widget _tipsCard(bool isDark) {
    final tips = (plan['tips'] as List?) ?? [];
    if (tips.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.lightbulb_outline_rounded, color: _purple, size: 18),
          SizedBox(width: 8),
          Text('Lời khuyên', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _purple)),
        ]),
        const SizedBox(height: 10),
        ...tips.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                  color: _purple, shape: BoxShape.circle),
              child: Center(child: Text('${e.key + 1}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value.toString(),
                style: TextStyle(fontSize: 13, height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          ]),
        )).toList(),
      ]),
    );
  }

  Widget _goalCard(bool isDark) {
    final goalPlan = plan['goal_plan'] as String? ?? '';
    if (goalPlan.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.flag_outlined, color: Color(0xFF00CED1), size: 18),
          SizedBox(width: 8),
          Text('Lộ trình thực hiện',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(goalPlan, style: TextStyle(
            fontSize: 13, color: Colors.grey[600], height: 1.5)),
      ]),
    );
  }

  Widget _spendRuleBtn(BuildContext ctx) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const SpendingRuleView())),
        icon: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18),
        label: const Text('Xem quy tắc 50/30/20',
            style: TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal, elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SHARED BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────
class _SharedBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final bool isDark;
  const _SharedBottomNavBar(
      {required this.activeIndex, required this.isDark});
  static const _teal = Color(0xFF00CED1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _item(context, Icons.home_rounded, 'Home', 0,
                () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomeView()))),
            _item(context, Icons.assignment_rounded, 'Plan', 1, () {}),
            _voiceItem(context),
            _item(context, Icons.layers_rounded, 'Category', 3,
                () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const CategoriesView()))),
            _item(context, Icons.person_outline_rounded, 'Profile', 4,
                () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ProfileView()))),
          ]),
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label,
      int index, VoidCallback onTap) {
    final active = index == activeIndex;
    final color =
        active ? _teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active ? _teal.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        Text(label, style: TextStyle(fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: color)),
      ]),
    );
  }

  Widget _voiceItem(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(ctx, '/test-voice'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _teal.withOpacity(0.4),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        const Text('Voice', style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w600, color: _teal)),
      ]),
    );
  }
}