import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

const textSizeChoices = <(String, double)>[
  ('Normal', 1.0),
  ('Grande', 1.3),
  ('Muito grande', 1.6),
  ('Enorme', 2.0),
];

/// Asks in plain words before signing out; returns true when confirmed.
Future<bool> confirmSignOut(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Quer sair?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Para voltar, você vai precisar entrar de novo.'),
            const SizedBox(height: kSectionSpacing),
            BigButton(
              key: const Key('btn-confirm-sign-out'),
              label: 'Sim, sair',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: kButtonGap),
            BigButton(
              label: 'Ficar',
              outline: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(textScaleProvider);
    final p = context.palette;
    return ScreenScaffold(
      title: 'Letras maiores e menores',
      children: [
        const SectionTitle('Tamanho das letras'),
        RadioGroup<double>(
          groupValue: scale,
          onChanged: (v) => ref.read(textScaleProvider.notifier).set(v!),
          child: Column(children: [
            for (final (label, value) in textSizeChoices)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: p.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kButtonRadius),
                    side: BorderSide(
                        color: value == scale ? p.primary : p.border,
                        width: value == scale ? 3 : 2),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 72),
                    child: RadioListTile<double>(
                      radioScaleFactor: 1.4,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(label),
                      value: value,
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: kSectionSpacing),
        BigButton(
          key: const Key('btn-sign-out'),
          label: 'Sair',
          outline: true,
          height: 72,
          icon: Icons.logout,
          onPressed: () async {
            if (await confirmSignOut(context)) onSignOut();
          },
        ),
      ],
    );
  }
}
