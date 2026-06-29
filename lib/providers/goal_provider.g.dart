// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GoalNotifier)
final goalProvider = GoalNotifierProvider._();

final class GoalNotifierProvider
    extends $NotifierProvider<GoalNotifier, GoalState> {
  GoalNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalNotifierHash();

  @$internal
  @override
  GoalNotifier create() => GoalNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalState>(value),
    );
  }
}

String _$goalNotifierHash() => r'eeb8dad8dee437b1589e74763d0ca32c4a8e8459';

abstract class _$GoalNotifier extends $Notifier<GoalState> {
  GoalState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalState, GoalState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalState, GoalState>,
              GoalState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
