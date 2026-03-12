// lib/view/Function/spending_rule_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpendingRuleView extends StatefulWidget {
  const SpendingRuleView({Key? key}) : super(key: key);

  @override
  State<SpendingRuleView> createState() => _SpendingRuleViewState();
}

class _SpendingRuleViewState extends State<SpendingRuleView> {
  bool _isLoading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;

  double _needs = 0;
  double _wants = 0;
  double _savings = 0;

  Map<String, double> _needsDetail = {};
  Map<String, double> _wantsDetail = {};
  Map<String, double> _savingsDetail = {};

  // ✅ Tỷ lệ có thể chỉnh - mặc định 50/30/20
  double _needsPercent = 50;
  double _wantsPercent = 30;
  double _savingsPercent = 20;

  // Temp values khi đang chỉnh trong bottom sheet
  double _tempNeeds = 50;
  double _tempWants = 30;
  double _tempSavings = 20;

  static const List<String> _needsCategories = [
    'food', 'groceries', 'housing', 'rent', 'utilities',
    'medicine', 'healthcare', 'health', 'medical',
    'transport', 'transportation', 'education',
    'electricity', 'water', 'gas', 'internet', 'phone',
    'nhà ở', 'ăn uống', 'y tế', 'đi lại', 'học phí',
    'tiền điện', 'tiền nước', 'tiền nhà', 'tiền trọ',
  ];

  static const List<String> _wantsCategories = [
    'entertainment', 'shopping', 'dining', 'restaurant',
    'coffee', 'travel', 'gym', 'sports', 'beauty',
    'clothing', 'fashion', 'gifts', 'hobby',
    'giải trí', 'mua sắm', 'du lịch', 'thể thao',
    'làm đẹp', 'quà tặng', 'cafe', 'cà phê',
  ];

  static const List<String> _savingsCategories = [
    'savings', 'investment', 'insurance', 'emergency',
    'tiết kiệm', 'đầu tư', 'bảo hiểm', 'dự phòng',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _classifyCategory(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    for (final cat in _savingsCategories) {
      if (lower.contains(cat)) return 'savings';
    }
    for (final cat in _needsCategories) {
      if (lower.contains(cat)) return 'needs';
    }
    for (final cat in _wantsCategories) {
      if (lower.contains(cat)) return 'wants';
    }
    return 'wants';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get();

      double totalIncome = 0, totalExpense = 0;
      double needs = 0, wants = 0, savings = 0;
      Map<String, double> needsDetail = {};
      Map<String, double> wantsDetail = {};
      Map<String, double> savingsDetail = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isIncome =
            data['type'] == 'income' || data['isIncome'] == true;
        final amount = _toDouble(data['amount']).abs();
        final categoryName =
            (data['categoryName'] ?? data['category'] ?? 'Other').toString();

        if (isIncome) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
          final group = _classifyCategory(categoryName);
          if (group == 'needs') {
            needs += amount;
            needsDetail[categoryName] =
                (needsDetail[categoryName] ?? 0) + amount;
          } else if (group == 'savings') {
            savings += amount;
            savingsDetail[categoryName] =
                (savingsDetail[categoryName] ?? 0) + amount;
          } else {
            wants += amount;
            wantsDetail[categoryName] =
                (wantsDetail[categoryName] ?? 0) + amount;
          }
        }
      }

      setState(() {
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _needs = needs;
        _wants = wants;
        _savings = savings;
        _needsDetail = needsDetail;
        _wantsDetail = wantsDetail;
        _savingsDetail = savingsDetail;
        _isLoading = false;
      });
    } catch (e) {
      print('[SpendingRule] Error: $e');
      setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  // ✅ Bottom sheet chỉnh tỷ lệ với slider
  void _showEditRatioSheet() {
    _tempNeeds = _needsPercent;
    _tempWants = _wantsPercent;
    _tempSavings = _savingsPercent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final total = _tempNeeds + _tempWants + _tempSavings;
            final isValid = total.round() == 100;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),

                  // Header row
                  Row(
                    children: [
                      const Text('⚙️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Chỉnh tỷ lệ phân bổ',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87)),
                      ),
                      // Preset buttons
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          _tempNeeds = 50;
                          _tempWants = 30;
                          _tempSavings = 20;
                        }),
                        child: _presetChip('50/30/20'),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          _tempNeeds = 60;
                          _tempWants = 20;
                          _tempSavings = 20;
                        }),
                        child: _presetChip('60/20/20'),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          _tempNeeds = 70;
                          _tempWants = 20;
                          _tempSavings = 10;
                        }),
                        child: _presetChip('70/20/10'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Tổng 3 nhóm phải bằng 100%',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 20),

                  // Visual ratio bar
                  _buildRatioBar(_tempNeeds, _tempWants, _tempSavings),
                  const SizedBox(height: 24),

                  // Needs
                  _buildSliderRow(
                    emoji: '🏠',
                    label: 'Thiết yếu',
                    value: _tempNeeds,
                    color: const Color(0xFF00CED1),
                    isDark: isDark,
                    onChanged: (val) => setSheetState(() {
                      _tempNeeds = val.roundToDouble();
                      double rem = 100 - _tempNeeds - _tempWants;
                      if (rem < 0) {
                        _tempWants =
                            (_tempWants + rem).clamp(0, 100);
                        rem = 100 - _tempNeeds - _tempWants;
                      }
                      _tempSavings = rem.clamp(0, 100);
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Wants
                  _buildSliderRow(
                    emoji: '🎉',
                    label: 'Cá nhân',
                    value: _tempWants,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    onChanged: (val) => setSheetState(() {
                      _tempWants = val.roundToDouble();
                      double rem = 100 - _tempNeeds - _tempWants;
                      if (rem < 0) {
                        _tempNeeds =
                            (_tempNeeds + rem).clamp(0, 100);
                        rem = 100 - _tempNeeds - _tempWants;
                      }
                      _tempSavings = rem.clamp(0, 100);
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Savings
                  _buildSliderRow(
                    emoji: '💰',
                    label: 'Tiết kiệm',
                    value: _tempSavings,
                    color: Colors.green,
                    isDark: isDark,
                    onChanged: (val) => setSheetState(() {
                      _tempSavings = val.roundToDouble();
                      double rem = 100 - _tempNeeds - _tempSavings;
                      if (rem < 0) {
                        _tempNeeds =
                            (_tempNeeds + rem).clamp(0, 100);
                        rem = 100 - _tempNeeds - _tempSavings;
                      }
                      _tempWants = rem.clamp(0, 100);
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Total indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isValid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isValid ? Colors.green : Colors.red),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isValid
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color: isValid ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isValid
                              ? 'Tổng: ${total.toInt()}% ✅ Hợp lệ'
                              : 'Tổng: ${total.toInt()}% — cần đúng 100%',
                          style: TextStyle(
                              color: isValid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isValid
                              ? () {
                                  setState(() {
                                    _needsPercent = _tempNeeds;
                                    _wantsPercent = _tempWants;
                                    _savingsPercent = _tempSavings;
                                  });
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00CED1),
                            disabledBackgroundColor:
                                Colors.grey[300],
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Áp dụng',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _presetChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00CED1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00CED1).withOpacity(0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF00CED1),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRatioBar(double needs, double wants, double savings) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (needs > 0)
                Flexible(
                  flex: needs.toInt(),
                  child: Container(
                    height: 30,
                    color: const Color(0xFF00CED1),
                    alignment: Alignment.center,
                    child: Text('${needs.toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              if (wants > 0)
                Flexible(
                  flex: wants.toInt(),
                  child: Container(
                    height: 30,
                    color: const Color(0xFF8B5CF6),
                    alignment: Alignment.center,
                    child: Text('${wants.toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              if (savings > 0)
                Flexible(
                  flex: savings.toInt(),
                  child: Container(
                    height: 30,
                    color: Colors.green,
                    alignment: Alignment.center,
                    child: Text('${savings.toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendDot(const Color(0xFF00CED1), '🏠 Thiết yếu'),
            _legendDot(const Color(0xFF8B5CF6), '🎉 Cá nhân'),
            _legendDot(Colors.green, '💰 Tiết kiệm'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10, height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSliderRow({
    required String emoji,
    required String label,
    required double value,
    required Color color,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              overlayColor: color.withOpacity(0.1),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ),
        Container(
          width: 46,
          alignment: Alignment.center,
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toInt()}%',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF2C2C2C) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quy tắc phân bổ chi tiêu',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              '${_needsPercent.toInt()}% / ${_wantsPercent.toInt()}% / ${_savingsPercent.toInt()}%',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF00CED1)),
            ),
          ],
        ),
        actions: [
          // ✅ Nút Chỉnh tỷ lệ
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: _showEditRatioSheet,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF00CED1).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded,
                        color: Color(0xFF00CED1), size: 16),
                    SizedBox(width: 4),
                    Text('Chỉnh',
                        style: TextStyle(
                            color: Color(0xFF00CED1),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF00CED1)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF00CED1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderCard(isDark),
                  const SizedBox(height: 16),
                  _buildSummaryBars(isDark),
                  const SizedBox(height: 16),
                  _buildGroupCard(
                    isDark: isDark,
                    emoji: '🏠',
                    title: 'Nhu Cầu Thiết Yếu',
                    subtitle: 'Nhà ở, ăn uống, y tế, đi lại...',
                    targetPercent: _needsPercent,
                    actual: _needs,
                    detail: _needsDetail,
                    color: const Color(0xFF00CED1),
                  ),
                  const SizedBox(height: 12),
                  _buildGroupCard(
                    isDark: isDark,
                    emoji: '🎉',
                    title: 'Cá Nhân & Giải Trí',
                    subtitle: 'Mua sắm, giải trí, du lịch...',
                    targetPercent: _wantsPercent,
                    actual: _wants,
                    detail: _wantsDetail,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  _buildGroupCard(
                    isDark: isDark,
                    emoji: '💰',
                    title: 'Tiết Kiệm & Đầu Tư',
                    subtitle: 'Tiết kiệm, đầu tư, bảo hiểm...',
                    targetPercent: _savingsPercent,
                    actual: _savings,
                    detail: _savingsDetail,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildAdviceCard(isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân tích tháng này',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_formatMoney(_totalIncome),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const Text('Tổng thu nhập',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _headerStat('Chi tiêu',
                      _formatMoney(_totalExpense), Colors.red[200]!)),
              Expanded(
                  child: _headerStat(
                      'Còn lại',
                      _formatMoney(_totalIncome - _totalExpense),
                      Colors.green[200]!)),
              Expanded(
                  child: _headerStat(
                      '% Chi',
                      '${_totalIncome > 0 ? ((_totalExpense / _totalIncome) * 100).toStringAsFixed(1) : 0}%',
                      Colors.yellow[200]!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildSummaryBars(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng quan phân bổ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF00CED1),
                    Color(0xFF8B5CF6)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_needsPercent.toInt()}/${_wantsPercent.toInt()}/${_savingsPercent.toInt()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryBar(
              '🏠 Thiết yếu (${_needsPercent.toInt()}%)',
              _needs,
              _totalIncome * _needsPercent / 100,
              const Color(0xFF00CED1),
              isDark),
          const SizedBox(height: 12),
          _summaryBar(
              '🎉 Cá nhân (${_wantsPercent.toInt()}%)',
              _wants,
              _totalIncome * _wantsPercent / 100,
              const Color(0xFF8B5CF6),
              isDark),
          const SizedBox(height: 12),
          _summaryBar(
              '💰 Tiết kiệm (${_savingsPercent.toInt()}%)',
              _savings,
              _totalIncome * _savingsPercent / 100,
              Colors.green,
              isDark),
        ],
      ),
    );
  }

  Widget _summaryBar(String label, double actual, double target,
      Color color, bool isDark) {
    final percent =
        target > 0 ? (actual / target).clamp(0.0, 1.5) : 0.0;
    final isOver = actual > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87)),
            Text('${_formatMoney(actual)} / ${_formatMoney(target)}',
                style: TextStyle(
                    fontSize: 11,
                    color: isOver ? Colors.red : Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                  color:
                      isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(5)),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                    color: isOver ? Colors.red : color,
                    borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          isOver
              ? '⚠️ Vượt ${_formatMoney(actual - target)}'
              : '✅ Còn ${_formatMoney(target - actual)}',
          style: TextStyle(
              fontSize: 11,
              color: isOver ? Colors.red : Colors.green),
        ),
      ],
    );
  }

  Widget _buildGroupCard({
    required bool isDark,
    required String emoji,
    required String title,
    required String subtitle,
    required double targetPercent,
    required double actual,
    required Map<String, double> detail,
    required Color color,
  }) {
    final target = _totalIncome * targetPercent / 100;
    final isOver = actual > target;
    final actualPercent = _totalIncome > 0
        ? (actual / _totalIncome * 100).toStringAsFixed(1)
        : '0';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
        border: isOver
            ? Border.all(
                color: Colors.red.withOpacity(0.5), width: 1.5)
            : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: (isOver ? Colors.red : color)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Thực tế: $actualPercent% | Mục tiêu: ${targetPercent.toInt()}%',
                  style: TextStyle(
                      fontSize: 11,
                      color: isOver ? Colors.red : color,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatMoney(actual),
                  style: TextStyle(
                      color: isOver ? Colors.red : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(isOver ? '⚠️ Vượt' : '✅ OK',
                  style: TextStyle(
                      fontSize: 11,
                      color: isOver ? Colors.red : Colors.green)),
            ],
          ),
          children: [
            if (detail.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Chưa có giao dịch nào',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 13)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(),
                    ...detail.entries.map((entry) {
                      final pct = actual > 0
                          ? (entry.value / actual * 100)
                              .toStringAsFixed(1)
                          : '0';
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(entry.key,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87))),
                            Text(
                                '${_formatMoney(entry.value)} ($pct%)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: color)),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard(bool isDark) {
    final needsTarget = _totalIncome * _needsPercent / 100;
    final wantsTarget = _totalIncome * _wantsPercent / 100;
    final savingsTarget = _totalIncome * _savingsPercent / 100;
    final List<String> advices = [];

    if (_needs > needsTarget) {
      advices.add(
          '⚠️ Chi thiết yếu vượt mục tiêu ${_needsPercent.toInt()}%. Xem lại tiền nhà hoặc ăn uống.');
    } else {
      advices.add('✅ Chi thiết yếu trong mức cho phép. Tốt lắm!');
    }
    if (_wants > wantsTarget) {
      advices.add(
          '⚠️ Giải trí/mua sắm vượt mục tiêu ${_wantsPercent.toInt()}%. Cân nhắc cắt giảm.');
    } else {
      advices.add('✅ Chi cá nhân hợp lý. Tiếp tục duy trì!');
    }
    if (_savings < savingsTarget) {
      advices.add(
          '💡 Cần tiết kiệm thêm ${_formatMoney(savingsTarget - _savings)} để đạt mục tiêu ${_savingsPercent.toInt()}%.');
    } else {
      advices.add('🎉 Tiết kiệm đạt mục tiêu! Xuất sắc!');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: Color(0xFF00CED1), size: 20),
              const SizedBox(width: 8),
              Text('Lời khuyên tháng này',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          ...advices
              .map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(a,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.white70
                                : Colors.black87)),
                  ))
              .toList(),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M₫';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K₫';
    }
    return '${amount.toStringAsFixed(0)}₫';
  }
}