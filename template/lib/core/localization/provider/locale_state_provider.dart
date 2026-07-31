import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../../const/enum_debounce_key.dart';
import '../../const/enum_storage_key.dart';
import '../../util/debounce/debounce_service.dart';
import '../generated/l10n.dart';

part 'locale_state_provider.g.dart';

@Riverpod(dependencies: [], keepAlive: true)
class LocaleState extends _$LocaleState {
  @override
  Locale build() {
    try {
      final savedLocale = sharedPrefs.getString(StorageKey.locale.key);

      // 저장된 언어를 더 이상 지원하지 않을 수 있다. 그대로 쓰면 번역이
      // 없는 화면이 뜬다.
      if (savedLocale != null && isSupported(Locale(savedLocale))) {
        return Locale(savedLocale);
      }
    } catch (e) {
      // 에러시 기본값
    }

    return defaultLocale;
  }

  /// 지원 언어 목록
  ///
  /// **생성된 delegate 가 정한다.** 목록을 여기에 손으로 들고 있으면,
  /// arb 를 빼고 재생성했을 때 앱이 지원하지 않는 언어를 기본값으로 잡는다.
  static List<Locale> get supportedLocales => S.delegate.supportedLocales;

  /// 저장된 것이 없을 때 쓸 언어
  static Locale get defaultLocale => defaultAmong(supportedLocales);

  static bool isSupported(Locale locale) => supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  /// [supported] 중 기본으로 쓸 언어
  ///
  /// 한국어를 우선하되, 빠져 있으면 남은 것 중 첫 번째다.
  ///
  /// 목록을 인자로 받는 이유는 시험할 수 있게 하려는 것이다.
  /// [supportedLocales] 는 생성된 코드가 정해서 테스트가 바꿀 수 없다.
  static Locale defaultAmong(List<Locale> supported) => supported.firstWhere(
    (locale) => locale.languageCode == 'ko',
    orElse: () => supported.first,
  );

  /// [current] 다음에 올 언어
  ///
  /// 고를 것이 없거나 [current] 가 목록에 없으면 null 이다. 없는 것을
  /// 0번으로 되돌리면, 지원하지 않는 언어에 갇힌 사용자가 버튼을 눌렀을 때
  /// 어디로 갈지 아무도 설명할 수 없다.
  static Locale? nextAmong(List<Locale> supported, Locale current) {
    if (supported.length < 2) return null;

    final index = supported.indexWhere(
      (locale) => locale.languageCode == current.languageCode,
    );
    if (index < 0) return null;

    return supported[(index + 1) % supported.length];
  }

  /// 로케일 변경
  /// UI는 즉시 변경되고, 저장은 debounce로 처리
  Future<void> setLocale(Locale locale) async {
    // 1. UI 즉시 업데이트 (언어 변경은 즉시 반영되어야 함)
    state = locale;

    // 2. 저장은 debounce로 처리
    _scheduleLocaleSave(locale);
  }

  /// 다음 지원 언어로 넘어간다
  ///
  /// 지원 언어가 하나뿐이면 아무 일도 하지 않는다.
  /// UI는 즉시 변경되고, 저장은 debounce로 처리
  Future<void> toggleLocale() async {
    final newLocale = nextAmong(supportedLocales, state);
    if (newLocale == null) return;

    // 1. UI 즉시 업데이트
    state = newLocale;

    // 2. 저장은 debounce로 처리
    _scheduleLocaleSave(newLocale);
  }

  /// 저장된 로케일 불러오기 (앱 시작 시 한 번만 호출)
  Future<void> loadSavedLocale() async {
    final savedLocale = sharedPrefs.getString(StorageKey.locale.key);
    if (savedLocale != null && isSupported(Locale(savedLocale))) {
      state = Locale(savedLocale);
    }
  }

  /// 현재 대기 중인 로케일 저장 작업을 즉시 실행
  ///
  /// 앱 종료 시나 긴급히 저장이 필요한 경우 사용
  /// 반환값: 저장 작업이 있었으면 true, 없었으면 false
  Future<bool> flushLocaleSave() async {
    return await DebounceService.instance.executeImmediately(
      DebounceKey.locale.key,
    );
  }

  /// Provider 정리 시 대기 중인 저장 작업 완료
  ///
  /// 이 메서드는 Provider가 dispose될 때 자동으로 호출되지 않으므로
  /// 필요한 경우 수동으로 호출해야 함
  Future<void> dispose() async {
    await flushLocaleSave();
  }

  /// 로케일 저장 작업을 debounce 서비스에 스케줄링
  void _scheduleLocaleSave(Locale locale) {
    DebounceService.instance.schedule(
      key: DebounceKey.locale.key,
      operation: () => _saveLocale(locale),
      delay: const Duration(seconds: 1), // 로케일은 기본 500ms
    );
  }

  /// 로케일 저장 (실제 저장 로직)
  Future<void> _saveLocale(Locale locale) async {
    try {
      await sharedPrefs.setString(StorageKey.locale.key, locale.languageCode);
    } catch (e) {
      // 저장 실패 시 로그 (에러를 던지지 않음으로써 UI 동작은 계속됨)
    }
  }
}
