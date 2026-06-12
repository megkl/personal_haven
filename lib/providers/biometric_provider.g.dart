// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BiometricNotifier)
final biometricProvider = BiometricNotifierProvider._();

final class BiometricNotifierProvider
    extends $NotifierProvider<BiometricNotifier, BiometricState> {
  BiometricNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricNotifierHash();

  @$internal
  @override
  BiometricNotifier create() => BiometricNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricState>(value),
    );
  }
}

String _$biometricNotifierHash() => r'679bd15d0dbf416870882c6d10dddff299c1bc94';

abstract class _$BiometricNotifier extends $Notifier<BiometricState> {
  BiometricState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BiometricState, BiometricState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BiometricState, BiometricState>,
              BiometricState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
