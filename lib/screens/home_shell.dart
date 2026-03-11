import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'financial_report_screen.dart';
import 'members_screen.dart';
import 'secretary_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
        (auth) => auth.currentUser?.isAdmin ?? false);

    final pages = <Widget>[
      const MembersScreen(),
      if (isAdmin) const FinancialReportScreen(),
      const SecretaryScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.people), label: 'Membros'),
      if (isAdmin)
        const NavigationDestination(
            icon: Icon(Icons.request_quote), label: 'Financeiro'),
      const NavigationDestination(
          icon: Icon(Icons.description), label: 'Secretaria'),
    ];

    final safeIndex = _index >= pages.length ? pages.length - 1 : _index;

    if (safeIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _index = safeIndex);
        }
      });
    }

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: destinations,
      ),
    );
  }
}
