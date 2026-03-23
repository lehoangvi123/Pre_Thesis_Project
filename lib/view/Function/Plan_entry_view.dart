// lib/view/Function/Plan/plan_entry_view.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project1/view/Function/AI_Chatbot/chatbot_view.dart';
import 'Spending_analysis_view.dart';
import 'package:project1/view/Bill_Scanner_Service/Bill_scanner_view.dart';
import 'Plan_intro_view.dart';
import 'Plan_form_screen.dart';

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
  bool? _introSeen; // null = loading

  @override
  void initState() {
    super.initState();
    _checkIntroSeen();
  }

  Future<void> _checkIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    // TODO: xoá dòng này trước khi release
    await prefs.remove('plan_intro_seen');
    final seen  = prefs.getBool('plan_intro_seen') ?? false;
    if (mounted) setState(() => _introSeen = seen);
  }

  void _onStartForm() => setState(() => _introSeen = true);

  void _onFreeChat() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ChatbotView()));
  }

  void _onAnalysis() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SpendingAnalysisView()));
  }

  // ✅ Gán class Bill Scanner của bạn vào đây
  void _onBillScanner() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const BillScannerViewSimple()));
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (_introSeen == null) return const SizedBox.shrink();

    // Chưa xem → intro
    if (_introSeen == false) {
      return PlanIntroView(
        onStartForm:   _onStartForm,
        onFreeChat:    _onFreeChat,
        onAnalysis:    _onAnalysis,
        onBillScanner: _onBillScanner,
      );
    }

    // Đã xem → form
    return PlanFormScreen(
      onPlanCreated: widget.onPlanCreated,
      isGenerating:  widget.isGenerating,
      onGenerate:    widget.onGenerate,
      onBackToIntro: () => setState(() => _introSeen = false),
    );
  }
}