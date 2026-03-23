// lib/view/Function/Plan/spending_analysis_view.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpendingAnalysisView extends StatefulWidget {
  const SpendingAnalysisView({Key? key}) : super(key: key);

  @override
  State<SpendingAnalysisView> createState() => _SpendingAnalysisViewState();
}

class _SpendingAnalysisViewState extends State<SpendingAnalysisView>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  late AnimationController _animCtrl;
  late Animation<double>   _barAnim;

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);
  static const _orange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _barAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  // ── Màu cảnh báo theo % ───────────────────────────────
  Color _statusColor(double pct) {
    if (pct >= 100) return Colors.red[600]!;
    if (pct >= 90)  return Colors.red[400]!;
    if (pct >= 50)  return Colors.orange[600]!;
    return Colors.green[500]!;
  }

  String _statusLabel(double pct) {
    if (pct >= 100) return 'Vượt giới hạn!';
    if (pct >= 90)  return 'Nguy hiểm';
    if (pct >= 50)  return 'Cần chú ý';
    return 'Ổn định';
  }

  IconData _statusIcon(double pct) {
    if (pct >= 90) return Icons.warning_rounded;
    if (pct >= 50) return Icons.info_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final userId  = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(isDark),
          Expanded(
            child: userId == null
                ? const Center(child: Text('Vui lòng đăng nhập'))
                : StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || !snap.data!.exists) {
                        return const Center(
                            child: CircularProgressIndicator(color: _teal));
                      }
                      final data =
                          snap.data!.data() as Map<String, dynamic>? ?? {};
                      final income  = (data['totalIncome']  ?? 0).toDouble();
                      final expense = (data['totalExpense'] ?? 0).toDouble();
                      final balance = (data['balance']      ?? 0).toDouble();
                      final pct = income > 0
                          ? (expense / income * 100).clamp(0.0, 150.0)
                          : 0.0;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Status banner ──────────────
                            _statusBanner(pct, isDark),
                            const SizedBox(height: 20),

                            // ── 3 cards tổng quan ──────────
                            _summaryCards(income, expense, balance, isDark),
                            const SizedBox(height: 24),

                            // ── Biểu đồ thanh ngang ────────
                            _sectionTitle('📊 Biểu đồ thu chi', isDark),
                            const SizedBox(height: 12),
                            _barChart(income, expense, balance, pct, isDark),
                            const SizedBox(height: 24),

                            // ── Biểu đồ tròn (gauge) ───────
                            _sectionTitle('🎯 Tỷ lệ chi tiêu / thu nhập', isDark),
                            const SizedBox(height: 12),
                            _gaugeChart(pct, income, expense, isDark),
                            const SizedBox(height: 24),

                            // ── Pie chart danh mục ──────────
                            _sectionTitle('🥧 Chi tiêu theo danh mục', isDark),
                            const SizedBox(height: 12),
                            _categoryPieChart(userId, isDark),
                            const SizedBox(height: 24),

                            // ── Lời khuyên ─────────────────
                            _adviceCard(pct, income, expense, isDark),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Phân tích chi tiêu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Dựa trên số liệu thực tế của bạn',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ])),
      ]),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(title, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87));
  }

  // ── Status banner ────────────────────────────────────
  Widget _statusBanner(double pct, bool isDark) {
    final color = _statusColor(pct);
    final label = _statusLabel(pct);
    final icon  = _statusIcon(pct);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            pct >= 100
                ? 'Chi tiêu đã vượt thu nhập ${(pct - 100).toStringAsFixed(0)}%'
                : 'Đã chi ${pct.toStringAsFixed(1)}% so với thu nhập',
            style: TextStyle(fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20)),
          child: Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── 3 cards tổng quan ────────────────────────────────
  Widget _summaryCards(double income, double expense, double balance, bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _miniCard('Thu nhập', income,
            Colors.green[600]!, Icons.trending_up_rounded, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _miniCard('Chi tiêu', expense,
            Colors.red[500]!, Icons.trending_down_rounded, isDark)),
      ]),
      const SizedBox(height: 10),
      _miniCard('Số dư', balance,
          balance >= 0 ? _teal : Colors.red[600]!,
          Icons.account_balance_wallet_rounded, isDark,
          isFullWidth: true),
    ]);
  }

  Widget _miniCard(String title, double amount, Color color,
      IconData icon, bool isDark, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: isFullWidth
          ? Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(
                  fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]))),
              Text('${amount >= 0 ? '' : '-'}${_fmt(amount.abs())}đ',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold, color: color)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(title, style: TextStyle(fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ]),
              const SizedBox(height: 6),
              Text('${_fmt(amount)}đ', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ]),
    );
  }

  // ── Biểu đồ thanh ngang ──────────────────────────────
  Widget _barChart(double income, double expense, double balance,
      double pct, bool isDark) {
    final maxVal = [income, expense, balance.abs()].reduce(
            (a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    final bars = [
      _BarData('Thu nhập', income, Colors.green[500]!),
      _BarData('Chi tiêu', expense, _statusColor(pct)),
      _BarData('Số dư', balance.abs(),
          balance >= 0 ? _teal : Colors.red[400]!),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(children: bars.map((b) {
        final ratio = (b.value / maxVal).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(b.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[800])),
              Text('${_fmt(b.value)}đ', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: b.color)),
            ]),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio * _barAnim.value,
                  minHeight: 12,
                  backgroundColor:
                      isDark ? Colors.grey[700] : Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation(b.color),
                ),
              ),
            ),
          ]),
        );
      }).toList()),
    );
  }

  // ── Gauge chart (bán nguyệt) ─────────────────────────
  Widget _gaugeChart(double pct, double income, double expense, bool isDark) {
    final color = _statusColor(pct);
    final clampedPct = pct.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(children: [
        // Gauge
        AnimatedBuilder(
          animation: _barAnim,
          builder: (_, __) => CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _GaugePainter(
              percentage: clampedPct * _barAnim.value,
              color: color,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // % lớn ở giữa
        Text('${pct.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 28,
                fontWeight: FontWeight.bold, color: color)),
        Text('Chi tiêu / Thu nhập',
            style: TextStyle(fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 16),

        // Legend 3 mức
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _legendItem('< 50%', 'Ổn định', Colors.green[500]!),
          _legendItem('50-90%', 'Cần chú ý', Colors.orange[600]!),
          _legendItem('> 90%', 'Nguy hiểm', Colors.red[500]!),
        ]),
      ]),
    );
  }

  Widget _legendItem(String range, String label, Color color) {
    return Column(children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      Text(range, style: TextStyle(fontSize: 10, color: color,
          fontWeight: FontWeight.w600)),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
    ]);
  }

  // ── Lời khuyên ───────────────────────────────────────
  Widget _adviceCard(double pct, double income, double expense, bool isDark) {
    final color = _statusColor(pct);
    String title;
    String message;
    IconData icon;

    if (pct >= 100) {
      title   = 'Chi tiêu vượt thu nhập!';
      message = 'Bạn đang chi tiêu nhiều hơn thu nhập. Hãy xem lại các khoản chi không cần thiết và cắt giảm ngay để tránh thâm hụt tài chính.';
      icon    = Icons.warning_amber_rounded;
    } else if (pct >= 90) {
      title   = 'Cảnh báo chi tiêu!';
      message = 'Bạn đã dùng ${pct.toStringAsFixed(0)}% thu nhập. Chỉ còn ${_fmt(income - expense)}đ — hãy dừng các khoản chi không cần thiết.';
      icon    = Icons.warning_rounded;
    } else if (pct >= 50) {
      title   = 'Cần kiểm soát chi tiêu';
      message = 'Bạn đã dùng ${pct.toStringAsFixed(0)}% thu nhập. Hãy theo dõi sát hơn và cố gắng tiết kiệm ít nhất 20% thu nhập mỗi tháng.';
      icon    = Icons.info_rounded;
    } else {
      title   = 'Chi tiêu đang tốt!';
      message = 'Bạn chỉ dùng ${pct.toStringAsFixed(0)}% thu nhập — rất tốt! Hãy duy trì thói quen này và tăng dần tỷ lệ tiết kiệm.';
      icon    = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(
              fontSize: 13, height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700])),
        ])),
      ]),
    );
  }
  // ── Pie chart danh mục chi tiêu ──────────────────────
  Widget _categoryPieChart(String userId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }

        // Gom nhóm theo category
        final Map<String, double> catMap = {};
        for (final doc in snap.data!.docs) {
          final d       = doc.data() as Map<String, dynamic>;
          final cat     = (d['category'] as String? ?? 'Khác').trim();
          final amount  = (d['amount'] as num?)?.toDouble() ?? 0;
          catMap[cat]   = (catMap[cat] ?? 0) + amount;
        }

        if (catMap.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Center(child: Text('Chưa có giao dịch chi tiêu',
                style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          );
        }

        // Sắp xếp giảm dần, lấy top 6, còn lại gom vào "Khác"
        final sorted = catMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top    = sorted.take(6).toList();
        final others = sorted.skip(6).fold(0.0, (s, e) => s + e.value);
        if (others > 0) top.add(MapEntry('Khác', others));

        final total  = top.fold(0.0, (s, e) => s + e.value);

        // Màu cho từng slice
        const sliceColors = [
          Color(0xFF00CED1), Color(0xFFFF6B6B), Color(0xFF4ECDC4),
          Color(0xFFFFBE0B), Color(0xFF8B5CF6), Color(0xFFFF9800),
          Color(0xFF607D8B),
        ];

        final slices = top.asMap().entries.map((e) => _PieSlice(
          label:   e.value.key,
          value:   e.value.value,
          percent: total > 0 ? e.value.value / total * 100 : 0,
          color:   sliceColors[e.key % sliceColors.length],
        )).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          child: Column(children: [
            // Pie chart
            AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) => SizedBox(
                height: 200,
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _PieChartPainter(
                      slices: slices,
                      progress: _barAnim.value),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legend list
            ...slices.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 12, height: 12,
                    decoration: BoxDecoration(
                        color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(s.label,
                    style: TextStyle(fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[800]))),
                Text('${s.percent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: s.color)),
                const SizedBox(width: 8),
                Text('${_fmt(s.value)}đ',
                    style: TextStyle(fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ]),
            )).toList(),
          ]),
        );
      },
    );
  }
}

// ── Pie slice model ───────────────────────────────────
class _PieSlice {
  final String label;
  final double value;
  final double percent;
  final Color  color;
  const _PieSlice({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });
}

// ── Pie chart painter ─────────────────────────────────
class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final double progress; // 0.0 → 1.0 animation

  const _PieChartPainter({required this.slices, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.height / 2) - 10;
    final innerR = r * 0.52; // donut hole

    final total  = slices.fold(0.0, (s, e) => s + e.value);
    if (total == 0) return;

    double startAngle = -3.14159 / 2; // bắt đầu từ trên đỉnh
    final maxSweep = 2 * 3.14159 * progress;
    double swept   = 0;

    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * 3.14159;
      final clampedSweep = (swept + sweep > maxSweep)
          ? (maxSweep - swept).clamp(0.0, sweep)
          : sweep;
      if (clampedSweep <= 0) break;

      // Slice
      paint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, clampedSweep, true, paint,
      );

      // % label nếu đủ lớn
      if (slice.percent >= 5 && clampedSweep >= sweep * 0.9) {
        final labelAngle = startAngle + clampedSweep / 2;
        final lx = cx + (r * 0.72) * _cos(labelAngle);
        final ly = cy + (r * 0.72) * _sin(labelAngle);
        textPainter
          ..text = TextSpan(
            text: '${slice.percent.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white,
                fontSize: 10, fontWeight: FontWeight.bold),
          )
          ..layout();
        textPainter.paint(canvas,
            Offset(lx - textPainter.width / 2,
                   ly - textPainter.height / 2));
      }

      startAngle += clampedSweep;
      swept += clampedSweep;
    }

    // Donut hole
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), innerR, paint);

    // Text ở giữa
    textPainter
      ..text = TextSpan(
        text: 'Chi tiêu',
        style: TextStyle(color: Colors.grey[600],
            fontSize: 11, fontWeight: FontWeight.w500),
      )
      ..layout();
    textPainter.paint(canvas,
        Offset(cx - textPainter.width / 2, cy - 8));
  }

  double _cos(double rad) {
    // Simple cos approximation using dart:math would be ideal
    // but we avoid import — use built-in via radians
    return _mathCos(rad);
  }

  double _sin(double rad) => _mathSin(rad);

  // Use dart math
  double _mathCos(double x) {
    // Taylor series cos(x)
    double r = 1, t = 1;
    for (int i = 1; i <= 10; i++) {
      t *= -x * x / ((2 * i - 1) * (2 * i));
      r += t;
    }
    return r;
  }

  double _mathSin(double x) {
    double r = x, t = x;
    for (int i = 1; i <= 10; i++) {
      t *= -x * x / ((2 * i) * (2 * i + 1));
      r += t;
    }
    return r;
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.progress != progress || old.slices != slices;
}
class _BarData {
  final String label;
  final double value;
  final Color  color;
  const _BarData(this.label, this.value, this.color);
}

// ── Gauge painter ─────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double percentage; // 0 - 100
  final Color  color;
  final bool   isDark;

  const _GaugePainter({
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final r  = size.width * 0.38;

    final bgPaint = Paint()
      ..color = isDark ? Colors.grey[700]! : Colors.grey[200]!
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = 3.14159; // 180°
    const sweepFull  = 3.14159; // 180°

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle, sweepFull, false, bgPaint,
    );

    // Foreground arc — theo %
    final sweep = sweepFull * (percentage / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle, sweep, false, fgPaint,
    );

    // Tick marks 0%, 50%, 100%
    final tickPaint = Paint()
      ..color = (isDark ? Colors.grey[500] : Colors.grey[400])!
      ..strokeWidth = 1.5;

    for (final pct in [0.0, 0.5, 1.0]) {
      final angle = startAngle + sweepFull * pct;
      final x1 = cx + (r - 12) * -1 * _cos(angle);
      final y1 = cy + (r - 12) * _sin(angle) * -1;
      final x2 = cx + (r + 4)  * -1 * _cos(angle);
      final y2 = cy + (r + 4)  * _sin(angle) * -1;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  double _cos(double rad) => -1 * (rad == 3.14159 ? -1.0 : (rad > 3.14159 ? -0.7071 : 1.0));
  double _sin(double rad) => rad == 3.14159 ? 0.0 : 0.7071;

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.percentage != percentage || old.color != color;
}