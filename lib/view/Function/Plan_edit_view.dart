// lib/view/Function/PlanEditView.dart
//
// Màn hình chỉnh sửa kế hoạch chi tiêu.
// Navigator.push từ _PlanResultScreen, trả về Map<String,int> editedAmounts
// khi người dùng nhấn "Lưu & Quay lại".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlanEditView extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final Map<String, int> initialEdits;
  final int recommendedIncome;

  const PlanEditView({
    Key? key,
    required this.rows,
    required this.initialEdits,
    required this.recommendedIncome,
  }) : super(key: key);

  @override
  State<PlanEditView> createState() => _PlanEditViewState();
}

class _PlanEditViewState extends State<PlanEditView> {
  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);
  static const _orange = Color(0xFFFF9800);
  static const _red    = Color(0xFFE53935);
  static const _green  = Color(0xFF4CAF50);

  final Map<String, TextEditingController> _ctrls = {};
  final List<Map<String, dynamic>> _extraRows = [];
  final Map<String, TextEditingController> _extraCtrls = {};

  late TextEditingController _incomeCtrl;
  bool _showIncomeField = false;

  static const _rowColors = [
    Color(0xFF00CED1), Color(0xFF4CAF50), Color(0xFFFF9800),
    Color(0xFF2196F3), Color(0xFFE91E63), Color(0xFF9C27B0),
    Color(0xFFFF5722), Color(0xFF009688), Color(0xFFFFC107),
    Color(0xFF607D8B), Color(0xFFE53935), Color(0xFF8BC34A),
  ];

  @override
  void initState() {
    super.initState();
    final initIncome = widget.initialEdits['__income__'] ?? widget.recommendedIncome;
    _incomeCtrl = TextEditingController(text: initIncome.toString());

    for (final row in widget.rows) {
      final cat     = row['category'] as String? ?? '';
      final origAmt = (row['amount'] as num?)?.toInt() ?? 0;
      final initVal = widget.initialEdits[cat] ?? origAmt;
      _ctrls[cat]   = TextEditingController(text: initVal.toString());
    }
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    for (final c in _ctrls.values) c.dispose();
    for (final c in _extraCtrls.values) c.dispose();
    super.dispose();
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  int get _total {
    int sum = _ctrls.values.fold(0, (s, c) =>
        s + (int.tryParse(c.text.replaceAll(',', '')) ?? 0));
    sum += _extraCtrls.values.fold(0, (s, c) =>
        s + (int.tryParse(c.text.replaceAll(',', '')) ?? 0));
    return sum;
  }

  int get _income =>
      int.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;

  int get _remaining => _income - _total;

  void _save() {
    final result = <String, int>{};
    final inc = _income;
    if (inc > 0) result['__income__'] = inc;

    for (final row in widget.rows) {
      final cat = row['category'] as String? ?? '';
      final val = int.tryParse(_ctrls[cat]?.text.replaceAll(',', '') ?? '');
      if (val != null) result[cat] = val;
    }

    for (final extra in _extraRows) {
      final cat = extra['category'] as String? ?? '';
      final val = int.tryParse(_extraCtrls[cat]?.text.replaceAll(',', '') ?? '');
      if (val != null && cat.isNotEmpty) result['__extra__$cat'] = val;
    }

    Navigator.pop(context, result);
  }

  void _reset() {
    setState(() {
      _incomeCtrl.text = widget.recommendedIncome.toString();
      for (final row in widget.rows) {
        final cat     = row['category'] as String? ?? '';
        final origAmt = (row['amount'] as num?)?.toInt() ?? 0;
        _ctrls[cat]?.text = origAmt.toString();
      }
      for (final c in _extraCtrls.values) c.dispose();
      _extraCtrls.clear();
      _extraRows.clear();
    });
  }

  void _showAddDialog(bool isDark) {
    final nameCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 20),
              const Text('Thêm khoản chi mới',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Nhập tên và số tiền khoản chi bạn muốn thêm',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Tên khoản chi',
                  hintText: 'VD: Học phí, Gym, Netflix...',
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: _teal, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _teal.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _teal, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên';
                  final exists = widget.rows.any((r) =>
                      (r['category'] as String?)?.toLowerCase() == v.trim().toLowerCase());
                  final existsExtra = _extraRows.any((r) =>
                      (r['category'] as String?)?.toLowerCase() == v.trim().toLowerCase());
                  if (exists || existsExtra) return 'Tên này đã tồn tại';
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  hintText: 'VD: 500000',
                  suffixText: 'đ',
                  suffixStyle: const TextStyle(color: _teal, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.payments_outlined, color: _teal, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _teal.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _teal, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập số tiền';
                  if ((int.tryParse(v) ?? 0) <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final name = nameCtrl.text.trim();
                      final amt  = int.tryParse(amountCtrl.text) ?? 0;
                      setState(() {
                        _extraRows.add({'category': name, 'amount': amt});
                        _extraCtrls[name] = TextEditingController(text: amt.toString());
                      });
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: const Text('Thêm khoản chi',
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: Column(children: [
        _buildHeader(isDark),
        _buildIncomeSection(isDark),
        _buildTotalBar(isDark),
        _buildHintBanner(isDark),
        Expanded(child: _buildList(isDark)),
        _buildBottomBar(isDark),
      ])),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, null),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Chỉnh sửa kế hoạch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Nhập số tiền bạn muốn cho từng mục',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ])),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Đặt lại về mặc định?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                content: Text('Tất cả số tiền sẽ về giá trị AI đã tạo.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context),
                      child: Text('Huỷ', style: TextStyle(color: Colors.grey[500]))),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(context); _reset(); },
                    style: ElevatedButton.styleFrom(backgroundColor: _teal, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Đặt lại', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, size: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Mặc định', style: TextStyle(fontSize: 11,
                  color: isDark ? Colors.grey[300] : Colors.grey[600])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildIncomeSection(bool isDark) {
    return AnimatedBuilder(
      animation: _incomeCtrl,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => setState(() => _showIncomeField = !_showIncomeField),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 18, color: _teal),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Thu nhập / tháng của bạn',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(
                    _income > 0 ? '${_fmt(_income)} đ' : 'Chưa nhập',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _income > 0 ? _teal : Colors.grey[400]),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _showIncomeField ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ]),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _incomeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'VD: 12000000',
                    suffixText: 'đ',
                    suffixStyle: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 16),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF3A3A3A) : _teal.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _teal.withOpacity(0.3))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _teal.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _teal, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              crossFadeState: _showIncomeField ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildTotalBar(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([..._ctrls.values, _incomeCtrl]),
      builder: (_, __) {
        final total     = _total;
        final income    = _income;
        final remaining = income - total;
        final hasIncome = income > 0;
        final isOver    = hasIncome && remaining < 0;
        final isOk      = hasIncome && remaining >= 0;

        final List<Color> gradColors = isOver
            ? [_red, const Color(0xFFFF6B6B)]
            : isOk ? [_green, const Color(0xFF81C784)]
            : [_teal, _purple];

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradColors),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Row(children: [
              Icon(isOver ? Icons.warning_amber_rounded
                  : isOk ? Icons.check_circle_rounded : Icons.calculate_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tổng kế hoạch chi tiêu',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text('${_fmt(total)} đ / tháng',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ])),
              const Icon(Icons.sync_rounded, color: Colors.white70, size: 16),
            ]),
            if (hasIncome) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Expanded(child: _miniStat('Thu nhập', '${_fmt(income)} đ', Colors.white)),
                  Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _miniStat('Chi tiêu', '${_fmt(total)} đ', Colors.white)),
                  Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _miniStat(
                    isOver ? 'Vượt quá' : 'Còn lại',
                    '${_fmt(remaining.abs())} đ',
                    isOver ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
                  )),
                ]),
              ),
            ],
          ]),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7))),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _buildHintBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF0FAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Đây là tổng chi tiêu do app đề xuất, trong đó đã có khoản Tiết kiệm. '
            'Bạn có thể thêm những khoản chi mà bạn mong muốn — '
            'đó là cách phù hợp nhất để kế hoạch sát với thực tế của bạn! 😊',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? Colors.grey[300] : const Color(0xFF2C7873),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildList(bool isDark) {
    final allItems = [
      ...widget.rows.asMap().entries.map((e) => _buildOrigRow(e.key, e.value, isDark)),
      ..._extraRows.asMap().entries.map((e) => _buildExtraRow(e.key, e.value, isDark)),
      _buildAddButton(isDark),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: allItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => allItems[i],
    );
  }

  Widget _buildOrigRow(int i, Map<String, dynamic> row, bool isDark) {
    final category = row['category'] as String? ?? '';
    final origAmt  = (row['amount'] as num?)?.toInt() ?? 0;
    final note     = row['note'] as String? ?? '';
    final color    = _rowColors[i % _rowColors.length];
    final ctrl     = _ctrls[category]!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(category,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('Gốc: ${_fmt(origAmt)}đ',
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.only(left: 18),
                child: Text(note, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
          ],
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  suffixText: 'đ',
                  suffixStyle: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3A3A) : color.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => ctrl.text = origAmt.toString()),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(Icons.restart_alt_rounded, size: 18, color: color),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildExtraRow(int i, Map<String, dynamic> extra, bool isDark) {
    final category = extra['category'] as String? ?? '';
    final color    = _rowColors[(widget.rows.length + i) % _rowColors.length];
    final ctrl     = _extraCtrls[category]!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(category,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: _orange.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: const Text('+ Tự thêm',
                  style: TextStyle(fontSize: 10, color: _orange, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _extraCtrls[category]?.dispose();
                  _extraCtrls.remove(category);
                  _extraRows.removeWhere((r) => r['category'] == category);
                });
              },
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: _red),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              suffixText: 'đ',
              suffixStyle: const TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 16),
              filled: true,
              fillColor: isDark ? const Color(0xFF3A3A3A) : _orange.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _orange.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _orange.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _orange, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showAddDialog(isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _teal.withOpacity(0.4), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: _teal.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, size: 18, color: _teal),
          ),
          const SizedBox(width: 8),
          const Text('Thêm khoản chi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _teal)),
        ]),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, null),
          child: Container(
            width: 48, height: 52,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Icon(Icons.close_rounded,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _save,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_teal, _purple]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _teal.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.save_alt_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Lưu & Quay lại',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}