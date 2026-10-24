import 'dart:math';
import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';

/// Komponen grafik batang pengeluaran 7 hari terakhir berbasis widget murni Flutter.
class WeeklyExpenseChart extends StatefulWidget {
  final double dailyBudget;
  final Map<DateTime, double> expenses;

  const WeeklyExpenseChart({
    super.key,
    required this.dailyBudget,
    required this.expenses,
  });

  @override
  State<WeeklyExpenseChart> createState() => _WeeklyExpenseChartState();
}

class _WeeklyExpenseChartState extends State<WeeklyExpenseChart> {
  DateTime? _selectedDate;

  String _formatSelectedHeader(DateTime date, double amount) {
    final dayName = SakuKosFormatters.dayNames[date.weekday - 1];
    final day = date.day;
    final monthName = SakuKosFormatters.monthNames[date.month - 1];
    final shortMonth =
        monthName.length > 3 ? monthName.substring(0, 3) : monthName;
    return '$dayName, $day $shortMonth: ${SakuKosFormatters.rupiah(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = SakuKosPalette.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final entries = widget.expenses.entries.toList();
    final total7Days =
        widget.expenses.values.fold<double>(0.0, (sum, val) => sum + val);

    final maxExpenseIn7Days = widget.expenses.values.isEmpty
        ? 0.0
        : widget.expenses.values.reduce(max);

    // Mencegah division by zero (0 / 0 = NaN)
    final maxScale = max(widget.dailyBudget, maxExpenseIn7Days);

    final selectedExpense = _selectedDate != null
        ? (widget.expenses[_selectedDate] ?? 0.0)
        : total7Days;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Grafik ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren 7 Hari Terakhir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDate != null
                          ? _formatSelectedHeader(_selectedDate!, selectedExpense)
                          : 'Total pengeluaran minggu ini',
                      style: TextStyle(
                        fontSize: 11,
                        color: _selectedDate != null
                            ? colors.emerald
                            : colors.textSecondary,
                        fontWeight: _selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    SakuKosFormatters.rupiah(selectedExpense),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _selectedDate != null
                          ? (selectedExpense > widget.dailyBudget
                              ? colors.rose
                              : (selectedExpense > 0
                                  ? colors.emerald
                                  : colors.textPrimary))
                          : colors.textPrimary,
                    ),
                  ),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = null),
                      child: Text(
                        'Reset info',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.emerald,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Bar Chart Rows ─────────────────────────────────────────
          SizedBox(
            height: 108,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final date = entry.key;
                final expense = entry.value;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected = _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;

                final heightRatio =
                    maxScale > 0 ? (expense / maxScale).clamp(0.0, 1.0) : 0.0;
                final barHeight = max(4.0, 70.0 * heightRatio);

                final Color barColor;
                if (expense == 0) {
                  barColor = colors.border;
                } else if (expense > widget.dailyBudget) {
                  barColor = colors.rose;
                } else {
                  barColor = colors.emerald;
                }

                return Expanded(
                  child: GestureDetector(
                    key: Key(
                      'chart_bar_${date.year}_${date.month}_${date.day}',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDate = null;
                        } else {
                          _selectedDate = date;
                        }
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Batang Vertikal
                        Container(
                          width: 20,
                          height: 70,
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            color: colors.scaffold,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? barColor : colors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: 18,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Label Hari
                        Text(
                          SakuKosFormatters.shortDayName(date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday
                                ? colors.emerald
                                : (isSelected
                                    ? colors.textPrimary
                                    : colors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Dot penanda hari ini
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isToday ? colors.emerald : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
