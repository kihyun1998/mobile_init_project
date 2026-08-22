// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocaleState)
final localeStateProvider = LocaleStateProvider._();

final class LocaleStateProvider extends $NotifierProvider<LocaleState, Locale> {
  LocaleStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeStateProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$localeStateHash();

  @$internal
  @override
  LocaleState create() => LocaleState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$localeStateHash() => r'df170fa2925709e3f441b692f0a2e98cc8e376dc';

abstract class _$LocaleState extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
