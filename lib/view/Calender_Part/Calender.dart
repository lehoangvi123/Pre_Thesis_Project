// lib/view/calendar/CalendarView.dart
// ✅ CALENDAR VIEW - Xem lịch sử giao dịch theo ngày (giống Folly)

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 

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
  Map<DateTime, double> _dailyTotals = {}; // Tổng chi tiêu mỗi ngày
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthData();
  }

  // ✅ Load data tháng hiện tại
  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);

    try {
      DateTime startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      DateTime endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: false)
          .get();

      Map<DateTime, List<Map<String, dynamic>>> events = {};
      Map<DateTime, double> totals = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime date = (data['date'] as Timestamp).toDate();
        DateTime dateOnly = DateTime(date.year, date.month, date.day);

        // Add to events
        if (events[dateOnly] == null) {
          events[dateOnly] = [];
        }
        events[dateOnly]!.add(data);

        // Calculate daily total (only expenses)
        bool isIncome = data['isIncome'] ?? false;
        double amount = (data['amount'] ?? 0).toDouble();
        
        if (!isIncome) {
          totals[dateOnly] = (totals[dateOnly] ?? 0) + amount;
        }
      }

      setState(() {
        _events = events;
        _dailyTotals = totals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ Get events for selected day
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    return _events[dateOnly] ?? [];
  }

  // ✅ Helper: Get Vietnamese weekday name
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Thứ 2';
      case DateTime.tuesday: return 'Thứ 3';
      case DateTime.wednesday: return 'Thứ 4';
      case DateTime.thursday: return 'Thứ 5';
      case DateTime.friday: return 'Thứ 6';
      case DateTime.saturday: return 'Thứ 7';
      case DateTime.sunday: return 'Chủ nhật';
      default: return '';
    }
  }

  // ✅ Format date manually (no locale needed)
  String _formatSelectedDate(DateTime date) {
    return '${_getWeekdayName(date.weekday)}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      
      appBar: AppBar(
        title: const Text('Lịch Chi Tiêu', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00D09E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Today button
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E)))
          : Column(
              children: [
                // Calendar Widget
                Container(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    
                    // Style
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF00D09E),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF00D09E).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: TextStyle(color: Colors.red[400]),
                    ),
                    
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    // Events
                    eventLoader: (day) => _getEventsForDay(day),
                    
                    // Callbacks
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

                    // Custom day builder
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        
                        DateTime dateOnly = DateTime(day.year, day.month, day.day);
                        double total = _dailyTotals[dateOnly] ?? 0;
                        
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatShortMoney(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Selected day info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null
                            ? _formatSelectedDate(_selectedDay!)
                            : 'Chọn ngày',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (_selectedDay != null) ...[
                        Text(
                          _formatMoney(_dailyTotals[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? 0),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Transactions list
                Expanded(
                  child: _buildTransactionsList(),
                ),
              ],
            ),
    );
  }

  // ✅ Build transactions list for selected day
  Widget _buildTransactionsList() {
    if (_selectedDay == null) {
      return const Center(child: Text('Chọn ngày để xem giao dịch'));
    }

    List<Map<String, dynamic>> dayEvents = _getEventsForDay(_selectedDay!);

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có giao dịch',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        var transaction = dayEvents[index];
        bool isIncome = transaction['isIncome'] ?? false;
        double amount = (transaction['amount'] ?? 0).toDouble();
        String title = transaction['title'] ?? 'Không có tiêu đề';
        String category = transaction['category'] ?? transaction['categoryName'] ?? 'Khác';
        DateTime date = (transaction['date'] as Timestamp).toDate();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C2C)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                '${isIncome ? '+' : '-'}${_formatMoney(amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMoney(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
}