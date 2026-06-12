// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationNotifier)
final notificationProvider = NotificationNotifierProvider._();

final class NotificationNotifierProvider
    extends $NotifierProvider<NotificationNotifier, NotificationPrefs> {
  NotificationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationNotifierHash();

  @$internal
  @override
  NotificationNotifier create() => NotificationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPrefs>(value),
    );
  }
}

String _$notificationNotifierHash() =>
    r'22975e1cc0c09fe132df0935e1c6c05d6e8c057f';

abstract class _$NotificationNotifier extends $Notifier<NotificationPrefs> {
  NotificationPrefs build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotificationPrefs, NotificationPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationPrefs, NotificationPrefs>,
              NotificationPrefs,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
