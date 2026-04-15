// lib/view/Function/plan_entry_view.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project1/view/Function/AI_Chatbot/chatbot_view.dart';
import 'package:project1/view/Function/SavingGoalsListView.dart';
import 'package:project1/view/Bill_Scanner_Service/Bill_scanner_view.dart';
import 'Plan_intro_view.dart';

class PlanEntryView extends StatefulWidget {
  final void Function(
      Map<String, dynamic> plan,
      Map<String, dynamic> formData) onPlanCreated;
  final bool isGenerating;
  final Future<void> Function(Map<String, dynamic> formData) onGenerate;

  const PlanEntryView({
    Key? key,
    required this.onPlanCreated,
    required this.isGenerating,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<PlanEntryView> createState() => _PlanEntryViewState();
}

class _PlanEntryViewState extends State<PlanEntryView> {
  bool _introSeen = false;

  @override
  void initState() {
    super.initState();
    _checkIntroSeen();
  }

  Future<void> _checkIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('plan_intro_seen'); // TODO: xoá trước khi release
    final seen = prefs.getBool('plan_intro_seen') ?? false;
    if (mounted) setState(() => _introSeen = seen);
  }

  void _onFreeChat() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ChatbotView()));
  }

  void _onSavingGoals() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SavingGoalsView()));
  }

  void _onBillScanner() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const BillScannerViewSimple()));
  }

  @override
  Widget build(BuildContext context) {
    return PlanIntroView(
      onFreeChat:    _onFreeChat,
      onSavingGoals: _onSavingGoals,
      onBillScanner: _onBillScanner,
    );
  }
}