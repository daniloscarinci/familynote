import 'package:flutter/material.dart';
import 'theme.dart';

/// A large, full-width, always-labelled button. [outline] makes it clearly
/// secondary. Text wraps instead of overflowing at the biggest text size.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outline = false,
    this.height,
    this.caption,
    this.alignStart = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outline;

  /// Minimum height in dp. Defaults to 80 (primary) or 64 (outline).
  final double? height;

  /// Second line under the label (for example "5 itens").
  final String? caption;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final h = height ?? (outline ? 64 : 80);
    final crossAlign = alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = alignStart ? TextAlign.start : TextAlign.center;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: h >= 96 ? 36 : 30),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAlign,
            children: [
              Text(label, textAlign: textAlign),
              if (caption != null)
                Text(caption!,
                    textAlign: textAlign,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(88, h)),
      alignment: alignStart ? Alignment.centerLeft : Alignment.center,
    );
    return SizedBox(
      width: double.infinity,
      child: outline
          ? OutlinedButton(onPressed: onPressed, style: style, child: child)
          : ElevatedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

/// Standard sub-screen: a labelled "Voltar" at the left, a 28sp title, 20dp
/// padding, and content that scrolls instead of overflowing.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kScreenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('btn-back'),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: kSectionSpacing),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

enum MessageKind { error, success, info }

/// A message with an icon AND words, never colour alone.
class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key, this.kind = MessageKind.info, this.textKey});
  final String text;
  final MessageKind kind;

  /// Key given to the Text itself (so tests can read the sentence).
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (color, icon) = switch (kind) {
      MessageKind.error => (p.error, Icons.error_outline),
      MessageKind.success => (p.success, Icons.check_circle_outline),
      MessageKind.info => (p.primary, Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                key: textKey,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Heading for a block of content on a screen.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// A clear label ABOVE a field (never a floating label that shrinks).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.helper});
  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: t.titleSmall),
        const SizedBox(height: 8),
        child,
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(helper!, style: t.bodySmall),
        ],
      ],
    );
  }
}

/// On/off row where the whole row is the tap target and the switch is enlarged.
class BigSwitchRow extends StatelessWidget {
  const BigSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Semantics(
      toggled: value,
      container: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kButtonRadius),
          side: BorderSide(color: p.border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(kButtonRadius),
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: t.bodyLarge),
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                  ]),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.4,
                      child: ExcludeSemantics(
                        child: Switch(value: value, onChanged: onChanged),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A checkbox row (whole row tappable, box enlarged 1.4x, 72dp minimum).
class BigCheckRow extends StatelessWidget {
  const BigCheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kButtonRadius),
          side: BorderSide(color: p.border, width: 2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            checkboxScaleFactor: 1.4,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: checked ? p.textSecondary : p.text,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
            value: checked,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
      ),
    );
  }
}

/// The only way the app shows a snack bar: it stays at least 5 seconds and has
/// a labelled "Fechar" button (the default 4s floor is not left to chance).
void showStickyMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(label: 'Fechar', onPressed: () {}),
  ));
}
