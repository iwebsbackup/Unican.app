import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import 'verification_widgets.dart';
import 'verification_final_screen.dart';

class VerificationResidingScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationResidingScreen({super.key, required this.verificationCase});

  @override
  State<VerificationResidingScreen> createState() =>
      _VerificationResidingScreenState();
}

class _VerificationResidingScreenState
    extends State<VerificationResidingScreen> {
  String? _choice;

  void _next() {
    if (_choice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Yes or No')),
      );
      return;
    }

    final c = widget.verificationCase;
    c.applicantResidingThere = _choice == 'Yes';
    c.generatedRemarks = c.buildConfirmedRemarks();
    c.finalStatus = c.applicantResidingThere!
        ? 'Traced — Confirmed — Residing'
        : 'Traced — Confirmed — Not Residing';

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerificationFinalScreen(verificationCase: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VStepScaffold(
      title: 'Final Check',
      nextLabel: 'Finish',
      onNext: _next,
      child: VOptionGroup(
        label: 'Is the applicant residing there?',
        options: const ['Yes', 'No'],
        value: _choice,
        onChanged: (v) => setState(() => _choice = v),
      ),
    );
  }
}