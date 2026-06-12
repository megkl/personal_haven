// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionNotifier)
final transactionProvider = TransactionNotifierProvider._();

final class TransactionNotifierProvider
    extends $NotifierProvider<TransactionNotifier, TransactionState> {
  TransactionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionNotifierHash();

  @$internal
  @override
  TransactionNotifier create() => TransactionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionState>(value),
    );
  }
}

String _$transactionNotifierHash() =>
    r'6ee2bf344ac362d748b71c7a7f150f1bcc0cc681';

abstract class _$TransactionNotifier extends $Notifier<TransactionState> {
  TransactionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionState, TransactionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionState, TransactionState>,
              TransactionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
