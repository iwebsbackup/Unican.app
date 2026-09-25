import 'package:flutter/foundation.dart';
import '../models/verification_case.dart';

class VerificationStore {
  VerificationStore._();

  static final VerificationStore instance = VerificationStore._();

  final ValueNotifier<List<VerificationCase>> cases =
      ValueNotifier<List<VerificationCase>>(<VerificationCase>[]);

  void save(VerificationCase value) {
    final list = List<VerificationCase>.from(cases.value);
    final index = list.indexWhere((e) => e.id == value.id);
    if (index >= 0) {
      list[index] = value;
    } else {
      list.insert(0, value);
    }
    cases.value = list;
  }

  void toggleFavorite(VerificationCase value) {
    value.isFavorite = !value.isFavorite;
    cases.value = List<VerificationCase>.from(cases.value);
  }

  void clear() {
    cases.value = <VerificationCase>[];
  }

  List<VerificationCase> get favorites =>
      cases.value.where((e) => e.isFavorite).toList();
}
