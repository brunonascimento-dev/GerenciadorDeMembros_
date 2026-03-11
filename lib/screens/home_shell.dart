import 'package:flutter/material.dart';

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
    final pages = <Widget>[
      const MembersScreen(),
      const FinancialReportScreen(),
      const SecretaryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Membros'),
          NavigationDestination(
              icon: Icon(Icons.request_quote), label: 'Financeiro'),
          NavigationDestination(
              icon: Icon(Icons.description), label: 'Secretaria'),
        ],
      ),
    );
  }
}
