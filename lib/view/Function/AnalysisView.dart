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
import './Plan_form_data.dart';

// ─────────────────────────────────────────────────────────
// MAIN VIEW — router giữa Form và Result
// ─────────────────────────────────────────────────────────
class AnalysisView extends StatefulWidget {
  const AnalysisView({Key? key}) : super(key: key);

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  Map<String, dynamic>? _savedPlan;
  Map<String, dynamic>? _savedFormData;
  bool _isGenerating = false;

  void _onPlanCreated(Map<String, dynamic> plan, Map<String, dynamic> formData) {
    setState(() {
      _savedPlan     = plan;
      _savedFormData = formData;
    });
  }

  void _resetPlan() {
    setState(() {
      _savedPlan     = null;
      _savedFormData = null;
    });
  }

  // ── Generate plan (gọi backend hoặc mock) ──────────────
  Future<void> _generate(Map<String, dynamic> formData) async {
    setState(() => _isGenerating = true);

    Map<String, dynamic> plan;
    try {
      const url = 'https://your-backend.onrender.com/api/financial-plan';
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': _buildPrompt(formData)}),
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        final text = (jsonDecode(res.body)['result'] as String? ?? '')
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        plan = jsonDecode(text) as Map<String, dynamic>;
      } else {
        plan = _mockPlan(formData);
      }
    } catch (_) {
      plan = _mockPlan(formData);
    }

    if (mounted) {
      setState(() => _isGenerating = false);
      _onPlanCreated(plan, formData);
    }
  }

  // ── Build AI prompt ────────────────────────────────────
  String _fmt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _buildPrompt(Map<String, dynamic> d) {
    // Occupation: hỗ trợ "Other" + custom text
    final occLabel = PlanFormData.occupationLabel(
        d['occupation'] ?? 'Employee',
        d['customOccupation'] ?? '');

    // City: lấy tên từ 64 tỉnh thành
    final cityLabel = PlanFormData.cityName(d['city'] ?? 'HCM');

    // Living
    final livMap = {
      'WithFamily': 'Ở cùng gia đình',
      'Renting':    'Thuê nhà/phòng trọ',
      'OwnHouse':   'Có nhà riêng',
      'Dormitory':  'Ký túc xá / Lưu xá',
      'Boarding':   'Nhà trọ sinh viên',
      'NoHouse':    'Chưa có nhà ở cố định',
    };

    // Goals: multi-select
    final goalMap = {
      'Emergency': 'Quỹ khẩn cấp',
      'BuyHouse':  'Mua nhà',
      'BuyCar':    'Mua xe',
      'Travel':    'Du lịch',
      'Invest':    'Đầu tư',
      'Retire':    'Hưu trí sớm',
      'Education': 'Học tập / Du học',
      'Wedding':   'Đám cưới',
      'Business':  'Khởi nghiệp',
      'Health':    'Quỹ y tế',
    };
    final goals = (d['savingGoals'] as List? ?? [d['savingGoal'] ?? 'Emergency'])
        .map((g) => goalMap[g] ?? g.toString())
        .join(', ');

    return '''Bạn là chuyên gia tài chính cá nhân tại Việt Nam. Tạo kế hoạch tài chính cho:
- Nghề nghiệp: $occLabel
- Độ tuổi: ${d['ageRange']}, Hôn nhân: ${d['maritalStatus']}
- Thành phố: $cityLabel
- Chỗ ở: ${livMap[d['livingStatus']] ?? d['livingStatus']}
- Thu nhập hiện tại: ${_fmt(d['currentSalary'])}đ/tháng
- Thu nhập mong muốn: ${_fmt(d['targetSalary'])}đ/tháng
- Nguồn thu: ${(d['incomeSources'] as List? ?? []).join(', ')}
- Độ ổn định: ${d['incomeStability']}
- Có tiết kiệm: ${d['hasSavings'] ? 'Có' : 'Chưa'}
- Có nợ: ${d['hasDebt'] ? 'Có (${_fmt(d['debtAmount'])}đ)' : 'Không'}
- Mục tiêu tài chính: $goals

Trả về JSON hợp lệ (KHÔNG có markdown, KHÔNG có backtick):
{
  "summary": "Nhận xét ngắn 2-3 câu về tình hình tài chính",
  "recommended_income": number,
  "income_advice": "Lý do và cách đạt mức thu nhập phù hợp",
  "expense_table": [
    {"category": "Nhà ở", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Ăn uống", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Di chuyển", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Hóa đơn tiện ích", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Mua sắm cá nhân", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Giải trí & xã hội", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Tiết kiệm bắt buộc", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Đầu tư / Học tập", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Quỹ khẩn cấp", "amount": number, "percent": number, "note": "ghi chú"},
    {"category": "Chi phí khác", "amount": number, "percent": number, "note": "ghi chú"}
  ],
  "tips": ["tip 1", "tip 2", "tip 3"],
  "goal_plan": "Lộ trình cụ thể 3-4 câu để đạt các mục tiêu: $goals"
}
Lưu ý: Tổng expense_table = recommended_income. Số tiền phù hợp mức sống tại $cityLabel.''';
  }

  // ── Mock plan (fallback) ───────────────────────────────
  Map<String, dynamic> _mockPlan(Map<String, dynamic> d) {
    final city     = d['city'] as String? ?? 'HCM';
    final cityName = PlanFormData.cityName(city);
    final sal      = (d['currentSalary'] as num?)?.toDouble() ?? 10000000;
    final rec      = sal < 8000000 ? 12000000.0 : sal;

    // Rent theo thành phố
    final rent = city == 'HCM'    ? 3500000.0
               : city == 'Hanoi'  ? 3000000.0
               : city == 'DaNang' ? 2500000.0
               : 2000000.0;

    final food  = (rec * 0.20).roundToDouble();
    final trans = (rec * 0.08).roundToDouble();
    final bills = (rec * 0.05).roundToDouble();
    final shop  = (rec * 0.07).roundToDouble();
    final ent   = (rec * 0.05).roundToDouble();
    final save  = (rec * 0.20).roundToDouble();
    final inv   = (rec * 0.10).roundToDouble();
    final emerg = (rec * 0.10).roundToDouble();
    final other = (rec - rent - food - trans - bills - shop - ent - save - inv - emerg)
        .clamp(0, double.infinity).toDouble();

    // Goals label
    final goalMap = {
      'Emergency': 'quỹ khẩn cấp', 'BuyHouse': 'mua nhà',
      'BuyCar': 'mua xe', 'Travel': 'du lịch', 'Invest': 'đầu tư',
      'Retire': 'hưu trí sớm', 'Education': 'học tập',
      'Wedding': 'đám cưới', 'Business': 'khởi nghiệp', 'Health': 'quỹ y tế',
    };
    final goals = (d['savingGoals'] as List? ?? [d['savingGoal'] ?? 'Emergency'])
        .map((g) => goalMap[g] ?? g.toString())
        .join(', ');

    final occLabel = PlanFormData.occupationLabel(
        d['occupation'] ?? 'Employee',
        d['customOccupation'] ?? '');

    return {
      'summary':
          'Dựa trên thu nhập và mức sống tại $cityName, kế hoạch dưới đây '
          'giúp bạn cân bằng chi tiêu và đạt các mục tiêu: $goals.',
      'recommended_income': rec,
      'income_advice':
          'Với nghề $occLabel tại $cityName, mức ${_fmt(rec)}đ/tháng là phù hợp. '
          'Bạn có thể tăng thu nhập qua freelance hoặc nâng cao kỹ năng chuyên môn.',
      'expense_table': [
        {'category': 'Nhà ở',              'amount': rent,  'percent': (rent  / rec * 100).round(), 'note': 'Ưu tiên gần nơi làm việc'},
        {'category': 'Ăn uống',            'amount': food,  'percent': (food  / rec * 100).round(), 'note': 'Nấu ăn tại nhà tiết kiệm hơn'},
        {'category': 'Di chuyển',          'amount': trans, 'percent': (trans / rec * 100).round(), 'note': 'Xăng xe + Grab'},
        {'category': 'Hóa đơn tiện ích',   'amount': bills, 'percent': (bills / rec * 100).round(), 'note': 'Điện, nước, internet'},
        {'category': 'Mua sắm cá nhân',    'amount': shop,  'percent': (shop  / rec * 100).round(), 'note': 'Quần áo, đồ dùng'},
        {'category': 'Giải trí & xã hội',  'amount': ent,   'percent': (ent   / rec * 100).round(), 'note': 'Cà phê, phim, bạn bè'},
        {'category': 'Tiết kiệm bắt buộc', 'amount': save,  'percent': (save  / rec * 100).round(), 'note': 'Chuyển khoản ngay đầu tháng'},
        {'category': 'Đầu tư / Học tập',   'amount': inv,   'percent': (inv   / rec * 100).round(), 'note': 'Khóa học, cổ phiếu'},
        {'category': 'Quỹ khẩn cấp',       'amount': emerg, 'percent': (emerg / rec * 100).round(), 'note': 'Đủ 3-6 tháng chi tiêu'},
        {'category': 'Chi phí khác',        'amount': other, 'percent': (other / rec * 100).round(), 'note': 'Y tế, quà tặng, phát sinh'},
      ],
      'tips': [
        'Áp dụng quy tắc 50/30/20: 50% thiết yếu, 30% cá nhân, 20% tiết kiệm',
        'Chuyển tiền tiết kiệm ngay khi nhận lương, không chờ cuối tháng',
        'Theo dõi chi tiêu hàng ngày trên Budget Buddy để kiểm soát tốt hơn',
      ],
      'goal_plan':
          'Để đạt mục tiêu $goals, hãy tiết kiệm ${_fmt(save)}đ/tháng. '
          'Sau 3-6 tháng xây dựng quỹ khẩn cấp, sau đó tăng dần tỷ lệ đầu tư '
          'lên 15-20% thu nhập mỗi tháng.',
    };
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_savedPlan == null) {
      // Chưa có plan → hiện form
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: PlanFormScreen(
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
      // Đã có plan → hiện kết quả
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
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kế hoạch của bạn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Được tạo tự động',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
        ),
        // Nút tạo lại nhỏ góc phải
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
              Text('Tạo lại',
                  style: TextStyle(fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _summaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00CED1), Color(0xFF48D1CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Text('🤖', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Nhận xét',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Text(plan['summary'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _incomeCard(bool isDark) {
    final rec = (plan['recommended_income'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
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
          const Text('Thu nhập đề xuất',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Text('${_fmt(rec)} đ / tháng',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _teal)),
        const SizedBox(height: 8),
        Text(plan['income_advice'] ?? '',
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
      ]),
    );
  }

  Widget _expenseTable(bool isDark) {
    final rows = (plan['expense_table'] as List?) ?? [];
    final rec  = (plan['recommended_income'] as num?)?.toDouble() ?? 0;
    final rowColors = [
      const Color(0xFF00CED1), const Color(0xFF4CAF50), const Color(0xFFFF9800),
      const Color(0xFF2196F3), const Color(0xFFE91E63), const Color(0xFF9C27B0),
      const Color(0xFFFF5722), const Color(0xFF009688), const Color(0xFFFFC107),
      const Color(0xFF607D8B),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(children: [
        // Table title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.table_chart_rounded, color: _purple, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Kế hoạch chi tiêu chi tiết',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Column headers
        Container(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Expanded(flex: 5,
              child: Text('DANH MỤC', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.grey, letterSpacing: 0.5))),
            const Expanded(flex: 4,
              child: Text('SỐ TIỀN', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.grey, letterSpacing: 0.5),
                  textAlign: TextAlign.right)),
            const SizedBox(width: 8),
            SizedBox(width: 38,
              child: Text('%', style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.grey, letterSpacing: 0.5),
                  textAlign: TextAlign.center)),
          ]),
        ),

        // Rows
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(flex: 5,
                    child: Text(row['category'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Expanded(flex: 4,
                    child: Text('${_fmt(amount)} đ',
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                    if ((row['note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(row['note'].toString(),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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

        // Total footer
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
            const Expanded(
              child: Text('Tổng thu nhập / tháng',
                  style: TextStyle(fontWeight: FontWeight.w600,
                      color: _teal, fontSize: 13)),
            ),
            Text('${_fmt(rec)} đ',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: _teal, fontSize: 15)),
          ]),
        ),
      ]),
    );
  }

  Widget _tipsCard(bool isDark) {
    final tips = (plan['tips'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Text('💡', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('Lời khuyên',
              style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: _purple)),
        ]),
        const SizedBox(height: 10),
        ...tips.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: _purple, shape: BoxShape.circle),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Text('🎯', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('Lộ trình đạt mục tiêu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(plan['goal_plan'] ?? '',
            style: TextStyle(fontSize: 13,
                color: Colors.grey[600], height: 1.5)),
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
  const _SharedBottomNavBar({required this.activeIndex, required this.isDark});

  static const _teal = Color(0xFF00CED1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _item(context, Icons.home_rounded, 'Home', 0,
                () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomeView()))),
            _item(context, Icons.assignment_rounded, 'Plan', 1, () {}),
            _voiceItem(context),
            _item(context, Icons.layers_rounded, 'Category', 3,
                () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const CategoriesView()))),
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
    final color  = active ? _teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
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
        Text(label, style: TextStyle(
            fontSize: 10,
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
            boxShadow: [BoxShadow(
                color: _teal.withOpacity(0.4),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        const Text('Voice', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
      ]),
    );
  }
}