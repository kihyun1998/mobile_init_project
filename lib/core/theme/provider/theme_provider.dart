import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../const/enum_debounce_key.dart';
import '../../const/enum_hive_key.dart';
import '../../util/debounce/debounce_service.dart';
import '../dark_theme.dart';
import '../foundation/app_theme.dart';
import '../light_theme.dart';

part 'theme_provider.g.dart';

@Riverpod(dependencies: [], keepAlive: true)
class Theme extends _$Theme {
  Box<String>? _box;

  @override
  AppTheme build() {
    try {
      final box = Hive.box<String>(HiveKey.boxSettings.key);
      final savedMode = box.get(HiveKey.theme.key);

      if (savedMode != null) {
        final mode = AppMode.fromJson(savedMode);
        return mode == AppMode.light ? LightTheme() : DarkTheme();
      }
    } catch (e) {
      // 에러시 기본값
    }

    return LightTheme();
  }

  /// 테마 변경 (토글)
  /// UI는 즉시 변경되고, 저장은 debounce로 처리
  Future<void> toggleTheme() async {
    final newTheme = state.mode == AppMode.light ? DarkTheme() : LightTheme();

    // 1. UI 즉시 업데이트 (사용자 경험 우선)
    state = newTheme;

    // 2. 저장은 debounce로 처리 (성능 최적화)
    _scheduleThemeSave(newTheme.mode);
  }

  /// 특정 테마로 설정
  /// UI는 즉시 변경되고, 저장은 debounce로 처리
  Future<void> setTheme(AppMode mode) async {
    final newTheme = mode == AppMode.light ? LightTheme() : DarkTheme();

    // 1. UI 즉시 업데이트
    state = newTheme;

    // 2. 저장은 debounce로 처리
    _scheduleThemeSave(mode);
  }

  /// 저장된 테마 불러오기 (앱 시작 시 한 번만 호출)
  Future<void> loadSavedTheme() async {
    _box ??= await _openBox();
    final savedMode = _box!.get(HiveKey.theme.key);

    if (savedMode != null) {
      final mode = AppMode.fromJson(savedMode);
      final newTheme = mode == AppMode.light ? LightTheme() : DarkTheme();

      state = newTheme;
    } else {}
  }

  /// 현재 대기 중인 테마 저장 작업을 즉시 실행
  Future<bool> flushThemeSave() async {
    return await DebounceService.instance
        .executeImmediately(DebounceKey.theme.key);
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
      _box ??= await _openBox();
      await _box!.put(HiveKey.theme.key, mode.toJson());

      // 🔍 Hive 박스 전체 내용 확인
    } catch (e) {}
  }

  /// Hive 박스 열기
  Future<Box<String>> _openBox() async {
    if (!Hive.isBoxOpen(HiveKey.boxSettings.key)) {
      final box = await Hive.openBox<String>(HiveKey.boxSettings.key);
      return box;
    }

    final box = Hive.box<String>(HiveKey.boxSettings.key);
    return box;
  }
}

extension ThemeProviderExt on WidgetRef {
  AppTheme get theme => watch(themeProvider);
  AppColor get color => theme.color;
  AppFont get font => theme.font;
  ThemeData get themeData => theme.themeData;
}
