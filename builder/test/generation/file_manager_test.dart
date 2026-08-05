import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/file_manager.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';

/// 파일 관리자를 열고 나서 **실패라고 말할지**를 정하는 규칙.
///
/// 순수 함수로 갈라둔 이유는 이 판정이 **OS 마다 다른데** 테스트는 한 OS 에서만
/// 돌기 때문이다. `Platform.operatingSystem` 을 그대로 읽으면 Windows 규칙은
/// Windows 러너에서만 검증되고, 정작 이 결함이 났던 자리가 다른 OS 의 CI 에서는
/// 빈칸으로 남는다.
ProcessRunResult _result(int exitCode, {bool timedOut = false}) =>
    ProcessRunResult(
      exitCode: exitCode,
      stdout: '',
      stderr: '',
      timedOut: timedOut,
    );

void main() {
  group('windows — explorer 의 종료 코드는 정보가 아니다', () {
    // 실측 (2026-08-05, Windows 11): 정상적으로 창이 열린 상태에서
    //   explorer C:\Users\User\mib-builder-release-test  →  exitCode 1
    // 그래서 1 을 실패로 읽으면 이 버튼은 **항상** 실패 메시지를 띄운다.
    // #32 의 릴리스 왕복에서 실제로 그렇게 나왔다.
    test('1 을 돌려줘도 실패가 아니다', () {
      expect(revealFailed(_result(1), operatingSystem: 'windows'), isFalse);
    });

    test('0 이어도 실패가 아니다', () {
      expect(revealFailed(_result(0), operatingSystem: 'windows'), isFalse);
    });

    test('감시견이 끊었으면 실패다 — 남은 유일한 신호', () {
      expect(
        revealFailed(_result(1, timedOut: true), operatingSystem: 'windows'),
        isTrue,
      );
    });
  });

  group('macos·linux — 종료 코드가 그대로 신호다', () {
    // `open` 과 `xdg-open` 은 실패했을 때 non-zero 를 돌려준다. Windows 규칙을
    // 여기까지 넓히면 진짜 실패가 조용해진다.
    for (final os in ['macos', 'linux']) {
      test('$os: 0 은 성공', () {
        expect(revealFailed(_result(0), operatingSystem: os), isFalse);
      });

      test('$os: non-zero 는 실패', () {
        expect(revealFailed(_result(1), operatingSystem: os), isTrue);
      });

      test('$os: 감시견이 끊어도 실패', () {
        expect(
          revealFailed(_result(0, timedOut: true), operatingSystem: os),
          isTrue,
        );
      });
    }
  });
}
