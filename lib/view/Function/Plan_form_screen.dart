// lib/view/Function/Plan/plan_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'plan_form_data.dart';
import 'plan_form_widgets.dart';

class PlanFormScreen extends StatefulWidget {
  final void Function(
      Map<String, dynamic> plan,
      Map<String, dynamic> formData) onPlanCreated;
  final bool isGenerating;
  final Future<void> Function(Map<String, dynamic> formData) onGenerate;
  final VoidCallback? onBackToIntro;

  const PlanFormScreen({
    Key? key,
    required this.onPlanCreated,
    required this.isGenerating,
    required this.onGenerate,
    this.onBackToIntro,
  }) : super(key: key);

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  // Page 1
  String? _occupation;
  final _customOccupationCtrl = TextEditingController();
  String? _ageRange;
  String? _maritalStatus;

  // Page 2
  String? _city;
  String _citySearch = '';
  String? _livingStatus;

  // Page 3
  String? _incomeStability;
  final List<String> _incomeSources = [];
  String? _hasChildren;
  String? _transport;
  String? _eatingHabit;

  // Page 4
  final List<String> _savingGoals = [];
  bool _hasDebt    = false;
  bool _hasSavings = false;
  final _targetSalaryCtrl  = TextEditingController();
  final _currentSalaryCtrl = TextEditingController(); // ✅ Thu nhập hiện tại
  final _debtCtrl         = TextEditingController();
  String? _currentSpending;
  String? _insurance;

  @override
  void dispose() {
    _pageController.dispose();
    _customOccupationCtrl.dispose();
    _targetSalaryCtrl.dispose();
    _currentSalaryCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  String _spendingLabel(String? v) {
    const m = {
      'under5': 'Dưới 5 triệu/tháng',
      '5to10':  '5 - 10 triệu/tháng',
      '10to15': '10 - 15 triệu/tháng',
      'over15': 'Trên 15 triệu/tháng',
    };
    return m[v ?? ''] ?? 'Chưa rõ';
  }

  String _insuranceLabel(String? v) {
    const m = {
      'company': 'Có BHYT qua công ty',
      'self':    'Tự mua bảo hiểm',
      'none':    'Chưa có bảo hiểm',
    };
    return m[v ?? ''] ?? 'Chưa rõ';
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
    final childrenMap  = {'none': 'Chưa có con', 'one': 'Có 1 con', 'two_plus': 'Có 2 con trở lên'};
    final transportMap = {'motorbike': 'Xe máy', 'car': 'Ô tô', 'grab': 'Grab / xe buýt', 'walk': 'Đi bộ / xe đạp'};
    final eatingMap    = {'cook': 'Hay nấu ăn tại nhà', 'eatout': 'Hay ăn ngoài', 'mixed': '50% nấu, 50% ăn ngoài'};

    final formData = {
      'occupation':       _occupation ?? 'Employee',
      'customOccupation': _customOccupationCtrl.text.trim(),
      'ageRange':         _ageRange       ?? '22-30',
      'maritalStatus':    _maritalStatus  ?? 'Single',
      'city':             _city           ?? 'HCM',
      'livingStatus':     _livingStatus   ?? 'Renting',
      'incomeStability':  _incomeStability ?? 'Stable',
      'incomeSources':    List<String>.from(_incomeSources),
      'currentSalary':    double.tryParse(_currentSalaryCtrl.text.replaceAll(',', '')) ?? 0,
      'targetSalary':     double.tryParse(_targetSalaryCtrl.text.replaceAll(',', '')) ?? 0,
      'hasDebt':          _hasDebt,
      'debtAmount':       double.tryParse(_debtCtrl.text.replaceAll(',', '')) ?? 0,
      'hasSavings':       _hasSavings,
      'savingGoals':      List<String>.from(_savingGoals),
      'savingGoal':       _savingGoals.isNotEmpty ? _savingGoals.first : 'Emergency',
      'hasChildren':      childrenMap[_hasChildren ?? 'none'] ?? 'Chưa có con',
      'transport':        transportMap[_transport ?? 'motorbike'] ?? 'Xe máy',
      'eatingHabit':      eatingMap[_eatingHabit ?? 'mixed'] ?? '50% nấu, 50% ăn ngoài',
      'currentSpending':  _spendingLabel(_currentSpending),
      'insurance':        _insuranceLabel(_insurance),
    };
    widget.onGenerate(formData);
  }

  List<Map<String, String>> get _filteredProvinces {
    if (_citySearch.isEmpty) return List<Map<String,String>>.from(PlanFormData.provinces);
    final q = _citySearch.toLowerCase();
    return PlanFormData.provinces
        .where((p) => p['l']!.toLowerCase().contains(q))
        .toList().cast<Map<String,String>>();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titles = ['👤 Bạn là ai?', '📍 Bạn ở đâu?', '💼 Công việc & sinh hoạt', '🎯 Mục tiêu'];

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
            _page3WorkLifestyle(isDark),
            _page4GoalsFinance(isDark),
          ],
        ),
      ),
      _buildNavButtons(isDark),
    ]);
  }

  // ── Loading ──────────────────────────────────────────────
  Widget _buildGenerating() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: _teal.withOpacity(0.1), shape: BoxShape.circle),
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

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader(String title, bool isDark) {
    final isFirstPage = _currentPage == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Back arrow — chỉ hiện bước 1
        if (isFirstPage && widget.onBackToIntro != null) ...[
          GestureDetector(
            onTap: widget.onBackToIntro,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // Title + step
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
          Text('Bước ${_currentPage + 1} / $_totalPages',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ])),

        // Nút tạo plan tự do
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/buddy-chat'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _teal.withOpacity(0.5), width: 1.2),
              boxShadow: [BoxShadow(color: _teal.withOpacity(0.08),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 13, color: _teal),
              const SizedBox(width: 5),
              Text('Tạo plan tự do', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _teal)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Progress bar ─────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: List.generate(_totalPages, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < _totalPages - 1 ? 6 : 0),
          height: 4,
          decoration: BoxDecoration(
            color: i <= _currentPage ? _teal : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ))),
    );
  }

  // ── Nav buttons ──────────────────────────────────────────
  Widget _buildNavButtons(bool isDark) {
    final isLast = _currentPage == _totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
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
        Expanded(child: GestureDetector(
          onTap: _next,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_teal, _purple]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(
              isLast ? '🚀  Tạo kế hoạch' : 'Tiếp theo  →',
              style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w600),
            )),
          ),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 1 — WHO
  // ═══════════════════════════════════════════════════════
  Widget _page1Who(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        PlanFormWidgets.label('Nghề nghiệp của bạn'),
        PlanFormWidgets.grid(
          opts: PlanFormData.occupations.map((e) => Map<String,String>.from(e)).toList(),
          selected: _occupation,
          onSelect: (v) => setState(() => _occupation = v),
          isDark: isDark, aspectRatio: 2.0,
        ),
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
          opts: PlanFormData.ageRanges.map((e) => Map<String,String>.from(e)).toList(),
          selected: _ageRange,
          onSelect: (v) => setState(() => _ageRange = v),
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        PlanFormWidgets.label('Tình trạng hôn nhân'),
        PlanFormWidgets.row(
          opts: PlanFormData.maritalStatuses.map((e) => Map<String,String>.from(e)).toList(),
          selected: _maritalStatus,
          onSelect: (v) => setState(() => _maritalStatus = v),
          isDark: isDark,
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 2 — WHERE
  // ═══════════════════════════════════════════════════════
  Widget _page2Where(bool isDark) {
    final filtered = _filteredProvinces;
    final regions  = ['south', 'central', 'highland', 'north', 'other'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: TextField(
          onChanged: (v) => setState(() => _citySearch = v),
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Tìm tỉnh / thành phố...',
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_citySearch.isEmpty) ...[
            ...regions.map((region) {
              final group = filtered.where((p) => p['r'] == region).toList();
              if (group.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(PlanFormData.regionLabels[region] ?? region,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.grey[500])),
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
            opts: PlanFormData.livingStatuses.map((e) => Map<String,String>.from(e)).toList(),
            selected: _livingStatus,
            onSelect: (v) => setState(() => _livingStatus = v),
            isDark: isDark, aspectRatio: 2.3,
          ),
          const SizedBox(height: 16),
        ]),
      )),
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
            color: active ? _teal.withOpacity(0.12)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? _teal : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: active ? 2 : 1),
          ),
          child: Text(p['l']!, style: TextStyle(fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? _teal : null)),
        ),
      );
    }).toList());
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 3 — WORK & LIFESTYLE
  // ═══════════════════════════════════════════════════════
  Widget _page3WorkLifestyle(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        PlanFormWidgets.label('Thu nhập có ổn định không?'),
        PlanFormWidgets.grid(
          opts: PlanFormData.incomeStabilities.map((e) => Map<String,String>.from(e)).toList(),
          selected: _incomeStability,
          onSelect: (v) => setState(() => _incomeStability = v),
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        PlanFormWidgets.label('Nguồn thu nhập (chọn nhiều)'),
        PlanFormWidgets.chips(
          opts: PlanFormData.incomeSources,
          selected: _incomeSources,
          onToggle: (v) => setState(() => _incomeSources.contains(v)
              ? _incomeSources.remove(v) : _incomeSources.add(v)),
          isDark: isDark,
        ),
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 16),
        PlanFormWidgets.label('Bạn có con chưa?'),
        _row3(
          options: [
            {'v': 'none',     'i': '👤', 'l': 'Chưa có'},
            {'v': 'one',      'i': '👶', 'l': 'Có 1 con'},
            {'v': 'two_plus', 'i': '👨‍👩‍👧‍👦', 'l': '2 con+'},
          ],
          selected: _hasChildren,
          onSelect: (v) => setState(() => _hasChildren = v),
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        PlanFormWidgets.label('Phương tiện đi lại chính'),
        _row4(
          options: [
            {'v': 'motorbike', 'i': '🏍️', 'l': 'Xe máy'},
            {'v': 'car',       'i': '🚗',  'l': 'Ô tô'},
            {'v': 'grab',      'i': '📱',  'l': 'Grab/buýt'},
            {'v': 'walk',      'i': '🚶',  'l': 'Đi bộ'},
          ],
          selected: _transport,
          onSelect: (v) => setState(() => _transport = v),
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        PlanFormWidgets.label('Thói quen ăn uống'),
        _row3(
          options: [
            {'v': 'cook',   'i': '🍳', 'l': 'Hay nấu nhà'},
            {'v': 'mixed',  'i': '🍱', 'l': '50/50'},
            {'v': 'eatout', 'i': '🍜', 'l': 'Hay ăn ngoài'},
          ],
          selected: _eatingHabit,
          onSelect: (v) => setState(() => _eatingHabit = v),
          isDark: isDark,
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 4 — GOALS & FINANCE
  // ═══════════════════════════════════════════════════════
  Widget _page4GoalsFinance(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),

        // Mục tiêu
        Row(children: [
          Expanded(child: PlanFormWidgets.label('Mục tiêu tài chính')),
          if (_savingGoals.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20)),
              child: Text('${_savingGoals.length} đã chọn',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
        ]),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Chọn một hoặc nhiều mục tiêu',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        PlanFormWidgets.multiGrid(
          opts: PlanFormData.savingGoals.map((e) => Map<String,String>.from(e)).toList(),
          selected: _savingGoals,
          onToggle: (v) => setState(() => _savingGoals.contains(v)
              ? _savingGoals.remove(v) : _savingGoals.add(v)),
          isDark: isDark,
        ),

        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 14),

        // Chi tiêu hiện tại
        PlanFormWidgets.label('Chi tiêu thực tế hiện tại / tháng'),
        _row4(
          options: [
            {'v': 'under5',  'i': '💵', 'l': 'Dưới\n5 triệu'},
            {'v': '5to10',   'i': '💰', 'l': '5 - 10\ntriệu'},
            {'v': '10to15',  'i': '💳', 'l': '10 - 15\ntriệu'},
            {'v': 'over15',  'i': '💎', 'l': 'Trên\n15 triệu'},
          ],
          selected: _currentSpending,
          onSelect: (v) => setState(() => _currentSpending = v),
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Bảo hiểm
        PlanFormWidgets.label('Bạn có bảo hiểm y tế không?'),
        _row3(
          options: [
            {'v': 'company', 'i': '🏢', 'l': 'BHYT\ncông ty'},
            {'v': 'self',    'i': '🛡️', 'l': 'Tự mua\nbảo hiểm'},
            {'v': 'none',    'i': '❌',  'l': 'Chưa\ncó'},
          ],
          selected: _insurance,
          onSelect: (v) => setState(() => _insurance = v),
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // ✅ Thu nhập hiện tại
        PlanFormWidgets.label('Thu nhập hiện tại / tháng'),
        _moneyFieldWithSub(
          controller: _currentSalaryCtrl,
          hint: 'VD: 10,000,000',
          subText: 'Giúp hệ thống đề xuất kế hoạch sát thực tế hơn',
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Thu nhập mong muốn
        PlanFormWidgets.label('Thu nhập mong muốn / tháng'),
        _moneyFieldWithSub(
          controller: _targetSalaryCtrl,
          hint: 'VD: 15,000,000',
          subText: 'Để trống nếu chưa có mục tiêu cụ thể',
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Nợ
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

        // Tiết kiệm
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

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _teal.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Text('📋', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Hệ thống sẽ đề xuất mức thu nhập và lập kế hoạch chi tiêu phù hợp dựa trên thông tin của bạn.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }

  // ── Helper widgets ───────────────────────────────────────
  Widget _row3({
    required List<Map<String,String>> options,
    required String? selected,
    required Function(String) onSelect,
    required bool isDark,
  }) {
    return Row(children: options.map((o) {
      final active = selected == o['v'];
      final isLast = o == options.last;
      return Expanded(child: GestureDetector(
        onTap: () => onSelect(o['v']!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(right: isLast ? 0 : 10),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? _teal.withOpacity(0.1)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? _teal : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: active ? 2 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(o['i']!, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(o['l']!, style: TextStyle(fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? _teal : null),
                textAlign: TextAlign.center),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _row4({
    required List<Map<String,String>> options,
    required String? selected,
    required Function(String) onSelect,
    required bool isDark,
  }) {
    return Row(children: options.map((o) {
      final active = selected == o['v'];
      final isLast = o == options.last;
      return Expanded(child: GestureDetector(
        onTap: () => onSelect(o['v']!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(right: isLast ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _teal.withOpacity(0.1)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? _teal : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: active ? 2 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(o['i']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(o['l']!, style: TextStyle(fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? _teal : null),
                textAlign: TextAlign.center),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _moneyFieldWithSub({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    String? subText,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: 'đ',
          suffixStyle: const TextStyle(color: _teal, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      if (subText != null) ...[
        const SizedBox(height: 6),
        Text(subText, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    ]);
  }
}