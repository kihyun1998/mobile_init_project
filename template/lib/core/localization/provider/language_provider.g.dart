// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$languageHash() => r'8790e18093b69934a6e14cc91d93c52348cf1251';

/// See also [language].
@ProviderFor(language)
final languageProvider = AutoDisposeProvider<S>.internal(
  language,
  name: r'languageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$languageHash,
  dependencies: <ProviderOrFamily>[localeStateProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    localeStateProvider,
    ...?localeStateProvider.allTransitiveDependencies
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LanguageRef = AutoDisposeProviderRef<S>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
