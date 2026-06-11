// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JournalNotifier)
final journalProvider = JournalNotifierProvider._();

final class JournalNotifierProvider
    extends $NotifierProvider<JournalNotifier, JournalState> {
  JournalNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalNotifierHash();

  @$internal
  @override
  JournalNotifier create() => JournalNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalState>(value),
    );
  }
}

String _$journalNotifierHash() => r'6bbe2175cf4a098cb6fc0ad73da7f9f98e9693c2';

abstract class _$JournalNotifier extends $Notifier<JournalState> {
  JournalState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<JournalState, JournalState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JournalState, JournalState>,
              JournalState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
