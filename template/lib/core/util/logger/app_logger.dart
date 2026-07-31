import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  // 싱글톤 인스턴스
  static final AppLogger _instance = AppLogger._internal();
  static AppLogger get instance => _instance;

  AppLogger._internal();

  /// kDebugMode일 때만 출력, 릴리즈에서는 자동 비활성화
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, printEmojis: true),
    level: kDebugMode ? Level.debug : Level.off,
  );

  /// 디버그 로그
  void d(dynamic message) => _logger.d(message);

  /// 정보 로그
  void i(dynamic message) => _logger.i(message);

  /// 경고 로그
  void w(dynamic message) => _logger.w(message);

  /// 에러 로그
  void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

/// 전역 logger 접근용 getter
AppLogger get logger => AppLogger.instance;
