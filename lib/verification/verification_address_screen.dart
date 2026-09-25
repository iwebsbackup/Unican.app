import 'package:flutter/material.dart';
import '../../models/verification_case.dart';
import 'verification_widgets.dart';
import 'verification_untraced_screen.dart';
import 'verification_neighbor_screen.dart';

class VerificationAddressScreen extends StatefulWidget {
  const VerificationAddressScreen({super.key});

  @override
  State<VerificationAddressScreen> createState() =>
      _VerificationAddressScreenState();
}

class _VerificationAddressScreenState
    extends State<VerificationAddressScreen> {
  // Test/dummy address to kick off the flow.
  final _case = VerificationCase(
    address: '221B, Sector 12, Dwarka, New Delhi - 110078',
  );

  String? _tracedChoice;

  void _next() {
    if (_tracedChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Traced or Untraced first')),
      );
      return;
    }

    _case.traced = _tracedChoice == 'Traced';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _case.traced!
            ? VerificationNeighborScreen(verificationCase: _case)
            : VerificationUntracedScreen(verificationCase: _case),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VStepScaffold(
      title: 'Residence Verification',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Given Address',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_case.address, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 24),
          VOptionGroup(
            label: 'Was the address traced?',
            options: const ['Traced', 'Untraced'],
            value: _tracedChoice,
            onChanged: (v) => setState(() => _tracedChoice = v),
          ),
        ],
      ),
    );
  }
}