// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventNotifier)
final eventProvider = EventNotifierProvider._();

final class EventNotifierProvider
    extends $NotifierProvider<EventNotifier, EventState> {
  EventNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventNotifierHash();

  @$internal
  @override
  EventNotifier create() => EventNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventState>(value),
    );
  }
}

String _$eventNotifierHash() => r'c9e3959339f62c0571a63f6285bd4cf90de9f218';

abstract class _$EventNotifier extends $Notifier<EventState> {
  EventState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventState, EventState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventState, EventState>,
              EventState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
