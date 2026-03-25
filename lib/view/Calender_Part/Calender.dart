// lib/view/calendar/CalendarView.dart
// ✅ CALENDAR VIEW - Xem lịch sử giao dịch theo ngày

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({Key? key}) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  Map<DateTime, double> _dailyExpenseTotals = {};
  Map<DateTime, double> _dailyIncomeTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthData();
  }

  // ✅ Kiểm tra đúng cả 2 field: type == 'income' hoặc isIncome == true
  bool _isIncome(Map<String, dynamic> data) {
    return data['type'] == 'income' || data['isIncome'] == true;
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    try {
      final startOfMonth =
          DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(
          _focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: false)
          .get();

      final Map<DateTime, List<Map<String, dynamic>>> events = {};
      final Map<DateTime, double> expenseTotals = {};
      final Map<DateTime, double> incomeTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateOnly = DateTime(date.year, date.month, date.day);
        final amount = (data['amount'] ?? 0).toDouble().abs();
        final income = _isIncome(data);

        events[dateOnly] ??= [];
        events[dateOnly]!.add(data);

        if (income) {
          incomeTotals[dateOnly] = (incomeTotals[dateOnly] ?? 0) + amount;
        } else {
          expenseTotals[dateOnly] =
              (expenseTotals[dateOnly] ?? 0) + amount;
        }
      }

      setState(() {
        _events = events;
        _dailyExpenseTotals = expenseTotals;
        _dailyIncomeTotals = incomeTotals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _events[dateOnly] ?? [];
  }

  String _getWeekdayName(int weekday) {
    const names = {
      DateTime.monday: 'Thứ 2',
      DateTime.tuesday: 'Thứ 3',
      DateTime.wednesday: 'Thứ 4',
      DateTime.thursday: 'Thứ 5',
      DateTime.friday: 'Thứ 6',
      DateTime.saturday: 'Thứ 7',
      DateTime.sunday: 'Chủ nhật',
    };
    return names[weekday] ?? '';
  }

  String _formatSelectedDate(DateTime date) {
    return '${_getWeekdayName(date.weekday)}, '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatMoney(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}đ';
  }

  String _formatShortMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toInt()}K';
    }
    return amount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Lịch Chi Tiêu',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00D09E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            tooltip: 'Hôm nay',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadMonthData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00D09E)))
          : Column(
              children: [
                // ── Calendar ──────────────────────────────────
                Container(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay, day),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF00D09E),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF00D09E).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle:
                          TextStyle(color: Colors.red[400]),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left,
                          color: isDark ? Colors.white : Colors.black),
                      rightChevronIcon: Icon(Icons.chevron_right,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadMonthData();
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        final dateOnly =
                            DateTime(day.year, day.month, day.day);
                        final expTotal =
                            _dailyExpenseTotals[dateOnly] ?? 0;
                        if (expTotal == 0) return null;

                        return Positioned(
                          bottom: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatShortMoney(expTotal),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Ngày đã chọn + tổng hôm đó ───────────────
                if (_selectedDay != null)
                  _buildDaySummaryBar(isDark),

                // ── Danh sách giao dịch ───────────────────────
                Expanded(child: _buildTransactionsList(isDark)),
              ],
            ),
    );
  }

  // ── Thanh tóm tắt ngày ──────────────────────────────────
  Widget _buildDaySummaryBar(bool isDark) {
    final dateOnly = DateTime(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final incomeTotal = _dailyIncomeTotals[dateOnly] ?? 0;
    final expTotal = _dailyExpenseTotals[dateOnly] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: Row(
        children: [
          // Ngày
          Expanded(
            child: Text(
              _formatSelectedDate(_selectedDay!),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          // Thu nhập
          if (incomeTotal > 0) ...[
            Text(
              '+${_formatMoney(incomeTotal)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Chi tiêu
          if (expTotal > 0)
            Text(
              '-${_formatMoney(expTotal)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  // ── Danh sách giao dịch trong ngày ──────────────────────
  Widget _buildTransactionsList(bool isDark) {
    if (_selectedDay == null) {
      return const Center(child: Text('Chọn ngày để xem giao dịch'));
    }

    final dayEvents = _getEventsForDay(_selectedDay!);

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Không có giao dịch',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    // Sắp xếp: income trước, expense sau; cùng loại thì mới nhất lên đầu
    final sorted = List<Map<String, dynamic>>.from(dayEvents)
      ..sort((a, b) {
        final aIncome = _isIncome(a) ? 0 : 1;
        final bIncome = _isIncome(b) ? 0 : 1;
        if (aIncome != bIncome) return aIncome - bIncome;
        final aDate = (a['date'] as Timestamp).toDate();
        final bDate = (b['date'] as Timestamp).toDate();
        return bDate.compareTo(aDate);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = sorted[index];
        final isIncome = _isIncome(tx);
        final amount = (tx['amount'] ?? 0).toDouble().abs();
        final title = tx['title'] ?? tx['note'] ?? 'Không có tiêu đề';
        final category =
            tx['category'] ?? tx['categoryName'] ?? 'Khác';
        final date = (tx['date'] as Timestamp).toDate();
        final timeStr =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        final color = isIncome ? Colors.green[600]! : Colors.red[500]!;
        final bgColor = isIncome
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(category,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Text('• $timeStr',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ]),
                  ],
                ),
              ),

              // ✅ Amount — income = +xanh, expense = -đỏ
              Text(
                '${isIncome ? '+' : '-'}${_formatMoney(amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}