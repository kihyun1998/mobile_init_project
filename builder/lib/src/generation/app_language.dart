import 'selection.dart';

/// 결과물이 지원할 언어.
///
/// [code] 는 arb 파일 이름(`intl_<code>.arb`)이자 `Locale` 의 언어 코드다.
enum AppLanguage {
  ko('ko', '한국어'),
  en('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;
}

/// 고른 언어. **비어 있는 선택은 만들 수 없다.**
///
/// 언어를 하나도 남기지 않으면 arb 가 전부 사라져서 `intl_utils` 가 빈
/// 번역 파일을 새로 만들고, 결과물이 컴파일되지 않는다.
class LanguageSelection {
  const LanguageSelection._(this.languages);

  factory LanguageSelection.of(Iterable<AppLanguage> languages) =>
      LanguageSelection._(
        orderedNonEmpty(languages, AppLanguage.values, '언어를 하나 이상 골라야 합니다.'),
      );

  static const all = LanguageSelection._([AppLanguage.ko, AppLanguage.en]);

  final List<AppLanguage> languages;

  /// `intl_utils` 의 `main_locale`.
  ///
  /// **이게 가리키는 arb 가 없으면 `intl_utils` 는 빈 arb 를 새로 만들고,
  /// 번역 문자열이 하나도 없는 `S` 가 생성된다.** 기본값이 `en` 이라서
  /// 한국어만 고른 경우가 정확히 그 상황이다. 그래서 고른 것 중 하나를
  /// 반드시 적어줘야 한다.
  AppLanguage get main => languages.first;
}
