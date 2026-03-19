// lib/view/Function/Plan/plan_form_widgets.dart
// Reusable widgets cho form lập kế hoạch

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlanFormWidgets {
  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  // ── Section label ─────────────────────────────────────
  static Widget label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
  );

  // ── 2-column grid (choice cards) ──────────────────────
  static Widget grid({
    required List<Map<String, String>> opts,
    required String? selected,
    required Function(String) onSelect,
    required bool isDark,
    double aspectRatio = 2.2,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: aspectRatio,
      children: opts.map((o) {
        final active = selected == o['v'];
        return GestureDetector(
          onTap: () => onSelect(o['v']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active
                  ? _teal.withOpacity(0.1)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active
                      ? _teal
                      : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                  width: active ? 2 : 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Text(o['i']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(o['l']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                        color: active ? _teal : null),
                    maxLines: 2),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Multi-select grid ─────────────────────────────────
  static Widget multiGrid({
    required List<Map<String, String>> opts,
    required List<String> selected,
    required Function(String) onToggle,
    required bool isDark,
    double aspectRatio = 2.0,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: aspectRatio,
      children: opts.map((o) {
        final active = selected.contains(o['v']);
        return GestureDetector(
          onTap: () => onToggle(o['v']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active
                  ? _teal.withOpacity(0.1)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active
                      ? _teal
                      : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                  width: active ? 2 : 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Text(o['i']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(o['l']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                        color: active ? _teal : null),
                    maxLines: 2),
              ),
              if (active)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00CED1), size: 16),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Horizontal row (choice pills) ────────────────────
  static Widget row({
    required List<Map<String, String>> opts,
    required String? selected,
    required Function(String) onSelect,
    required bool isDark,
  }) {
    return Row(children: opts.map((o) {
      final active = selected == o['v'];
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(o['v']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: o == opts.last ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? _teal.withOpacity(0.1)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active
                      ? _teal
                      : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                  width: active ? 2 : 1),
            ),
            child: Center(
              child: Text(o['l']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal,
                      color: active ? _teal : null)),
            ),
          ),
        ),
      );
    }).toList());
  }

  // ── Wrap chips (multi-select) ─────────────────────────
  static Widget chips({
    required List<String> opts,
    required List<String> selected,
    required Function(String) onToggle,
    required bool isDark,
  }) {
    return Wrap(spacing: 8, runSpacing: 8, children: opts.map((o) {
      final active = selected.contains(o);
      return GestureDetector(
        onTap: () => onToggle(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? _teal.withOpacity(0.1)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: active
                    ? _teal
                    : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: active ? 2 : 1),
          ),
          child: Text(o,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? _teal : null)),
        ),
      );
    }).toList());
  }

  // ── Money text field ──────────────────────────────────
  static Widget moneyField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: 'đ',
        suffixStyle:
            const TextStyle(color: _teal, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _teal, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ── Custom text field (nghề khác) ─────────────────────
  static Widget textField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    String? label,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _teal, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ── Bool card (yes/no) ────────────────────────────────
  static Widget boolCard({
    required String label,
    required String icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? _teal.withOpacity(0.1)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive
                  ? _teal
                  : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
              width: isActive ? 2 : 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? _teal : null),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}