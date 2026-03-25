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
import './analysis_widgets.dart';
import './Spend_rule_view.dart';
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

  void _onPlanCreated(
      Map<String, dynamic> plan, Map<String, dynamic> formData) {
    setState(() { _savedPlan = plan; _savedFormData = formData; });
    _savePlanToFirestore(plan, formData);
  }

  Future<void> _savePlanToFirestore(
      Map<String, dynamic> plan, Map<String, dynamic> formData) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('plans').doc('current_plan')
          .set({
        'plan': plan, 'formData': formData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Plan saved to Firestore');
    } catch (e) { print('⚠️ Error saving plan: $e'); }
  }

  void _resetPlan() =>
      setState(() { _savedPlan = null; _savedFormData = null; });

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // ══════════════════════════════════════════════════════
  // PROMPT — Gửi cho AI qua Render backend
  // ══════════════════════════════════════════════════════
  String _buildPrompt(Map<String, dynamic> d) {
    final cityLabel = PlanFormData.cityName(d['city'] ?? 'HCM');
    final occLabel  = PlanFormData.occupationLabel(
        d['occupation'] ?? 'Employee', d['customOccupation'] ?? '');

    final livMap = {
      'WithFamily': 'Ở cùng gia đình (KHÔNG tốn tiền thuê nhà)',
      'Renting':    'Thuê nhà/phòng trọ (CÓ chi phí thuê)',
      'OwnHouse':   'Có nhà riêng (KHÔNG tốn tiền thuê)',
      'Dormitory':  'Ký túc xá (~500k-1tr/tháng)',
      'Boarding':   'Nhà trọ sinh viên (~1-2tr/tháng)',
      'NoHouse':    'Chưa có nhà cố định (đang thuê)',
    };
    final goalMap = {
      'Emergency': 'Quỹ dự phòng', 'BuyHouse': 'Mua nhà',
      'BuyCar': 'Mua xe', 'Travel': 'Du lịch', 'Invest': 'Đầu tư',
      'Retire': 'Hưu trí sớm', 'Education': 'Học tập / Du học',
      'Wedding': 'Đám cưới', 'Business': 'Khởi nghiệp', 'Health': 'Quỹ y tế',
    };

    final goals = (d['savingGoals'] as List? ?? [d['savingGoal'] ?? 'Emergency'])
        .map((g) => goalMap[g] ?? g.toString()).join(', ');

    final hasDebt     = d['hasDebt']     as bool?   ?? false;
    final hasSavings  = d['hasSavings']  as bool?   ?? false;
    final married     = d['maritalStatus'] == 'Married';
    final hasChildren = d['hasChildren'] as String? ?? 'Chưa có con';
    final living      = d['livingStatus'] as String? ?? 'Renting';
    final transport   = d['transport']   as String? ?? 'Xe máy';
    final eating      = d['eatingHabit'] as String? ?? '50/50';
    final stability   = d['incomeStability'] as String? ?? 'Stable';
    final sources     = (d['incomeSources'] as List? ?? []).join(', ');
    final ageRange    = d['ageRange']    as String? ?? '22-30';
    final occupation  = d['occupation'] as String? ?? 'Employee';

    final currentSalary = (d['currentSalary'] as num?)?.toDouble() ?? 0;
    final targetSalary  = (d['targetSalary']  as num?)?.toDouble() ?? 0;

    final currentText = currentSalary > 0
        ? '${_fmt(currentSalary)}đ/tháng ← USER ĐÃ NHẬP, BẮT BUỘC DÙNG SỐ NÀY'
        : 'Chưa nhập → ước tính theo bảng tham khảo';
    final targetText = targetSalary > 0
        ? '${_fmt(targetSalary)}đ/tháng' : 'Chưa cung cấp';

    final ctx = StringBuffer();
    if (living == 'OwnHouse')
      ctx.write('• Có nhà riêng → KHÔNG có khoản "Nhà ở" trong expense_table.\n');
    if (living == 'WithFamily')
      ctx.write('• Ở cùng gia đình → KHÔNG có khoản "Nhà ở" trong expense_table.\n');
    if (married)
      ctx.write('• Đã kết hôn → chi phí cao hơn, PHẢI có khoản "Chi phí gia đình".\n');
    if (hasChildren != 'Chưa có con')
      ctx.write('• Có con → PHẢI có khoản "Chi phí con cái" 3-6tr.\n');
    if (transport == 'Ô tô' || transport == 'car')
      ctx.write('• Đi ô tô → di chuyển 3-6tr/tháng.\n');
    if (hasDebt)
      ctx.write('• Có nợ → PHẢI có khoản "Trả nợ hàng tháng".\n');

    final needsRent = living == 'Renting' || living == 'Boarding'
        || living == 'NoHouse' || living == 'Dormitory';

    return '''Bạn là chuyên gia tư vấn tài chính cá nhân Việt Nam 2024-2025.
Lập kế hoạch tài chính THỰC TẾ và CHÍNH XÁC.

════════════════════════════════════
THÔNG TIN NGƯỜI DÙNG
════════════════════════════════════
Nghề nghiệp      : $occLabel
Độ tuổi          : $ageRange
Hôn nhân         : ${married ? 'Đã kết hôn' : 'Độc thân'}
Thành phố        : $cityLabel
Chỗ ở            : ${livMap[living] ?? living}
Thu nhập ổn định : $stability
Nguồn thu        : ${sources.isEmpty ? 'Chưa rõ' : sources}
THU NHẬP HIỆN TẠI: $currentText
Thu nhập mong muốn: $targetText
Có con           : $hasChildren
Phương tiện      : $transport
Thói quen ăn     : $eating
Chi tiêu thực tế : ${d['currentSpending'] ?? 'Chưa rõ'}
Bảo hiểm y tế   : ${d['insurance'] ?? 'Chưa có'}
Có nợ            : ${hasDebt ? 'Có (${_fmt(d['debtAmount'])}đ)' : 'Không'}
Có tiết kiệm     : ${hasSavings ? 'Có' : 'Chưa'}
Mục tiêu         : $goals

════════════════════════════════════
LƯU Ý ĐẶC BIỆT
════════════════════════════════════
${ctx.toString().isEmpty ? '• Không có điều chỉnh đặc biệt.' : ctx.toString()}

════════════════════════════════════
BẢNG LƯƠNG THAM KHẢO 2024-2025
════════════════════════════════════
Sinh viên/thực tập : HCM 2-5tr | Tỉnh 1-3tr
Nhân viên mới      : HCM/HN 9-15tr | Tỉnh 7-11tr
Nhân viên KN 3-7năm: HCM/HN 15-25tr | Tỉnh 10-18tr
Kỹ sư IT           : HCM/HN 18-40tr | Đà Nẵng 15-30tr | Tỉnh 12-20tr
Freelancer         : HCM/HN 12-35tr
Bác sĩ mới         : 8-15tr | Có KN: 20-50tr | Tư nhân: 30-80tr
Giáo viên trường công: 8-14tr | Trường tư: 12-22tr | Quốc tế: 20-40tr
  → Dạy thêm: +3-10tr | HCM cao hơn tỉnh 20-30%
  → GV HCM đã kết hôn: KHÔNG THỂ dưới 12tr, thực tế 15-20tr
Kinh doanh         : 12-60tr+ tùy quy mô

════════════════════════════════════
CHI PHÍ THỰC TẾ 2024-2025
════════════════════════════════════
Thuê nhà: HCM trọ 2-3.5tr | HN trọ 2-3tr | Tỉnh 1-2.5tr
Ăn uống 1 người: nấu 2-3.5tr | 50/50: 3-5tr | ngoài: 4-7tr
  → Gia đình 2 người: ×1.7 | Có con: ×2.0-2.4
Di chuyển: xe máy 500k-1.2tr | ô tô 3-6tr | grab 1.5-3tr

════════════════════════════════════
QUY TẮC TUYỆT ĐỐI
════════════════════════════════════
1. User đã nhập thu nhập → BẮT BUỘC dùng đúng số đó làm recommended_income.
2. Chưa nhập → ước tính thực tế theo nghề + thành phố + tuổi + hoàn cảnh.
3. OwnHouse/WithFamily → KHÔNG có dòng "Nhà ở".
4. Renting/Boarding/NoHouse/Dormitory → BẮT BUỘC có dòng "Nhà ở".
5. Tổng amount trong expense_table PHẢI = recommended_income (±1%).
6. KHÔNG dùng từ "AI" ở bất kỳ đâu.

════════════════════════════════════
OUTPUT — JSON THUẦN (KHÔNG markdown, KHÔNG backtick)
════════════════════════════════════
{
  "recommended_income": <số nguyên VND>,
  "income_reason": "<1 câu cụ thể>",
  "summary": "<2 câu nhận xét>",
  "expense_table": [
    ${needsRent ? '{"category": "Nhà ở", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},' : ''}
    {"category": "Ăn uống", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Di chuyển", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Hóa đơn tiện ích", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Điện, nước, internet"},
    {"category": "Mua sắm cá nhân", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Giải trí & xã hội", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Tiết kiệm", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Chuyển ngay đầu tháng"},
    {"category": "Đầu tư & học tập", "amount": <số nguyên>, "percent": <số nguyên>, "note": "<ghi chú>"},
    {"category": "Quỹ dự phòng", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Tình huống bất ngờ"}
    ${hasDebt ? ',{"category": "Trả nợ hàng tháng", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Thanh toán đều đặn"}' : ''}
    ${married ? ',{"category": "Chi phí gia đình", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Chi phí gia đình"}' : ''}
    ${hasChildren != 'Chưa có con' ? ',{"category": "Chi phí con cái", "amount": <số nguyên>, "percent": <số nguyên>, "note": "Học phí, sữa, y tế"}' : ''}
  ],
  "tips": ["<tip 1>", "<tip 2>", "<tip 3>"],
  "goal_plan": "<lộ trình 2-3 câu đạt mục tiêu $goals>"
}''';
  }

  // ══════════════════════════════════════════════════════
  // FALLBACK — Dùng % để tổng luôn = 100%
  // ══════════════════════════════════════════════════════
  Map<String, dynamic> _fallbackPlan(Map<String, dynamic> d) {
    final city        = d['city']          as String? ?? 'HCM';
    final occupation  = d['occupation']    as String? ?? 'Employee';
    final living      = d['livingStatus']  as String? ?? 'Renting';
    final hasDebt     = d['hasDebt']       as bool?   ?? false;
    final married     = d['maritalStatus'] == 'Married';
    final hasChildren = d['hasChildren']   as String? ?? 'Chưa có con';
    final transport   = d['transport']     as String? ?? 'motorbike';
    final eating      = d['eatingHabit']   as String? ?? 'mixed';
    final ageRange    = d['ageRange']      as String? ?? '22-30';

    // ── Thu nhập đề xuất ──────────────────────────────
    final inputSalary = (d['currentSalary'] as num?)?.toDouble() ?? 0;

    final baseSalary = <String, double>{
      'Student': 3500000, 'Employee': 12000000, 'Freelancer': 18000000,
      'Business': 22000000, 'Doctor': 20000000, 'Teacher': 13000000,
      'Engineer': 22000000, 'Other': 12000000,
    };
    final cityMult = <String, double>{
      'HCM': 1.00, 'Hanoi': 0.97, 'DaNang': 0.83, 'HaiPhong': 0.80,
      'BinhDuong': 0.87, 'CanTho': 0.76, 'BaRiaVT': 0.80,
      'DakLak': 0.72, 'LamDong': 0.72, 'DongNai': 0.82,
    };
    final ageMult = <String, double>{
      '<22': 0.72, '22-30': 1.00, '31-40': 1.38, '40+': 1.55,
    };

    double baseRec = (baseSalary[occupation] ?? 12000000)
        * (cityMult[city] ?? 0.78)
        * (ageMult[ageRange] ?? 1.0);

    if (married)                                   baseRec *= 1.28;
    if (hasChildren == 'Có 1 con')                 baseRec += 4000000;
    if (hasChildren == 'Có 2 con trở lên')         baseRec += 7500000;
    if (transport == 'car' || transport == 'Ô tô') baseRec += 3500000;

    final rec = (inputSalary > 0 ? inputSalary : baseRec).roundToDouble();

    // ── Phân bổ theo % (tổng = 100%) ─────────────────
    final bool needsRent = living == 'Renting' || living == 'Boarding'
        || living == 'NoHouse' || living == 'Dormitory';
    final bool hasKids = hasChildren != 'Chưa có con';

    // % nhà ở
    double rentPct = 0;
    if (needsRent) {
      if      (living == 'Dormitory') rentPct = 8;
      else if (living == 'Boarding')  rentPct = 18;
      else if (city == 'HCM')         rentPct = 25;
      else if (city == 'Hanoi')       rentPct = 22;
      else                            rentPct = 18;
    }

    // % ăn uống
    double foodPct = 23;
    if (eating == 'cook'   || eating == 'Hay nấu nhà')  foodPct = 20;
    if (eating == 'eatout' || eating == 'Hay ăn ngoài') foodPct = 28;
    if (married) foodPct += 7;
    if (hasKids)  foodPct += 5;

    // % di chuyển
    double transPct = 5;
    if      (transport == 'car'  || transport == 'Ô tô')       transPct = 12;
    else if (transport == 'grab' || transport == 'Grab/buýt')  transPct = 8;
    else if (transport == 'walk' || transport == 'Đi bộ')      transPct = 1;

    // % các khoản cố định
    const billsPct  = 5.0;
    const shopPct   = 5.0;
    const entPct    = 4.0;
    const emergPct  = 5.0;
    final familyPct = married ? 5.0 : 0.0;
    final childPct  = hasKids  ? 8.0 : 0.0;
    final debtPct   = hasDebt  ? 10.0 : 0.0;
    final investPct = occupation == 'Student' ? 3.0 : 7.0;

    // % tiết kiệm = phần còn lại (min 5%)
    final usedPct = rentPct + foodPct + transPct + billsPct + shopPct
        + entPct + emergPct + familyPct + childPct + debtPct + investPct;
    final savingPct = (100.0 - usedPct).clamp(5.0, 40.0);

    // ── Tính số tiền từ % ──────────────────────────────
    int pct(double p) => (rec * p / 100).round();

    final rentAmt   = pct(rentPct);
    final foodAmt   = pct(foodPct);
    final transAmt  = pct(transPct);
    final billsAmt  = pct(billsPct);
    final shopAmt   = pct(shopPct);
    final entAmt    = pct(entPct);
    final emergAmt  = pct(emergPct);
    final familyAmt = pct(familyPct);
    final childAmt  = pct(childPct);
    final debtAmt   = pct(debtPct);
    final investAmt = pct(investPct);
    int   savingAmt = pct(savingPct);

    // Bù chênh lệch làm tròn vào tiết kiệm
    final subtotal = rentAmt + foodAmt + transAmt + billsAmt + shopAmt
        + entAmt + emergAmt + familyAmt + childAmt + debtAmt
        + investAmt + savingAmt;
    savingAmt += rec.toInt() - subtotal;

    // ── Build table ────────────────────────────────────
    final cityName = PlanFormData.cityName(city);
    final occLabel = PlanFormData.occupationLabel(
        occupation, d['customOccupation'] ?? '');

    String transNote = 'Xăng xe máy + bảo dưỡng';
    if      (transport == 'car'  || transport == 'Ô tô')       transNote = 'Xăng + bảo dưỡng + bãi đỗ ô tô';
    else if (transport == 'grab' || transport == 'Grab/buýt')  transNote = 'Grab / xe buýt hàng ngày';
    else if (transport == 'walk' || transport == 'Đi bộ')      transNote = 'Đi bộ / xe đạp';

    String eatNote = '50% nấu nhà, 50% ăn ngoài';
    if      (eating == 'cook'   || eating == 'Hay nấu nhà')  eatNote = 'Chủ yếu nấu tại nhà';
    else if (eating == 'eatout' || eating == 'Hay ăn ngoài') eatNote = 'Hay ăn ngoài — cần kiểm soát';
    if (married) eatNote += ' (cả gia đình)';

    final table = <Map<String, dynamic>>[
      if (rentAmt > 0)
        {'category': 'Nhà ở', 'amount': rentAmt, 'percent': rentPct.round(),
          'note': living == 'Dormitory' ? 'Ký túc xá / lưu xá'
              : living == 'Boarding'    ? 'Nhà trọ sinh viên'
              : 'Thuê nhà tại $cityName'},
      {'category': 'Ăn uống',           'amount': foodAmt,   'percent': foodPct.round(),   'note': eatNote},
      {'category': 'Di chuyển',         'amount': transAmt,  'percent': transPct.round(),  'note': transNote},
      {'category': 'Hóa đơn tiện ích',  'amount': billsAmt,  'percent': billsPct.round(),  'note': 'Điện, nước, internet'},
      {'category': 'Mua sắm cá nhân',   'amount': shopAmt,   'percent': shopPct.round(),   'note': 'Quần áo, đồ dùng'},
      {'category': 'Giải trí & xã hội', 'amount': entAmt,    'percent': entPct.round(),    'note': 'Cà phê, phim, bạn bè'},
      {'category': 'Tiết kiệm',         'amount': savingAmt, 'percent': savingPct.round(), 'note': 'Chuyển ngay khi nhận lương'},
      {'category': 'Đầu tư & học tập',  'amount': investAmt, 'percent': investPct.round(), 'note': 'Khóa học, sách, quỹ đầu tư'},
      {'category': 'Quỹ dự phòng',      'amount': emergAmt,  'percent': emergPct.round(),  'note': 'Tình huống khẩn cấp'},
      if (hasDebt)
        {'category': 'Trả nợ hàng tháng', 'amount': debtAmt,   'percent': debtPct.round(),   'note': 'Thanh toán đều đặn'},
      if (married)
        {'category': 'Chi phí gia đình',  'amount': familyAmt, 'percent': familyPct.round(), 'note': 'Chi phí sinh hoạt chung'},
      if (hasKids)
        {'category': 'Chi phí con cái',   'amount': childAmt,  'percent': childPct.round(),  'note': 'Học phí, sữa, y tế trẻ em'},
    ];

    final incomeReason = inputSalary > 0
        ? 'Thu nhập bạn cung cấp, dùng làm cơ sở lập kế hoạch.'
        : 'Ước tính phù hợp $occLabel tại $cityName'
            '${married ? ", đã kết hôn" : ""}${living == 'OwnHouse' ? ", có nhà riêng" : ""}'
            ' (thị trường 2024-2025).';

    final savingTip = occupation == 'Student'
        ? 'Sinh viên nên tìm việc làm thêm phù hợp ngành học để tích lũy kinh nghiệm và thu nhập.'
        : occupation == 'Teacher'
            ? 'Giáo viên có thể tăng thu nhập từ dạy thêm, gia sư online 2-3 buổi/tuần.'
            : 'Tìm cơ hội tăng thu nhập qua công việc phụ hoặc đầu tư nhỏ.';

    return {
      'recommended_income': rec.toInt(),
      'income_reason': incomeReason,
      'summary':
          'Với hoàn cảnh ${occupation == 'Student' ? 'sinh viên' : married ? 'đã kết hôn' : 'độc thân'} '
          'tại $cityName, kế hoạch cân bằng chi tiêu thiết yếu và tích lũy dài hạn. '
          '${savingPct >= 15 ? "Tỷ lệ tiết kiệm hợp lý — duy trì đều đặn." : "Cố gắng cắt giảm để tăng tiết kiệm."}',
      'expense_table': table,
      'tips': [
        'Chuyển ${_fmt(savingAmt)}đ vào tài khoản tiết kiệm ngay ngày nhận lương.',
        savingTip,
        married
            ? 'Lên ngân sách gia đình cùng vợ/chồng mỗi đầu tháng.'
            : 'Ghi chép chi tiêu hàng ngày bằng Budget Buddy để kiểm soát kịp thời.',
      ],
      'goal_plan':
          'Tiết kiệm đều ${_fmt(savingAmt)}đ/tháng. '
          'Sau 3-6 tháng xây quỹ dự phòng ≈ ${_fmt(rec * 3)}đ. '
          'Sau đó tăng dần đầu tư để đạt mục tiêu dài hạn.',
    };
  }

  // ══════════════════════════════════════════════════════
  // GENERATE — Gọi AI qua Render backend
  // ══════════════════════════════════════════════════════
  Future<void> _generate(Map<String, dynamic> formData) async {
    setState(() => _isGenerating = true);
    Map<String, dynamic> plan;

    try {
      final res = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message':          _buildPrompt(formData),
          'chatHistory':      [],
          'financialContext': '',
        }),
      ).timeout(const Duration(seconds: 40));

      if (res.statusCode == 200) {
        final body    = jsonDecode(res.body);
        final rawText = body['message'] as String? ?? '';
        final cleaned = rawText
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        final start = cleaned.indexOf('{');
        final end   = cleaned.lastIndexOf('}');
        if (start >= 0 && end > start) {
          plan = jsonDecode(cleaned.substring(start, end + 1))
              as Map<String, dynamic>;
          print('✅ Plan from AI (${body['provider'] ?? 'unknown'})');
        } else {
          throw Exception('No JSON in response');
        }
      } else {
        print('⚠️ Backend ${res.statusCode} → fallback');
        plan = _fallbackPlan(formData);
      }
    } catch (e) {
      print('! Error: $e → fallback');
      plan = _fallbackPlan(formData);
    }

    if (mounted) {
      setState(() => _isGenerating = false);
      _onPlanCreated(plan, formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_savedPlan == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: PlanEntryView(
            onPlanCreated: _onPlanCreated,
            isGenerating:  _isGenerating,
            onGenerate:    _generate,
          ),
        ),
        bottomNavigationBar:
            _SharedBottomNavBar(activeIndex: 1, isDark: isDark),
      );
    }
    return _PlanResultScreen(
        plan: _savedPlan!, formData: _savedFormData!, onReset: _resetPlan);
  }
}

// ══════════════════════════════════════════════════════════
// RESULT SCREEN
// ══════════════════════════════════════════════════════════
class _PlanResultScreen extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> formData;
  final VoidCallback onReset;
  const _PlanResultScreen(
      {required this.plan, required this.formData, required this.onReset});

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
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
          _header(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar:
          _SharedBottomNavBar(activeIndex: 1, isDark: isDark),
    );
  }

  Widget _header(BuildContext ctx, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    final s = plan['summary'] as String? ?? '';
    if (s.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00CED1), Color(0xFF48D1CC)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Nhận xét', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Text(s, style: const TextStyle(
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
    const rowColors = [
      Color(0xFF00CED1), Color(0xFF4CAF50), Color(0xFFFF9800),
      Color(0xFF2196F3), Color(0xFFE91E63), Color(0xFF9C27B0),
      Color(0xFFFF5722), Color(0xFF009688), Color(0xFFFFC107),
      Color(0xFF607D8B), Color(0xFFE53935), Color(0xFF8BC34A),
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
                fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey,
                letterSpacing: 0.5))),
            Expanded(flex: 4, child: Text('SỐ TIỀN', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey,
                letterSpacing: 0.5), textAlign: TextAlign.right)),
            SizedBox(width: 8),
            SizedBox(width: 38, child: Text('%', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey,
                letterSpacing: 0.5), textAlign: TextAlign.center)),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
            Text('${_fmt((plan['recommended_income'] as num?)?.toDouble() ?? 0)} đ',
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
        const Row(children: [
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
              decoration: const BoxDecoration(
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
    final g = plan['goal_plan'] as String? ?? '';
    if (g.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.flag_outlined, color: _teal, size: 18),
          SizedBox(width: 8),
          Text('Lộ trình thực hiện',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(g, style: TextStyle(
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

// ══════════════════════════════════════════════════════════
// SHARED BOTTOM NAV BAR
// ══════════════════════════════════════════════════════════
class _SharedBottomNavBar extends StatelessWidget {
  final int  activeIndex;
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
    final color  = active
        ? _teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
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