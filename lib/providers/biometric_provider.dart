import 'package:personal_haven/services/biometric_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_provider.g.dart';

class BiometricState {
  final bool isAvailable;
  final bool isEnabled;
  final String label;
  final bool isLoading;

  const BiometricState({
    this.isAvailable = false,
    this.isEnabled = false,
    this.label = 'Biometric',
    this.isLoading = true,
  });

  BiometricState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    String? label,
    bool? isLoading,
  }) {
    return BiometricState(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class BiometricNotifier extends _$BiometricNotifier {
  final _service = BiometricService.instance;

  @override
  BiometricState build() {
    // replaces the constructor — runs on first use
    Future.microtask(_load);
    return BiometricState();
  }

  Future<void> _load() async {
    final available = await _service.isAvailable();
    final enabled = await _service.isEnabled();
    final label = await _service.getBiometricLabel();
    if (!ref.mounted) return;
    state = BiometricState(
      isAvailable: available,
      isEnabled: available && enabled,
      label: label,
      isLoading: false,
    );
  }

  /// Toggle biometric lock on/off. Returns false if hardware unavailable.
  Future<bool> toggle(bool value) async {
    if (value && !state.isAvailable) return false;

    // When enabling, verify once first so the user knows it works
    if (value) {
      final ok = await _service.authenticate(
        reason: 'Confirm your identity to enable biometric lock',
      );
      if (!ok || !ref.mounted) return false;
    }

    await _service.setEnabled(value);
    if (!ref.mounted) return false;
    state = state.copyWith(isEnabled: value);
    return true;
  }

  Future<void> refresh() => _load();
}
