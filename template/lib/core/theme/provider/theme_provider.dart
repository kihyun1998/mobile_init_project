import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../../const/enum_debounce_key.dart';
import '../../const/enum_storage_key.dart';
import '../../util/debounce/debounce_service.dart';
import '../../util/logger/app_logger.dart';
import '../foundation/app_mode.dart';

part 'theme_provider.g.dart';

@Riverpod(dependencies: [], keepAlive: true)
class Theme extends _$Theme {
  @override
  AppMode build() {
    try {
      final savedMode = sharedPrefs.getString(StorageKey.theme.key);

      if (savedMode != null) {
        return AppMode.fromJson(savedMode);
      }
    } catch (e) {
      // 에러시 기본값
    }

    return AppMode.light;
  }

  /// 테마 변경 (토글)
  /// UI는 즉시 변경되고, 저장은 debounce로 처리
  Future<void> toggleTheme() async {
    final newMode = state == AppMode.light ? AppMode.dark : AppMode.light;

    // 1. UI 즉시 업데이트 (사용자 경험 우선)
    state = newMode;

    // 2. 저장은 debounce로 처리 (성능 최적화)
    _scheduleThemeSave(newMode);
  }

  /// 특정 테마로 설정
  /// UI는 즉시 변경되고, 저장은 debounce로 처리
  Future<void> setTheme(AppMode mode) async {
    // 1. UI 즉시 업데이트
    state = mode;

    // 2. 저장은 debounce로 처리
    _scheduleThemeSave(mode);
  }

  /// 저장된 테마 불러오기 (앱 시작 시 한 번만 호출)
  Future<void> loadSavedTheme() async {
    final savedMode = sharedPrefs.getString(StorageKey.theme.key);

    if (savedMode != null) {
      state = AppMode.fromJson(savedMode);
    }
  }

  /// 현재 대기 중인 테마 저장 작업을 즉시 실행
  Future<bool> flushThemeSave() async {
    return await DebounceService.instance.executeImmediately(
      DebounceKey.theme.key,
    );
  }

  /// Provider 정리 시 대기 중인 저장 작업 완료
  Future<void> dispose() async {
    await flushThemeSave();
  }

  /// 테마 저장 작업을 debounce 서비스에 스케줄링
  void _scheduleThemeSave(AppMode mode) {
    DebounceService.instance.schedule(
      key: DebounceKey.theme.key,
      operation: () => _saveThemeMode(mode),
      delay: const Duration(seconds: 5), // 테마는 좀 더 빠르게 저장
    );
  }

  /// 테마 모드 저장 (실제 저장 로직)
  Future<void> _saveThemeMode(AppMode mode) async {
    try {
      await sharedPrefs.setString(StorageKey.theme.key, mode.toJson());
    } catch (e, stackTrace) {
      // 삼키는 것이 의도다. 이 함수는 dispose() 경로에서도 불리므로 여기서
      // 던지면 화면을 떠나는 것 자체가 실패한다. 저장이 한 번 실패해도 다음
      // 테마 변경에서 다시 저장되므로 잃는 것은 그 사이의 설정뿐이다.
      // 다만 흔적은 남긴다 — 이유 없이 조용한 것과 이유 있게 조용한 것은 다르다.
      logger.e('테마 저장 실패', e, stackTrace);
    }
  }
}
