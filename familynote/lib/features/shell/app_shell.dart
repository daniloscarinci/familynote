import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.tabs});
  /// Exactly four pages, in order: Início, Listas, Família, Ajustes.
  final List<Widget> tabs;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.tabs[_i],
      bottomNavigationBar: NavigationBar(
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Listas'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Família'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
