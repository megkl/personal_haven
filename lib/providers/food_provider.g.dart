// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FoodNotifier)
final foodProvider = FoodNotifierProvider._();

final class FoodNotifierProvider
    extends $NotifierProvider<FoodNotifier, FoodState> {
  FoodNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodNotifierHash();

  @$internal
  @override
  FoodNotifier create() => FoodNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodState>(value),
    );
  }
}

String _$foodNotifierHash() => r'1c16f7d69e4599e48285bfed148b17a774b5a10d';

abstract class _$FoodNotifier extends $Notifier<FoodState> {
  FoodState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FoodState, FoodState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodState, FoodState>,
              FoodState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
