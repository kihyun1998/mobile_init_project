import 'dart:async';

import '../logger/app_logger.dart';

/// Debounce 작업을 나타내는 클래스
class DebounceOperation {
  final String key;
  final Future<void> Function() operation;
  Timer? _timer;
  final Duration delay;

  DebounceOperation({
    required this.key,
    required this.operation,
    this.delay = const Duration(milliseconds: 500),
  });

  /// 타이머를 시작하거나 재시작
  void schedule() {
    _timer?.cancel(); // 기존 타이머가 있으면 취소
    _timer = Timer(delay, () async {
      try {
        await operation();
      } catch (e, stackTrace) {
        // 타이머 콜백이라 이 예외를 받아줄 곳이 없다. 삼키되 흔적은 남긴다.
        logger.e('Debounce operation failed for key "$key"', e, stackTrace);
      }
    });
  }

  /// 즉시 실행 (debounce 무시하고 바로 실행)
  Future<void> executeImmediately() async {
    _timer?.cancel();
    try {
      await operation();
    } catch (e, stackTrace) {
      // 여기서는 호출자가 받아서 처리할 수 있으므로 남기고 다시 던진다.
      logger.e('Immediate execution failed for key "$key"', e, stackTrace);
      rethrow;
    }
  }

  /// 타이머 취소
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 현재 대기 중인지 확인
  bool get isPending => _timer?.isActive ?? false;

  /// 리소스 정리
  void dispose() {
    cancel();
  }
}
