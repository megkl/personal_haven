import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages biometric availability, preference persistence, and authentication.
class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  static const _prefKey = 'biometric_enabled';

  final _auth = LocalAuthentication();

  // ── Availability ─────────────────────────────────────────────────────────────

  /// Returns true if the device supports biometrics AND has enrolled credentials.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types.
  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Human-readable name for the best available biometric.
  Future<String> getBiometricLabel() async {
    final types = await getAvailableTypes();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  // ── Preference (SharedPreferences) ───────────────────────────────────────────

  /// Whether the user has opted in to biometric lock.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Enable or disable biometric lock.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  // ── Authentication ────────────────────────────────────────────────────────────

  /// Prompt the user for biometric authentication.
  /// Returns true on success, false on failure or cancellation.
  Future<bool> authenticate({
    String reason = 'Authenticate to access Personal Haven',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// Convenience: only prompt if biometrics are available AND enabled.
  /// Returns true if auth passed OR biometrics are not required.
  Future<bool> authenticateIfEnabled() async {
    if (!await isEnabled()) return true;
    if (!await isAvailable()) return true;
    return authenticate();
  }
}
