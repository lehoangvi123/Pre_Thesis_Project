// lib/view/Function/Plan/plan_form_screen.dart
// Form 5 bước — thay thế _PlanFormScreen trong AnalysisView.dart

import 'package:flutter/material.dart';
import 'plan_form_data.dart';
import 'plan_form_widgets.dart';

class PlanFormScreen extends StatefulWidget {
  final void Function(
      Map<String, dynamic> plan,
      Map<String, dynamic> formData) onPlanCreated;
  final bool isGenerating;
  final Future<void> Function(Map<String, dynamic> formData) onGenerate;

  const PlanFormScreen({
    Key? key,
    required this.onPlanCreated,
    required this.isGenerating,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  // ── Form state ────────────────────────────────────────
  // Page 1 — WHO
  String? _occupation;
  final _customOccupationCtrl = TextEditingController(); // khi chọn "Khác"
  String? _ageRange;
  String? _maritalStatus;

  // Page 2 — WHERE
  String? _city;
  String _citySearch = '';
  String? _livingStatus;

  // Page 3 — WORK
  String? _incomeStability;
  final List<String> _incomeSources = [];

  // Page 4 — INCOME
  final _salaryCtrl       = TextEditingController();
  final _targetSalaryCtrl = TextEditingController();
  bool _hasDebt    = false;
  bool _hasSavings = false;
  final _debtCtrl  = TextEditingController();

  // Page 5 — GOALS (multi-select)
  final List<String> _savingGoals = [];

  @override
  void dispose() {
    _pageController.dispose();
    _customOccupationCtrl.dispose();
    _salaryCtrl.dispose();
    _targetSalaryCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _submit() {
    final formData = {
      'occupation':      _occupation ?? 'Employee',
      'customOccupation': _customOccupationCtrl.text.trim(),
      'ageRange':        _ageRange        ?? '22-30',
      'maritalStatus':   _maritalStatus   ?? 'Single',
      'city':            _city            ?? 'HCM',
      'livingStatus':    _livingStatus    ?? 'Renting',
      'incomeStability': _incomeStability ?? 'Stable',
      'incomeSources':   List<String>.from(_incomeSources),
      'currentSalary':   double.tryParse(_salaryCtrl.text.replaceAll(',', ''))       ?? 0,
      'targetSalary':    double.tryParse(_targetSalaryCtrl.text.replaceAll(',', '')) ?? 0,
      'hasDebt':         _hasDebt,
      'debtAmount':      double.tryParse(_debtCtrl.text.replaceAll(',', ''))         ?? 0,
      'hasSavings':      _hasSavings,
      'savingGoals':     List<String>.from(_savingGoals),   // multi-select
      // keep single for backward compat with prompt
      'savingGoal':      _savingGoals.isNotEmpty ? _savingGoals.first : 'Emergency',
    };
    widget.onGenerate(formData);
  }

  // ── Filtered provinces by search ─────────────────────
  List<Map<String, String>> get _filteredProvinces {
    if (_citySearch.isEmpty) return List<Map<String,String>>.from(PlanFormData.provinces);
    final q = _citySearch.toLowerCase();
    return PlanFormData.provinces
        .where((p) => p['l']!.toLowerCase().contains(q))
        .toList()
        .cast<Map<String,String>>();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titles = [
      '👤 Bạn là ai?',
      '📍 Bạn ở đâu?',
      '💼 Công việc',
      '💰 Thu nhập',
      '🎯 Mục tiêu',
    ];

    if (widget.isGenerating) return _buildGenerating();

    return Column(children: [
      _buildHeader(titles[_currentPage], isDark),
      _buildProgressBar(),
      Expanded(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            _page1Who(isDark),
            _page2Where(isDark),
            _page3Work(isDark),
            _page4Income(isDark),
            _page5Goals(isDark),
          ],
        ),
      ),
      _buildNavButtons(isDark),
    ]);
  }

  // ── Loading ───────────────────────────────────────────
  Widget _buildGenerating() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: _teal.withOpacity(0.1), shape: BoxShape.circle),
          child: const CircularProgressIndicator(color: _teal, strokeWidth: 3),
        ),
        const SizedBox(height: 20),
        const Text('Đang tạo kế hoạch...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Phân tích hoàn cảnh của bạn',
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ],
    ));
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          Text('Bước ${_currentPage + 1} / $_totalPages',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ])),
      ]),
    );
  }

  // ── Progress bar ──────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(_totalPages, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < _totalPages - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: i <= _currentPage ? _teal : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }

  // ── Nav buttons ───────────────────────────────────────
  Widget _buildNavButtons(bool isDark) {
    final isLast = _currentPage == _totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, -3))],
      ),
      child: Row(children: [
        if (_currentPage > 0) ...[
          GestureDetector(
            onTap: _prev,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GestureDetector(
            onTap: _next,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_teal, _purple]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(
                isLast ? '🚀  Tạo kế hoạch' : 'Tiếp theo  →',
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              )),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // PAGE 1 — WHO (nghề nghiệp + text field nếu "Khác")
  // ═══════════════════════════════════════════════════
  Widget _page1Who(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        PlanFormWidgets.label('Nghề nghiệp của bạn'),
        PlanFormWidgets.grid(
          opts: PlanFormData.occupations
              .map((e) => Map<String,String>.from(e)).toList(),
          selected: _occupation,
          onSelect: (v) => setState(() => _occupation = v),
          isDark: isDark,
          aspectRatio: 2.0,
        ),

        // Text field hiện ra khi chọn "Khác"
        if (_occupation == 'Other') ...[
          const SizedBox(height: 14),
          PlanFormWidgets.label('Nghề nghiệp của bạn là gì?'),
          PlanFormWidgets.textField(
            controller: _customOccupationCtrl,
            hint: 'VD: Kiến trúc sư, Bác sĩ nội trú...',
            isDark: isDark,
          ),
        ],

        const SizedBox(height: 18),
        PlanFormWidgets.label('Độ tuổi'),
        PlanFormWidgets.row(
          opts: PlanFormData.ageRanges
              .map((e) => Map<String,String>.from(e)).toList(),
          selected: _ageRange,
          onSelect: (v) => setState(() => _ageRange = v),
          isDark: isDark,
        ),

        const SizedBox(height: 18),
        PlanFormWidgets.label('Tình trạng hôn nhân'),
        PlanFormWidgets.row(
          opts: PlanFormData.maritalStatuses
              .map((e) => Map<String,String>.from(e)).toList(),
          selected: _maritalStatus,
          onSelect: (v) => setState(() => _maritalStatus = v),
          isDark: isDark,
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // PAGE 2 — WHERE (search + 64 tỉnh + living status)
  // ═══════════════════════════════════════════════════
  Widget _page2Where(bool isDark) {
    // Group by region
    final filtered = _filteredProvinces;
    final regions  = ['south', 'central', 'highland', 'north'];

    return Column(children: [
      // Search bar — fixed at top
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: TextField(
          onChanged: (v) => setState(() => _citySearch = v),
          style: TextStyle(fontSize: 14,
              color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Tìm tỉnh / thành phố...',
            prefixIcon: const Icon(Icons.search_rounded,
                color: Colors.grey, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),

      // Scrollable list
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // City selection — grouped by region (or flat if searching)
            if (_citySearch.isEmpty) ...[
              ...regions.map((region) {
                final group = filtered
                    .where((p) => p['r'] == region)
                    .toList();
                if (group.isEmpty) return const SizedBox.shrink();
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      PlanFormData.regionLabels[region] ?? region,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500]),
                    ),
                  ),
                  _cityGrid(group, isDark),
                  const SizedBox(height: 12),
                ]);
              }).toList(),
            ] else ...[
              _cityGrid(filtered, isDark),
            ],

            const SizedBox(height: 18),
            PlanFormWidgets.label('Tình trạng chỗ ở'),
            PlanFormWidgets.grid(
              opts: PlanFormData.livingStatuses
                  .map((e) => Map<String,String>.from(e)).toList(),
              selected: _livingStatus,
              onSelect: (v) => setState(() => _livingStatus = v),
              isDark: isDark,
              aspectRatio: 2.3,
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    ]);
  }

  Widget _cityGrid(List<Map<String,String>> cities, bool isDark) {
    return Wrap(spacing: 8, runSpacing: 8, children: cities.map((p) {
      final active = _city == p['v'];
      return GestureDetector(
        onTap: () => setState(() => _city = p['v']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? _teal.withOpacity(0.12)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active
                    ? _teal
                    : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: active ? 2 : 1),
          ),
          child: Text(p['l']!,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? _teal : null)),
        ),
      );
    }).toList());
  }

  // ═══════════════════════════════════════════════════
  // PAGE 3 — WORK
  // ═══════════════════════════════════════════════════
  Widget _page3Work(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        PlanFormWidgets.label('Thu nhập có ổn định không?'),
        PlanFormWidgets.grid(
          opts: PlanFormData.incomeStabilities
              .map((e) => Map<String,String>.from(e)).toList(),
          selected: _incomeStability,
          onSelect: (v) => setState(() => _incomeStability = v),
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        PlanFormWidgets.label('Nguồn thu nhập (chọn nhiều)'),
        PlanFormWidgets.chips(
          opts: PlanFormData.incomeSources,
          selected: _incomeSources,
          onToggle: (v) => setState(() =>
              _incomeSources.contains(v)
                  ? _incomeSources.remove(v)
                  : _incomeSources.add(v)),
          isDark: isDark,
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // PAGE 4 — INCOME
  // ═══════════════════════════════════════════════════
  Widget _page4Income(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        PlanFormWidgets.label('Thu nhập hiện tại / tháng'),
        PlanFormWidgets.moneyField(
            controller: _salaryCtrl, hint: 'VD: 10,000,000', isDark: isDark),

        const SizedBox(height: 16),
        PlanFormWidgets.label('Thu nhập mong muốn / tháng'),
        PlanFormWidgets.moneyField(
            controller: _targetSalaryCtrl, hint: 'VD: 20,000,000', isDark: isDark),

        const SizedBox(height: 16),
        PlanFormWidgets.label('Bạn có khoản nợ không?'),
        Row(children: [
          Expanded(child: PlanFormWidgets.boolCard(
              label: 'Không có nợ', icon: '✅',
              isActive: !_hasDebt,
              onTap: () => setState(() => _hasDebt = false), isDark: isDark)),
          const SizedBox(width: 12),
          Expanded(child: PlanFormWidgets.boolCard(
              label: 'Có khoản nợ', icon: '⚠️',
              isActive: _hasDebt,
              onTap: () => setState(() => _hasDebt = true), isDark: isDark)),
        ]),

        if (_hasDebt) ...[
          const SizedBox(height: 14),
          PlanFormWidgets.label('Tổng số tiền nợ'),
          PlanFormWidgets.moneyField(
              controller: _debtCtrl, hint: 'VD: 50,000,000', isDark: isDark),
        ],

        const SizedBox(height: 16),
        PlanFormWidgets.label('Bạn có tiền tiết kiệm không?'),
        Row(children: [
          Expanded(child: PlanFormWidgets.boolCard(
              label: 'Chưa có', icon: '🌱',
              isActive: !_hasSavings,
              onTap: () => setState(() => _hasSavings = false), isDark: isDark)),
          const SizedBox(width: 12),
          Expanded(child: PlanFormWidgets.boolCard(
              label: 'Đang có', icon: '💰',
              isActive: _hasSavings,
              onTap: () => setState(() => _hasSavings = true), isDark: isDark)),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // PAGE 5 — GOALS (multi-select)
  // ═══════════════════════════════════════════════════
  Widget _page5Goals(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),

        Row(children: [
          Expanded(child: PlanFormWidgets.label('Mục tiêu tài chính')),
          // Badge đếm số đã chọn
          if (_savingGoals.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _teal, borderRadius: BorderRadius.circular(20)),
              child: Text('${_savingGoals.length} đã chọn',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
        ]),

        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Chọn một hoặc nhiều mục tiêu',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),

        // Multi-select grid
        PlanFormWidgets.multiGrid(
          opts: PlanFormData.savingGoals
              .map((e) => Map<String,String>.from(e)).toList(),
          selected: _savingGoals,
          onToggle: (v) => setState(() =>
              _savingGoals.contains(v)
                  ? _savingGoals.remove(v)
                  : _savingGoals.add(v)),
          isDark: isDark,
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _teal.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Text('🤖', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Hệ thống sẽ tạo kế hoạch tài chính chi tiết dựa trên toàn bộ thông tin bạn vừa điền.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }
}