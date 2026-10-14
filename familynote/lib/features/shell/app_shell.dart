import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.tabs, this.onBack});

  /// Exactly four pages, in order: Notas, Listas, Família, Ajustes.
  final List<Widget> tabs;

  /// Shows a "Voltar ao início" button above the page when set.
  final VoidCallback? onBack;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        if (widget.onBack != null)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar ao início'),
                  style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
                ),
              ),
            ),
          ),
        Expanded(child: widget.tabs[_i]),
      ]),
      bottomNavigationBar: NavigationBar(
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note), label: 'Notas'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Listas'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Família'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
