import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

const textSizeChoices = <(String, double)>[
  ('Normal', 1.0),
  ('Grande', 1.25),
  ('Muito grande', 1.5),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(textScaleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tamanho das letras', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioGroup<double>(
            groupValue: scale,
            onChanged: (v) => ref.read(textScaleProvider.notifier).set(v!),
            child: Column(children: [
              for (final (label, value) in textSizeChoices)
                SizedBox(
                  height: 64,
                  child: RadioListTile<double>(title: Text(label), value: value),
                ),
            ]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onSignOut, child: const Text('Sair')),
        ],
      ),
    );
  }
}
