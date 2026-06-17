import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/daily_screen.dart';
import 'screens/monthly_screen.dart';
import 'screens/savings_screen.dart';
import 'state/budget_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => BudgetState()..load(),
      child: const PresupuestoApp(),
    ),
  );
}

class PresupuestoApp extends StatelessWidget {
  const PresupuestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presupuesto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const RootShell(),
    );
  }
}

/// Cascarón con BottomNavigationBar y las 3 pestañas.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    DailyScreen(),
    MonthlyScreen(),
    SavingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    if (!state.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Diario',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Mensual',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Ahorro',
          ),
        ],
      ),
    );
  }
}
