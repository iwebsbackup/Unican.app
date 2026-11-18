import 'package:flutter/material.dart';

class VLabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const VLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class VDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const VDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = options.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        hint: Text(
          'Select',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        items: options
            .map(
              (opt) => DropdownMenuItem<String>(
                value: opt,
                child: Text(opt, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class VOptionGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const VOptionGroup({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((opt) {
              final selected = opt == value;
              return _OptionButton(
                label: opt,
                selected: selected,
                onTap: () => onChanged(opt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class VStepScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onNext;
  final String nextLabel;

  const VStepScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    onNext();
                  },
                  child: Text(
                    nextLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown whose "Any other" choice reveals a text box. [onChanged] always
/// receives the final value: the dropdown option, or the typed text when
/// "Any other" is selected (falls back to "Any other" while the box is empty).
/// A saved value that is not one of [options] is restored as "Any other" +
/// its text, so resumed drafts keep what the user typed.
class VOtherDropdown extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const VOtherDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  State<VOtherDropdown> createState() => _VOtherDropdownState();
}

class _VOtherDropdownState extends State<VOtherDropdown> {
  static const String _other = 'Any other';

  final TextEditingController _ctrl = TextEditingController();
  String? _selected;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    if (v == null || v.isEmpty) {
      _selected = null;
    } else if (widget.options.contains(v)) {
      _selected = v;
    } else {
      _selected = _other;
      _ctrl.text = v;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isOther => (_selected ?? '').toLowerCase() == _other.toLowerCase();

  void _emitOther() {
    final text = _ctrl.text.trim();
    widget.onChanged(text.isEmpty ? _other : text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: widget.options.contains(_selected) ? _selected : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: widget.label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            hint: Text(
              'Select',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            items: widget.options
                .map(
                  (opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selected = v);
              if (_isOther) {
                _emitOther();
              } else {
                widget.onChanged(v);
              }
            },
          ),
          if (_isOther) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Please specify',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => _emitOther(),
            ),
          ],
        ],
      ),
    );
  }
}
