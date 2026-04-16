// lib/view/Function/AnalysisView.dart

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
import './Plan_edit_view.dart';
import './SpecialFutureView.dart';
import './BudgetingPlanView.dart';

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
          .set({'plan': plan, 'formData': formData,
                'createdAt': FieldValue.serverTimestamp()});
    } catch (e) { debugPrint('Error saving plan: $e'); }
  }

  void _resetPlan() =>
      setState(() { _savedPlan = null; _savedFormData = null; });

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _buildPrompt(Map<String, dynamic> d) {
    final cityLabel = PlanFormData.cityName(d['city'] ?? 'HCM');
    final occLabel  = PlanFormData.occupationLabel(
        d['occupation'] ?? 'Employee', d['customOccupation'] ?? '');
    final livMap = {
      'WithFamily': 'Ở cùng gia đình (KHÔNG tốn tiền thuê nhà)',
      'Renting':    'Thuê nhà/phòng trọ',
      'OwnHouse':   'Có nhà riêng (KHÔNG tốn tiền thuê)',
      'Dormitory':  'Ký túc xá (~500k-1tr/tháng)',
      'Boarding':   'Nhà trọ sinh viên (~1-2tr/tháng)',
      'NoHouse':    'Chưa có nhà cố định',
    };
    final goalMap = {
      'Emergency':'Quỹ dự phòng','BuyHouse':'Mua nhà','BuyCar':'Mua xe',
      'Travel':'Du lịch','Invest':'Đầu tư','Retire':'Hưu trí sớm',
      'Education':'Học tập / Du học','Wedding':'Đám cưới',
      'Business':'Khởi nghiệp','Health':'Quỹ y tế',
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
    final currentText   = currentSalary > 0
        ? '${_fmt(currentSalary)}đ/tháng ← USER ĐÃ NHẬP, BẮT BUỘC DÙNG SỐ NÀY'
        : 'Chưa nhập → ước tính theo bảng';
    final targetText = targetSalary > 0
        ? '${_fmt(targetSalary)}đ/tháng' : 'Chưa cung cấp';
    final ctx = StringBuffer();
    if (living == 'OwnHouse')   ctx.write('• Có nhà riêng → KHÔNG có khoản "Nhà ở".\n');
    if (living == 'WithFamily') ctx.write('• Ở cùng gia đình → KHÔNG có khoản "Nhà ở".\n');
    if (married)                ctx.write('• Đã kết hôn → PHẢI có khoản "Chi phí gia đình".\n');
    if (hasChildren != 'Chưa có con') ctx.write('• Có con → PHẢI có khoản "Chi phí con cái".\n');
    if (hasDebt)                ctx.write('• Có nợ → PHẢI có khoản "Trả nợ hàng tháng".\n');
    final needsRent = living == 'Renting' || living == 'Boarding'
        || living == 'NoHouse' || living == 'Dormitory';
    return """Bạn là chuyên gia tư vấn tài chính cá nhân Việt Nam 2024-2025.

THÔNG TIN NGƯỜI DÙNG
Nghề nghiệp: $occLabel | Tuổi: $ageRange
Hôn nhân: ${married ? 'Đã kết hôn' : 'Độc thân'} | Thành phố: $cityLabel
Chỗ ở: ${livMap[living] ?? living}
Thu nhập ổn định: $stability | Nguồn: ${sources.isEmpty ? 'Chưa rõ' : sources}
THU NHẬP HIỆN TẠI: $currentText
Mong muốn: $targetText
Có con: $hasChildren | Phương tiện: $transport | Ăn: $eating
Có nợ: ${hasDebt ? 'Có' : 'Không'} | Có tiết kiệm: ${hasSavings ? 'Có' : 'Chưa'} | Mục tiêu: $goals

LƯU Ý: ${ctx.toString().isEmpty ? 'Không có.' : ctx.toString()}

QUY TẮC: 1. User đã nhập thu nhập → BẮT BUỘC dùng đúng số đó. 2. Tổng amount = recommended_income (±1%). 3. KHÔNG dùng từ "AI".

OUTPUT JSON THUẦN:
{"recommended_income":<số>,"income_reason":"<1 câu>","summary":"<2 câu>","expense_table":[${needsRent ? '{"category":"Nhà ở","amount":<số>,"percent":<số>,"note":"<ghi chú>"},' : ''}{"category":"Ăn uống","amount":<số>,"percent":<số>,"note":"<ghi chú>"},{"category":"Di chuyển","amount":<số>,"percent":<số>,"note":"<ghi chú>"},{"category":"Hóa đơn tiện ích","amount":<số>,"percent":<số>,"note":"Điện, nước, internet"},{"category":"Mua sắm cá nhân","amount":<số>,"percent":<số>,"note":"<ghi chú>"},{"category":"Giải trí & xã hội","amount":<số>,"percent":<số>,"note":"<ghi chú>"},{"category":"Tiết kiệm","amount":<số>,"percent":<số>,"note":"Chuyển ngay đầu tháng"},{"category":"Đầu tư & học tập","amount":<số>,"percent":<số>,"note":"<ghi chú>"},{"category":"Quỹ dự phòng","amount":<số>,"percent":<số>,"note":"Tình huống bất ngờ"}${hasDebt ? ',{"category":"Trả nợ hàng tháng","amount":<số>,"percent":<số>,"note":"Đều đặn"}' : ''}${married ? ',{"category":"Chi phí gia đình","amount":<số>,"percent":<số>,"note":"Sinh hoạt chung"}' : ''}${hasChildren != 'Chưa có con' ? ',{"category":"Chi phí con cái","amount":<số>,"percent":<số>,"note":"Học phí, sữa, y tế"}' : ''}],"tips":["<tip1>","<tip2>","<tip3>"],"goal_plan":"<2-3 câu>"}""";
  }

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
    final inputSalary = (d['currentSalary'] as num?)?.toDouble() ?? 0;
    final baseSalary = <String,double>{'Student':3500000,'Employee':12000000,'Freelancer':18000000,'Business':22000000,'Doctor':20000000,'Teacher':13000000,'Engineer':22000000,'Other':12000000};
    final cityMult = <String,double>{'HCM':1.00,'Hanoi':0.97,'DaNang':0.83,'HaiPhong':0.80,'BinhDuong':0.87,'CanTho':0.76,'BaRiaVT':0.80,'DakLak':0.72,'LamDong':0.72,'DongNai':0.82};
    final ageMult = <String,double>{'<22':0.72,'22-30':1.00,'31-40':1.38,'40+':1.55};
    double baseRec = (baseSalary[occupation] ?? 12000000) * (cityMult[city] ?? 0.78) * (ageMult[ageRange] ?? 1.0);
    if (married)                                   baseRec *= 1.28;
    if (hasChildren == 'Có 1 con')                 baseRec += 4000000;
    if (hasChildren == 'Có 2 con trở lên')         baseRec += 7500000;
    if (transport == 'car' || transport == 'Ô tô') baseRec += 3500000;
    final rec = (inputSalary > 0 ? inputSalary : baseRec).roundToDouble();
    final bool needsRent = living=='Renting'||living=='Boarding'||living=='NoHouse'||living=='Dormitory';
    final bool hasKids = hasChildren != 'Chưa có con';
    double rentPct = 0;
    if (needsRent) { if (living=='Dormitory') rentPct=8; else if (living=='Boarding') rentPct=18; else if (city=='HCM') rentPct=25; else if (city=='Hanoi') rentPct=22; else rentPct=18; }
    double foodPct = 23;
    if (eating=='cook'||eating=='Hay nấu nhà') foodPct=20;
    if (eating=='eatout'||eating=='Hay ăn ngoài') foodPct=28;
    if (married) foodPct+=7;
    if (hasKids) foodPct+=5;
    double transPct = 5;
    if (transport=='car'||transport=='Ô tô') transPct=12;
    else if (transport=='grab'||transport=='Grab/buýt') transPct=8;
    else if (transport=='walk'||transport=='Đi bộ') transPct=1;
    const billsPct=5.0; const shopPct=5.0; const entPct=4.0; const emergPct=5.0;
    final familyPct=married?5.0:0.0; final childPct=hasKids?8.0:0.0; final debtPct=hasDebt?10.0:0.0;
    final investPct=occupation=='Student'?3.0:7.0;
    final usedPct=rentPct+foodPct+transPct+billsPct+shopPct+entPct+emergPct+familyPct+childPct+debtPct+investPct;
    final savingPct=(100.0-usedPct).clamp(5.0,40.0);
    int p(double pct) => (rec*pct/100).round();
    final rentAmt=p(rentPct); final foodAmt=p(foodPct); final transAmt=p(transPct);
    final billsAmt=p(billsPct); final shopAmt=p(shopPct); final entAmt=p(entPct);
    final emergAmt=p(emergPct); final familyAmt=p(familyPct); final childAmt=p(childPct);
    final debtAmt=p(debtPct); final investAmt=p(investPct);
    int savingAmt=p(savingPct);
    final sub=rentAmt+foodAmt+transAmt+billsAmt+shopAmt+entAmt+emergAmt+familyAmt+childAmt+debtAmt+investAmt+savingAmt;
    savingAmt += rec.toInt()-sub;
    final cityName = PlanFormData.cityName(city);
    final occLabel = PlanFormData.occupationLabel(occupation, d['customOccupation'] ?? '');
    String transNote='Xăng xe máy + bảo dưỡng';
    if (transport=='car'||transport=='Ô tô') transNote='Xăng + bảo dưỡng + bãi đỗ ô tô';
    else if (transport=='grab'||transport=='Grab/buýt') transNote='Grab / xe buýt hàng ngày';
    else if (transport=='walk'||transport=='Đi bộ') transNote='Đi bộ / xe đạp';
    String eatNote='50% nấu nhà, 50% ăn ngoài';
    if (eating=='cook'||eating=='Hay nấu nhà') eatNote='Chủ yếu nấu tại nhà';
    else if (eating=='eatout'||eating=='Hay ăn ngoài') eatNote='Hay ăn ngoài — cần kiểm soát';
    if (married) eatNote+=' (cả gia đình)';
    final table=<Map<String,dynamic>>[
      if (rentAmt>0) {'category':'Nhà ở','amount':rentAmt,'percent':rentPct.round(),'note':living=='Dormitory'?'Ký túc xá':living=='Boarding'?'Nhà trọ':'Thuê nhà tại $cityName'},
      {'category':'Ăn uống','amount':foodAmt,'percent':foodPct.round(),'note':eatNote},
      {'category':'Di chuyển','amount':transAmt,'percent':transPct.round(),'note':transNote},
      {'category':'Hóa đơn tiện ích','amount':billsAmt,'percent':billsPct.round(),'note':'Điện, nước, internet'},
      {'category':'Mua sắm cá nhân','amount':shopAmt,'percent':shopPct.round(),'note':'Quần áo, đồ dùng'},
      {'category':'Giải trí & xã hội','amount':entAmt,'percent':entPct.round(),'note':'Cà phê, phim, bạn bè'},
      {'category':'Tiết kiệm','amount':savingAmt,'percent':savingPct.round(),'note':'Chuyển ngay khi nhận lương'},
      {'category':'Đầu tư & học tập','amount':investAmt,'percent':investPct.round(),'note':'Khóa học, sách, quỹ'},
      {'category':'Quỹ dự phòng','amount':emergAmt,'percent':emergPct.round(),'note':'Tình huống khẩn cấp'},
      if (hasDebt) {'category':'Trả nợ hàng tháng','amount':debtAmt,'percent':debtPct.round(),'note':'Đều đặn'},
      if (married) {'category':'Chi phí gia đình','amount':familyAmt,'percent':familyPct.round(),'note':'Sinh hoạt chung'},
      if (hasKids) {'category':'Chi phí con cái','amount':childAmt,'percent':childPct.round(),'note':'Học phí, sữa, y tế'},
    ];
    final incomeReason = inputSalary>0 ? 'Thu nhập bạn cung cấp, dùng làm cơ sở lập kế hoạch.' : 'Ước tính phù hợp $occLabel tại $cityName (2024-2025).';
    final savingTip = occupation=='Student' ? 'Tìm việc làm thêm phù hợp ngành học.' : occupation=='Teacher' ? 'Dạy thêm hoặc gia sư online 2-3 buổi/tuần.' : 'Tìm cơ hội tăng thu nhập qua công việc phụ hoặc đầu tư nhỏ.';
    return {'recommended_income':rec.toInt(),'income_reason':incomeReason,'summary':'Với hoàn cảnh ${occupation=="Student"?"sinh viên":married?"đã kết hôn":"độc thân"} tại $cityName, kế hoạch cân bằng chi tiêu và tích lũy. ${savingPct>=15?"Tỷ lệ tiết kiệm hợp lý.":"Cố gắng cắt giảm để tăng tiết kiệm."}','expense_table':table,'tips':['Chuyển ${_fmt(savingAmt)}đ tiết kiệm ngay ngày nhận lương.',savingTip,married?'Lên ngân sách gia đình cùng vợ/chồng mỗi đầu tháng.':'Ghi chép chi tiêu hàng ngày.'],'goal_plan':'Tiết kiệm đều ${_fmt(savingAmt)}đ/tháng. Sau 3-6 tháng xây quỹ dự phòng ≈ ${_fmt(rec*3)}đ. Sau đó tăng dần đầu tư.'};
  }

  Future<void> _generate(Map<String, dynamic> formData) async {
    setState(() => _isGenerating = true);
    Map<String, dynamic> plan;
    try {
      final res = await http.post(Uri.parse(_backendUrl), headers: {'Content-Type':'application/json'}, body: jsonEncode({'message':_buildPrompt(formData),'chatHistory':[],'financialContext':''})).timeout(const Duration(seconds: 40));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw  = (body['message'] as String? ?? '').replaceAll(RegExp(r'```json\s*'),'').replaceAll(RegExp(r'```\s*'),'').trim();
        final s = raw.indexOf('{'); final e = raw.lastIndexOf('}');
        if (s >= 0 && e > s) { plan = jsonDecode(raw.substring(s, e+1)) as Map<String, dynamic>; }
        else { throw Exception('No JSON'); }
      } else { plan = _fallbackPlan(formData); }
    } catch (e) { plan = _fallbackPlan(formData); }
    if (mounted) { setState(() => _isGenerating = false); _onPlanCreated(plan, formData); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_savedPlan == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(child: PlanEntryView(onPlanCreated: _onPlanCreated, isGenerating: _isGenerating, onGenerate: _generate)),
        bottomNavigationBar: _SharedBottomNavBar(activeIndex: 3, isDark: isDark),
      );
    }
    return _PlanResultScreen(plan: _savedPlan!, formData: _savedFormData!, onReset: _resetPlan);
  }
}

// ══════════════════════════════════════════════════════════
// RESULT SCREEN
// ══════════════════════════════════════════════════════════
class _PlanResultScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> formData;
  final VoidCallback onReset;
  const _PlanResultScreen({required this.plan, required this.formData, required this.onReset});
  @override
  State<_PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends State<_PlanResultScreen> {
  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);
  static const _orange = Color(0xFFFF9800);

  int _tabIndex = 0;
  Map<String, int> _editedAmounts = {};
  bool _isSaved = false;

  bool _editingIncome = false;
  final TextEditingController _incomeEditCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initIncome = (widget.plan['recommended_income'] as num?)?.toInt() ?? 0;
    _incomeEditCtrl.text = initIncome.toString();
  }

  @override
  void dispose() {
    _incomeEditCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get plan     => widget.plan;
  Map<String, dynamic> get formData => widget.formData;

  bool   get _isMarried   => (formData['maritalStatus'] as String? ?? '') == 'Married';
  String get _hasChildren => formData['hasChildren'] as String? ?? 'Chưa có con';
  bool   get _hasKids     => _hasChildren != 'Chưa có con';

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  double get _rec1 {
    if (_editedAmounts.containsKey('__income__'))
      return (_editedAmounts['__income__'] as num).toDouble();
    return (plan['recommended_income'] as num?)?.toDouble() ?? 0;
  }
  double get _rec2      => (_rec1 * 0.75).roundToDouble();
  double get _recFamily => _rec1 + _rec2;

  Future<void> _saveEditedPlan(BuildContext context) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final editedTable = (plan['expense_table'] as List).map((r) {
        final row = Map<String, dynamic>.from(r as Map);
        final cat = row['category'] as String? ?? '';
        if (_editedAmounts.containsKey(cat)) row['amount'] = _editedAmounts[cat];
        return row;
      }).toList();
      for (final entry in _editedAmounts.entries) {
        if (entry.key.startsWith('__extra__')) {
          final cat = entry.key.replaceFirst('__extra__', '');
          editedTable.add({'category':cat,'amount':entry.value,'percent':0,'note':'Tự thêm'});
        }
      }
      final editedPlan = Map<String, dynamic>.from(plan);
      editedPlan['expense_table'] = editedTable;
      if (_editedAmounts.containsKey('__income__'))
        editedPlan['recommended_income'] = _editedAmounts['__income__'];
      await FirebaseFirestore.instance.collection('users')
          .doc(uid).collection('plans').doc('current_plan')
          .set({'plan': editedPlan, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      setState(() => _isSaved = true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Đã lưu kế hoạch thành công!')]),
          backgroundColor: _teal, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  List<Map<String, dynamic>> get _familyTable {
    final base = (plan['expense_table'] as List? ?? []);
    const mult = <String, double>{'Nhà ở':1.0,'Ăn uống':1.0,'Di chuyển':1.4,'Hóa đơn tiện ích':1.4,'Mua sắm cá nhân':1.6,'Giải trí & xã hội':1.3,'Tiết kiệm':1.8,'Đầu tư & học tập':1.8,'Quỹ dự phòng':1.5,'Trả nợ hàng tháng':1.0,'Chi phí gia đình':1.0,'Chi phí con cái':1.0};
    double foodMult = 1.8;
    if (_hasChildren == 'Có 1 con') foodMult = 2.3;
    if (_hasChildren == 'Có 2 con trở lên') foodMult = 3.0;
    final result = <Map<String, dynamic>>[];
    for (final row in base) {
      final cat = row['category'] as String? ?? '';
      final amt = (row['amount'] as num?)?.toDouble() ?? 0;
      final m   = cat == 'Ăn uống' ? foodMult : (mult[cat] ?? 1.5);
      final newAmt = (amt * m).round();
      result.add({'category':cat,'amount':newAmt,'percent':_recFamily>0?(newAmt/_recFamily*100).round():0,'note':_familyNote(cat, row['note']??'')});
    }
    if (_hasKids && !base.any((r) => r['category'] == 'Chi phí con cái')) {
      final childAmt = _hasChildren=='Có 2 con trở lên'?9000000:5000000;
      result.add({'category':'Chi phí con cái','amount':childAmt,'percent':_recFamily>0?(childAmt/_recFamily*100).round():0,'note':_hasChildren=='Có 2 con trở lên'?'Học phí, sữa, y tế, đồ chơi 2 con':'Học phí, sữa, y tế trẻ em'});
    }
    return result;
  }

  String _familyNote(String cat, String original) {
    switch (cat) {
      case 'Ăn uống': return _hasChildren=='Có 2 con trở lên'?'Ăn uống cho gia đình 4 người':_hasChildren=='Có 1 con'?'Ăn uống cho gia đình 3 người':'Ăn uống cho 2 vợ chồng';
      case 'Di chuyển': return 'Di chuyển 2 người + đưa đón con';
      case 'Tiết kiệm': return 'Tiết kiệm gia đình hàng tháng';
      case 'Đầu tư & học tập': return _hasKids?'Đầu tư + quỹ giáo dục cho con':'Đầu tư chung gia đình';
      default: return original;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: Column(children: [
        _header(context, isDark),
        if (_isMarried) ...[const SizedBox(height: 12), _tabSwitcher(isDark)],
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _summaryCard(isDark),
            const SizedBox(height: 16),
            _isMarried && _tabIndex == 1 ? _familyIncomeCard(isDark) : _incomeCard(isDark),
            const SizedBox(height: 16),
            _isMarried && _tabIndex == 1 ? _familyExpenseTable(isDark) : _expenseTable(isDark),
            const SizedBox(height: 16),
            _tipsCard(isDark),
            const SizedBox(height: 16),
            _goalCard(isDark),
            const SizedBox(height: 16),
            _spendRuleBtn(context),
          ]),
        )),
      ])),
      bottomNavigationBar: _SharedBottomNavBar(activeIndex: 3, isDark: isDark),
    );
  }

  Widget _header(BuildContext ctx, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kế hoạch của bạn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Được tạo tự động', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ])),
        GestureDetector(
          onTap: widget.onReset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, size: 15, color: isDark ? Colors.grey[300] : Colors.grey[700]),
              const SizedBox(width: 4),
              Text('Tạo lại', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tabSwitcher(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _tabBtn(0, '👤  Cá nhân', _teal, isDark),
          _tabBtn(1, _hasKids ? (_hasChildren=='Có 2 con trở lên' ? '👨‍👩‍👧‍👦  Cả gia đình (4 người)' : '👨‍👩‍👦  Cả gia đình (3 người)') : '👫  Cả 2 vợ chồng', _orange, isDark),
        ]),
      ),
    );
  }

  Widget _tabBtn(int index, String label, Color activeColor, bool isDark) {
    final active = _tabIndex == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: active ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(9), boxShadow: active ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : []),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.normal, color: active ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600])))),
      ),
    ));
  }

  Widget _summaryCard(bool isDark) {
    final s = plan['summary'] as String? ?? '';
    if (s.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF48D1CC)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.info_outline_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Nhận xét', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]),
        const SizedBox(height: 10),
        Text(s, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _incomeCard(bool isDark) {
    final rec      = _rec1;
    final isEdited = _editedAmounts.containsKey('__income__');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _editingIncome ? _teal : isEdited ? _teal.withOpacity(0.4) : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: _editingIncome ? 2 : isEdited ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_editingIncome ? Icons.edit_rounded : Icons.account_balance_wallet_rounded, color: _teal, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdited ? 'Thu nhập của bạn' : 'Mức thu nhập phù hợp', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (!_editingIncome)
              Text(isEdited ? 'Đã chỉnh sửa thủ công' : 'Nhấn vào số tiền để chỉnh sửa',
                  style: TextStyle(fontSize: 11, color: _teal.withOpacity(0.7))),
          ])),
          if (!_editingIncome && isEdited)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('Đã chỉnh', style: TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 14),
        if (_editingIncome) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: _teal.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _teal.withOpacity(0.3))),
            child: Row(children: [
              const Text('₫', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _teal)),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: _incomeEditCtrl, autofocus: true, keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _teal),
                decoration: const InputDecoration(hintText: '0', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                  suffixText: 'đ / tháng', suffixStyle: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal)),
              )),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [8000000, 10000000, 15000000, 20000000, 25000000].map((v) {
            final label = '${v ~/ 1000000}tr';
            final isSel = (_incomeEditCtrl.text == v.toString());
            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(onTap: () => setState(() => _incomeEditCtrl.text = v.toString()),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: isSel ? _teal : _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _teal.withOpacity(0.3))),
                  child: Center(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : _teal)))))));
          }).toList()),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() { _editingIncome = false; _incomeEditCtrl.text = rec.toInt().toString(); }),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Hủy', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600], fontWeight: FontWeight.w600)))))),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: GestureDetector(
              onTap: () {
                final val = int.tryParse(_incomeEditCtrl.text.replaceAll(',', '')) ?? 0;
                if (val > 0) setState(() { _editedAmounts['__income__'] = val; _editingIncome = false; _isSaved = false; });
              },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [_teal, Color(0xFF0097A7)]), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('Xác nhận', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)))))),
          ]),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() {
              _editingIncome = true;
              _incomeEditCtrl.text = rec.toInt().toString();
              _incomeEditCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _incomeEditCtrl.text.length);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _teal.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _teal.withOpacity(0.2))),
              child: Row(children: [
                Expanded(child: Text('${_fmt(rec)} đ / tháng', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _teal))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: _teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_rounded, size: 12, color: _teal), SizedBox(width: 4), Text('Sửa', style: TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w600))])),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(isEdited ? 'Thu nhập bạn đã chỉnh sửa thủ công.' : (plan['income_reason'] as String? ?? ''),
              style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
        ],
      ]),
    );
  }

  Widget _familyIncomeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _orange.withOpacity(0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.people_rounded, color: _orange, size: 20)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Mức thu nhập gia đình', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _incomeMiniCard(label:'Bạn (ước tính)', amount:_rec1, color:_teal, sub:'100%', isDark:isDark)),
          const SizedBox(width: 10),
          Expanded(child: _incomeMiniCard(label:'Vợ / Chồng', amount:_rec2, color:_purple, sub:'~75% của bạn', isDark:isDark)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: LinearGradient(colors:[_orange.withOpacity(0.8),_orange], begin:Alignment.topLeft, end:Alignment.bottomRight), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tổng thu nhập gia đình', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${_fmt(_recFamily)} đ / tháng', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _incomeMiniCard({required String label, required double amount, required Color color, required String sub, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Text('${_fmt(amount)}đ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
      ]),
    );
  }

  Future<void> _openEditPage(List<Map<String, dynamic>> rows) async {
    final result = await Navigator.push<Map<String, int>>(context, MaterialPageRoute(builder: (_) => PlanEditView(rows: _displayRows, initialEdits: Map<String, int>.from(_editedAmounts), recommendedIncome: _rec1.toInt())));
    if (result != null) setState(() { _editedAmounts = result; _isSaved = false; });
  }

  Widget _buildExpenseTableWidget(List<Map<String, dynamic>> rows, double totalIncome, bool isDark, {Color accentColor = _teal}) {
    const rowColors = [Color(0xFF00CED1),Color(0xFF4CAF50),Color(0xFFFF9800),Color(0xFF2196F3),Color(0xFFE91E63),Color(0xFF9C27B0),Color(0xFFFF5722),Color(0xFF009688),Color(0xFFFFC107),Color(0xFF607D8B),Color(0xFFE53935),Color(0xFF8BC34A)];
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.table_chart_rounded, color: _purple, size: 20)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Kế hoạch chi tiêu chi tiết', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          GestureDetector(onTap: () => _openEditPage(rows),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _purple.withOpacity(0.25))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_rounded, size: 11, color: _purple), SizedBox(width: 3), Text('Chỉnh sửa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _purple))]))),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C1A) : const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(10), border: Border.all(color: _orange.withOpacity(0.3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔢', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: RichText(text: TextSpan(style: TextStyle(fontSize: 11, height: 1.45, color: isDark ? Colors.grey[300] : Colors.grey[700]), children: const [
              TextSpan(text: 'Tại sao số tiền lẻ? ', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: 'Hệ thống chia tỷ lệ tự động để tổng = đúng 100% thu nhập. Nhấn "Chỉnh sửa" để làm tròn sang số bạn muốn.'),
            ]))),
          ]),
        )),
        if (_editedAmounts.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: _orange.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: _orange.withOpacity(0.2))),
            child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: _orange), const SizedBox(width: 6), Text('${_editedAmounts.length} mục đã được chỉnh sửa', style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.w500))]))),
        const SizedBox(height: 12),
        Container(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: const Row(children: [
          Expanded(flex: 5, child: Text('DANH MỤC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5))),
          Expanded(flex: 4, child: Text('SỐ TIỀN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5), textAlign: TextAlign.right)),
          SizedBox(width: 8),
          SizedBox(width: 42, child: Text('%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5), textAlign: TextAlign.center)),
        ])),
        ...rows.asMap().entries.map((e) {
          final i = e.key; final row = e.value;
          final category = row['category'] as String? ?? '';
          final origAmt  = (row['amount'] as num?)?.toDouble() ?? 0;
          final displayAmt = (_editedAmounts[category] ?? origAmt).toInt();
          final percent  = (row['percent'] as num?)?.toInt() ?? 0;
          final color    = rowColors[i % rowColors.length];
          final isLast   = i == rows.length - 1;
          final isEdited = _editedAmounts.containsKey(category);
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(flex: 5, child: Text(category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                Expanded(flex: 4, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (isEdited) Container(margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: _orange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: const Text('✏️', style: TextStyle(fontSize: 9))),
                  Text('${_fmt(displayAmt)} đ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isEdited ? _orange : color)),
                ])),
                const SizedBox(width: 8),
                Container(width: 42, height: 24, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Center(child: Text('$percent%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)))),
              ]),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(left: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: (percent/100).clamp(0.0,1.0), backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100], valueColor: AlwaysStoppedAnimation(color), minHeight: 4)),
                if ((row['note']??'').toString().isNotEmpty) ...[const SizedBox(height: 3), Text(row['note'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey[500]))],
              ])),
            ])),
            if (!isLast) Divider(height: 1, thickness: 0.5, color: isDark ? Colors.grey[700] : Colors.grey[100]),
          ]);
        }).toList(),
        () {
          final totalExpense = rows.fold<int>(0, (s, r) {
            final cat = r['category'] as String? ?? '';
            final amt = (_editedAmounts[cat] ?? (r['amount'] as num?)?.toInt() ?? 0);
            return s + amt;
          });
          final remaining = totalIncome.toInt() - totalExpense;
          return Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: accentColor.withOpacity(0.25))),
            child: Column(children: [
              Row(children: [
                Icon(Icons.calculate_rounded, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Tổng chi tiêu kế hoạch', style: TextStyle(fontWeight: FontWeight.w600, color: accentColor, fontSize: 13))),
                Text('${_fmt(totalExpense)} đ', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.account_balance_wallet_rounded, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Thu nhập / tháng', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                Text('${_fmt(totalIncome.toInt())} đ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: totalIncome > 0 ? (totalExpense / totalIncome).clamp(0.0, 1.0) : 0, minHeight: 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(totalExpense > totalIncome ? Colors.red : accentColor))),
              const SizedBox(height: 6),
              Row(children: [
                Icon(remaining >= 0 ? Icons.savings_rounded : Icons.warning_rounded, size: 14, color: remaining >= 0 ? Colors.green[600] : Colors.red),
                const SizedBox(width: 6),
                Expanded(child: Text(remaining >= 0 ? 'Chưa phân bổ / Tiết kiệm thêm' : 'Vượt thu nhập',
                    style: TextStyle(fontSize: 11, color: remaining >= 0 ? Colors.green[600] : Colors.red))),
                Text('${remaining >= 0 ? '+' : ''}${_fmt(remaining)} đ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: remaining >= 0 ? Colors.green[600] : Colors.red)),
              ]),
            ]),
          );
        }(),
        () {
          final totalExpense = rows.fold<int>(0, (s, r) {
            final cat = r['category'] as String? ?? '';
            return s + (_editedAmounts[cat] ?? (r['amount'] as num?)?.toInt() ?? 0);
          });
          final remaining = totalIncome.toInt() - totalExpense;
          if (remaining <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: RichText(text: TextSpan(style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey[700]), children: [
                  TextSpan(text: 'Tại sao còn dư ${_fmt(remaining)}đ? ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
                  const TextSpan(text: 'Kế hoạch này chỉ liệt kê các khoản chi chính. Phần còn lại bạn có thể dùng để '),
                  const TextSpan(text: 'tăng tiết kiệm, đầu tư thêm, ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: 'hoặc thêm khoản chi khác bằng nút "Chỉnh sửa".'),
                ]))),
              ]),
            ),
          );
        }(),
        Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: _isSaved ? null : () => _saveEditedPlan(context),
          icon: Icon(_isSaved ? Icons.check_circle_rounded : Icons.save_alt_rounded, color: Colors.white, size: 18),
          label: Text(_isSaved ? 'Đã lưu kế hoạch ✓' : 'Lưu kế hoạch', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: _isSaved ? Colors.grey[400] : _purple, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ))),
      ]),
    );
  }

  List<Map<String, dynamic>> get _displayRows {
    final rows = (plan['expense_table'] as List? ?? []).map((r) => Map<String, dynamic>.from(r as Map)).toList();
    for (final row in rows) {
      final cat = row['category'] as String? ?? '';
      if (_editedAmounts.containsKey(cat)) row['amount'] = _editedAmounts[cat];
    }
    for (final entry in _editedAmounts.entries) {
      if (entry.key.startsWith('__extra__')) {
        final cat = entry.key.replaceFirst('__extra__', '');
        rows.add({'category':cat,'amount':entry.value,'percent':_rec1>0?(entry.value/_rec1*100).round():0,'note':'+ Tự thêm'});
      }
    }
    return rows;
  }

  Widget _expenseTable(bool isDark) => _buildExpenseTableWidget(_displayRows, _rec1, isDark, accentColor: _teal);
  Widget _familyExpenseTable(bool isDark) => _buildExpenseTableWidget(_familyTable, _recFamily, isDark, accentColor: _orange);

  Widget _tipsCard(bool isDark) {
    final table = (plan['expense_table'] as List? ?? []);
    final rec   = _rec1;
    final occ   = formData['occupation'] as String? ?? '';
    final eating = formData['eatingHabit'] as String? ?? 'mixed';
    final living = formData['livingStatus'] as String? ?? 'Renting';
    final city   = formData['city'] as String? ?? 'HCM';
    double getAmt(String cat) { for (final r in table) { if ((r['category'] as String? ?? '') == cat) return (r['amount'] as num?)?.toDouble() ?? 0; } return 0; }
    final saving = getAmt('Tiết kiệm'); final food = getAmt('Ăn uống'); final rent = getAmt('Nhà ở'); final ent = getAmt('Giải trí & xã hội'); final invest = getAmt('Đầu tư & học tập');
    final tips = <_TipItem>[];
    if (saving > 0) tips.add(_TipItem(icon:'💰', color:_teal, title:'Tiết kiệm ${_fmt(saving)}đ ngay đầu tháng', desc:'Ngay khi nhận lương, chuyển ${_fmt(saving)}đ vào tài khoản tiết kiệm riêng TRƯỚC khi chi bất cứ thứ gì.'));
    if (food > 0) { final perDay=(food/30).round(); tips.add(_TipItem(icon:'🍜', color:const Color(0xFFFF9800), title:'Kiểm soát ăn uống — khoản dễ vượt nhất', desc:'Ngân sách ăn uống ${_fmt(food)}đ/tháng (~${_fmt(perDay)}đ/ngày). Tăng số bữa nấu tại nhà để tiết kiệm thêm.')); }
    if (rent > 0 && (living=='Renting'||living=='Boarding'||living=='NoHouse')) { final rentPct=rec>0?(rent/rec*100).round():0; tips.add(_TipItem(icon:'🏠', color:const Color(0xFF4CAF50), title:'Nhà ở — khoản cố định cần giữ ổn định', desc:'Tiền thuê nhà ${_fmt(rent)}đ ($rentPct% thu nhập)${rentPct>30?" — khá cao. Tìm phòng chia sẻ để giảm xuống dưới 25%.":" — đang hợp lý."}')); }
    if (ent > 0) { final entPct=rec>0?(ent/rec*100).round():0; tips.add(_TipItem(icon:'🎬', color:const Color(0xFF8B5CF6), title:'Giải trí ${_fmt(ent)}đ/tháng${entPct>=8?" — cần kiểm soát":" — đang hợp lý"}', desc:'Chia đều theo tuần (~${_fmt((ent/4).round())}đ/tuần) để không tiêu hết đầu tháng.')); }
    if (occ=='Student') tips.add(_TipItem(icon:'📱', color:const Color(0xFF00BCD4), title:'Tìm việc làm thêm phù hợp ngành', desc:'Sinh viên ${PlanFormData.cityName(city)} có thể kiếm thêm 2-5tr/tháng từ gia sư, thực tập có lương.'));
    else if (occ=='Teacher') tips.add(_TipItem(icon:'📚', color:const Color(0xFF00BCD4), title:'Dạy thêm để tăng thu nhập', desc:'Dạy thêm 2-3 buổi/tuần, mỗi buổi 150-300k — đủ để tăng tiết kiệm.'));
    else if (occ=='Freelancer') tips.add(_TipItem(icon:'💻', color:const Color(0xFF00BCD4), title:'Thu nhập không ổn định — cần quỹ đệm', desc:'Nên có quỹ đệm 2-3 tháng lương (≈ ${_fmt(rec*2.5)}) để tháng không có dự án vẫn đủ sống.'));
    if (tips.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _purple.withOpacity(0.07), borderRadius: BorderRadius.circular(18), border: Border.all(color: _purple.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.lightbulb_outline_rounded, color: _purple, size: 18), SizedBox(width: 8), Text('Lời khuyên cụ thể cho bạn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _purple))]),
        const SizedBox(height: 12),
        ...tips.take(4).map((tip) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: tip.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(tip.icon, style: const TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tip.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tip.color)),
            const SizedBox(height: 3),
            Text(tip.desc, style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.grey[300] : Colors.grey[600])),
          ])),
        ]))).toList(),
      ]),
    );
  }

  Widget _goalCard(bool isDark) {
    final table = (plan['expense_table'] as List? ?? []);
    final rec   = _rec1;
    double getAmt(String cat) { for (final r in table) { if ((r['category'] as String? ?? '') == cat) return (r['amount'] as num?)?.toDouble() ?? 0; } return 0; }
    final saving = getAmt('Tiết kiệm'); final emerg = getAmt('Quỹ dự phòng'); final invest = getAmt('Đầu tư & học tập');
    final totalFixed = table.fold<double>(0, (sum, r) { final cat = (r as Map)['category'] as String? ?? ''; if (['Nhà ở','Di chuyển','Hóa đơn tiện ích'].contains(cat)) return sum + ((r['amount'] as num?)?.toDouble() ?? 0); return sum; });
    final leftAfterFixed = rec - totalFixed - saving - emerg;
    final actions = [
      _ActionItem(week:'Ngày nhận lương', icon:'💸', color:_teal, action:'Chuyển ${_fmt(saving+emerg)}đ vào tiết kiệm', detail:'${_fmt(saving)}đ tiết kiệm + ${_fmt(emerg)}đ quỹ dự phòng. Làm ngay, không để qua hôm sau.'),
      _ActionItem(week:'Tuần 1-4', icon:'📊', color:const Color(0xFF8B5CF6), action:'Chi tiêu sinh hoạt tối đa ${_fmt(leftAfterFixed)}đ', detail:'Chia đều ~${_fmt((leftAfterFixed/4).round())}đ/tuần cho ăn uống, mua sắm, giải trí.'),
      _ActionItem(week:'Cuối tháng', icon:'📋', color:const Color(0xFFFF9800), action:'Kiểm tra xem có vượt kế hoạch không', detail:'Nhìn lại 3 khoản dễ vượt: ăn uống, giải trí, mua sắm. Nếu vượt → tháng sau cắt đúng khoản đó.'),
      if (invest > 0) _ActionItem(week:'Sau 3 tháng', icon:'🎯', color:const Color(0xFF4CAF50), action:'Bắt đầu đầu tư ${_fmt(invest)}đ/tháng', detail:'Sau khi có quỹ dự phòng đủ 3 tháng, mới nên bắt đầu đầu tư vào quỹ mở hoặc gửi kỳ hạn.'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.calendar_month_rounded, color: _teal, size: 18), SizedBox(width: 8), Text('Kế hoạch hành động tháng này', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 14),
        ...actions.asMap().entries.map((e) {
          final i = e.key; final action = e.value; final isLast = i == actions.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: action.color, shape: BoxShape.circle), child: Center(child: Text(action.icon, style: const TextStyle(fontSize: 15)))),
              if (!isLast) Container(width: 2, height: 48, color: action.color.withOpacity(0.25)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: action.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(action.week, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: action.color))),
              const SizedBox(height: 4),
              Text(action.action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(action.detail, style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ]))),
          ]);
        }).toList(),
      ]),
    );
  }

  Widget _spendRuleBtn(BuildContext ctx) {
    return SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
      onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SpendingRuleView())),
      icon: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18),
      label: const Text('Xem quy tắc 50/30/20', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(backgroundColor: _teal, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ));
  }
}

class _TipItem {
  final String icon; final Color color; final String title; final String desc;
  const _TipItem({required this.icon, required this.color, required this.title, required this.desc});
}

class _ActionItem {
  final String week; final String icon; final Color color; final String action; final String detail;
  const _ActionItem({required this.week, required this.icon, required this.color, required this.action, required this.detail});
}

// ══════════════════════════════════════════════════════════
// SHARED BOTTOM NAV BAR
// ══════════════════════════════════════════════════════════
class _SharedBottomNavBar extends StatelessWidget {
  final int activeIndex; final bool isDark;
  const _SharedBottomNavBar({required this.activeIndex, required this.isDark});
  static const _teal = Color(0xFF00CED1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _item(context, Icons.home_rounded, 'Home', 0,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeView()))),
          _item(context, Icons.history_rounded, 'History', 1,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CategoriesView()))),
          _voiceItem(context),
          _item(context, Icons.pie_chart_rounded, 'Plan', 3, activeIndex == 3 ? () {} : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BudgetPlanView()))),
          _item(context, Icons.person_outline_rounded, 'Profile', 4,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileView()))),
        ]),
      )),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label, int index, VoidCallback onTap) {
    final active = index == activeIndex;
    final color  = active ? _teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: active ? _teal.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 24)),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: color)),
    ]));
  }

  Widget _voiceItem(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(ctx,
          MaterialPageRoute(builder: (_) => const SpecialFeaturesView())),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26)),
        const SizedBox(height: 4),
        const Text('Tính năng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
      ]),
    );
  }
}