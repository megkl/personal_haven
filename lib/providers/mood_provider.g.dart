// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MoodNotifier)
final moodProvider = MoodNotifierProvider._();

final class MoodNotifierProvider
    extends $NotifierProvider<MoodNotifier, MoodState> {
  MoodNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moodNotifierHash();

  @$internal
  @override
  MoodNotifier create() => MoodNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MoodState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MoodState>(value),
    );
  }
}

String _$moodNotifierHash() => r'a4ed328c8f8d2e92ea2981b01a5297047d2c8836';

abstract class _$MoodNotifier extends $Notifier<MoodState> {
  MoodState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MoodState, MoodState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MoodState, MoodState>,
              MoodState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
