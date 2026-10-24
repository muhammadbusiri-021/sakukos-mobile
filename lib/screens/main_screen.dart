import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/add_debt_bottom_sheet.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import 'dashboard_screen.dart';
import 'debt_screen.dart';
import 'report_screen.dart';

/// Shell navigasi utama aplikasi SakuKos dengan Bottom Navigation Bar 3 Tab
/// bergaya WhatsApp (ikon di atas, label teks di bawah).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    DebtScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              key: const Key('catat_fab'),
              onPressed: () => showAddTransactionBottomSheet(context),
              backgroundColor: colors.emerald,
              foregroundColor: isDark ? colors.scaffold : Colors.white,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Catat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : _currentIndex == 1
              ? FloatingActionButton.extended(
                  key: const Key('debt_fab'),
                  onPressed: () => showAddDebtBottomSheet(context),
                  backgroundColor: colors.emerald,
                  foregroundColor: isDark ? colors.scaffold : Colors.white,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Talangan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(
            top: BorderSide(color: colors.border, width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildNavTab(
                  index: 0,
                  label: 'Dompet',
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  colors: colors,
                ),
                _buildNavTab(
                  index: 1,
                  label: 'Talangan',
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  colors: colors,
                ),
                _buildNavTab(
                  index: 2,
                  label: 'Laporan',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required SakuKosPalette colors,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('nav_tab_$index'),
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: colors.emerald.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.emerald.withAlpha(25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 22,
                    color: isSelected ? colors.emerald : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colors.emerald : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
