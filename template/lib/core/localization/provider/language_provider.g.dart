// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(language)
final languageProvider = LanguageProvider._();

final class LanguageProvider extends $FunctionalProvider<S, S, S>
    with $Provider<S> {
  LanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[localeStateProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          LanguageProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = localeStateProvider;

  @override
  String debugGetCreateSourceHash() => _$languageHash();

  @$internal
  @override
  $ProviderElement<S> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  S create(Ref ref) {
    return language(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(S value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<S>(value),
    );
  }
}

String _$languageHash() => r'8790e18093b69934a6e14cc91d93c52348cf1251';
