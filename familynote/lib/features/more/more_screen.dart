import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// "Outras opções": plain-language rows, each 72dp.
class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.onSearch,
    required this.onFamily,
    required this.onTextSize,
    required this.onSignOut,
  });
  final VoidCallback onSearch;
  final VoidCallback onFamily;
  final VoidCallback onTextSize;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    Widget row(String key, IconData icon, String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: kButtonGap),
          child: BigButton(
            key: Key(key),
            icon: icon,
            label: label,
            outline: true,
            height: 72,
            alignStart: true,
            onPressed: onTap,
          ),
        );
    return ScreenScaffold(
      title: 'Outras opções',
      children: [
        row('opt-search', Icons.search, 'Procurar', onSearch),
        row('opt-family', Icons.groups, 'Família', onFamily),
        row('opt-text-size', Icons.text_fields, 'Letras maiores e menores', onTextSize),
        row('opt-sign-out', Icons.logout, 'Sair', onSignOut),
      ],
    );
  }
}
