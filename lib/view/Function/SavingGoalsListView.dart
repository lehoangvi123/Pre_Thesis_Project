// lib/view/Function/SavingGoalsListView.dart

import 'package:flutter/material.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';
import './SavingGoalDetailView.dart';
import './AddSavingGoalView.dart';

class SavingGoalsView extends StatefulWidget {
  const SavingGoalsView({Key? key}) : super(key: key);

  @override
  State<SavingGoalsView> createState() => _SavingGoalsViewState();
}

class _SavingGoalsViewState extends State<SavingGoalsView> {
  final SavingGoalService _goalService = SavingGoalService();

  static const _teal = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}₫';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mục tiêu tiết kiệm',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_teal, _purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddSavingGoalView()));
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<SavingGoal>>(
        stream: _goalService.getSavingGoalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _teal));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final goals = snapshot.data!;
          final completedCount = goals.where((g) => g.isCompleted).length;
          final totalTarget =
              goals.fold(0.0, (sum, g) => sum + g.targetAmount);
          final totalSaved =
              goals.fold(0.0, (sum, g) => sum + g.currentAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(goals.length, completedCount,
                    totalTarget, totalSaved, isDark),
                const SizedBox(height: 24),
                if (goals.where((g) => !g.isCompleted).isNotEmpty) ...[
                  _buildSectionTitle('Đang thực hiện', isDark),
                  const SizedBox(height: 12),
                  ...goals
                      .where((g) => !g.isCompleted)
                      .map((g) => _buildGoalCard(g, isDark)),
                ],
                if (goals.where((g) => g.isCompleted).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Đã hoàn thành 🎉', isDark),
                  const SizedBox(height: 12),
                  ...goals
                      .where((g) => g.isCompleted)
                      .map((g) => _buildGoalCard(g, isDark)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddSavingGoalView()));
          setState(() {});
        },
        backgroundColor: _teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm mục tiêu',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSummaryCard(int total, int completed, double totalTarget,
      double totalSaved, bool isDark) {
    final overallProgress =
        totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_teal, _purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _teal.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng đã tiết kiệm',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(totalSaved),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$completed/$total hoàn thành',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mục tiêu: ${_formatCurrency(totalTarget)}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(overallProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87));
  }

  Widget _buildGoalCard(SavingGoal goal, bool isDark) {
    final goalColor = Color(goal.color ?? 0xFF00CED1);
    final daysLeft = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SavingGoalDetailView(goal: goal)));
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: goal.isCompleted
              ? Border.all(
                  color: Colors.green.withOpacity(0.4), width: 1.5)
              : Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: goalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(goal.icon ?? '🎯',
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(goal.title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (goal.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('✓ Xong',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600)),
                            ),
                          if (!goal.isCompleted && daysLeft != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (daysLeft <= 7
                                        ? Colors.red
                                        : Colors.orange)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  daysLeft <= 0
                                      ? 'Hết hạn'
                                      : '$daysLeft ngày',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: daysLeft <= 7
                                          ? Colors.red
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${_formatCurrency(goal.currentAmount)} / ${_formatCurrency(goal.targetAmount)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal.progress / 100,
                      backgroundColor:
                          isDark ? Colors.grey[700] : Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(goalColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${goal.progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: goalColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_teal, _purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: _teal.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.savings_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 28),
            Text('Chưa có mục tiêu nào',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            Text(
                'Bắt đầu đặt mục tiêu tiết kiệm\nđể theo dõi hành trình tài chính của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color:
                        isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddSavingGoalView()));
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tạo mục tiêu đầu tiên',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}