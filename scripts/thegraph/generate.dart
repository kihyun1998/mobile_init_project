// thegraph — 1층(생성 파이프라인) 진짜 왕복
//
// 빌드 스탬프: thegraph/SKILL.md sha256 ec9136b5f672
// 값의 출처는 docs/agents/thegraph.md 의 `implement / proof` 절이다.
//
// **이 스크립트는 생성을 직접 돌리지 않는다.** `ProjectGenerator` 는
// `builder/lib` 안에 있고 pubspec 없는 standalone 스크립트는 그것을 import 할 수
// 없다. 생성 자체는 빌더 GUI 나 `builder/test/` 를 거친다. 여기는 **그 주위를
// 전부** 한다 — 선행 조건, 검증, 매트릭스, 정리 순서.
//
// 못 하는 것을 하는 척하지 않는 쪽을 골랐다. fake runner 가 초록인데 결과물이
// 컴파일 안 되는 상태가 얼마든지 가능하다는 것이 이 층이 존재하는 이유이므로,
// 여기서 "돌린 척" 하면 같은 실패를 한 겹 더 만든다.
//
// 실행:
//   dart scripts/thegraph/generate.dart --check          ← 생성 전 선행 조건만
//   dart scripts/thegraph/generate.dart --out <경로> [--example off]
//   dart scripts/thegraph/generate.dart --out <경로> --teardown

import 'dart:io';

import '_pipeline_proof.dart';

Future<void> main(List<String> args) async {
  final opts = _parse(args);

  if (opts.containsKey('check') || !opts.containsKey('out')) {
    final ok = await _precondition();
    if (!opts.containsKey('out')) {
      stdout.writeln('');
      stdout.writeln('사용: --out <생성된 프로젝트 경로> [--example on|off]');
      stdout.writeln('      --check            선행 조건만');
      stdout.writeln('      --out <경로> --teardown   검증 끝난 뒤 지운다');
      exit(ok ? 0 : 1);
    }
    if (!ok) exit(1);
  }

  final out = opts['out']!;
  final dir = Directory(out);

  if (opts.containsKey('teardown')) {
    // **정리는 verify 가 결과물을 읽은 뒤에** 한다. 먼저 지우면 렌즈가 볼 것이
    // 없다. 그래서 별도 플래그다 — 검증과 같은 실행에 묶지 않는다.
    if (!dir.existsSync()) {
      stdout.writeln('없다: $out');
      exit(0);
    }
    dir.deleteSync(recursive: true);
    stdout.writeln('지웠다: $out');
    exit(0);
  }

  if (!await _precondition()) exit(1);

  if (!dir.existsSync()) {
    stderr.writeln('생성된 프로젝트가 없다: $out');
    stderr.writeln('먼저 빌더로 생성한다. `_validate` 가 기존 디렉토리에 throw');
    stderr.writeln('하므로 재실행 전에는 --teardown 으로 지워야 한다.');
    exit(1);
  }

  final failures = <String>[];

  if (!await _outputSane(out)) failures.add('결과물 형태 검사');
  if (!await _run(out, 'flutter', ['pub', 'get'])) failures.add('pub get');
  if (!await _run(out, 'flutter', ['analyze'])) failures.add('analyze');
  if (!await _run(out, 'flutter', ['test'])) failures.add('test');

  stdout.writeln('');
  final example = opts['example'];
  if (example == 'off') {
    stdout.writeln('예제 끈 상태로 돌았다.');
    stdout.writeln('→ 켠 상태로도 한 번 돈다. 매트릭스가 둘이다.');
  } else {
    stdout.writeln('예제 켠 상태로 돌았다.');
    stdout.writeln('→ 예제를 끄는 변경이면 **끈 상태로도 한 번** 돈다.');
  }
  stdout.writeln('옵션이 늘면 매트릭스도 늘어난다.');
  stdout.writeln('');
  stdout.writeln('정리는 `verify` 가 이 결과물을 읽은 뒤에:');
  stdout.writeln('  dart scripts/thegraph/generate.dart --out $out --teardown');

  if (failures.isEmpty) {
    // 영수증을 남긴다 — 지금 파이프라인 상태에 대해서만 유효하다. gates.dart 가
    // 이걸 보고 1층 게이트를 통과시킨다. 없으면 그 게이트는 영원히 빨갛고,
    // 통과할 수 없는 게이트는 곧 무시당한다.
    writeReceipt();
    stdout.writeln('');
    stdout.writeln('1층 왕복 통과. 영수증: ${receiptFile.path}');
    stdout.writeln('파이프라인이 다시 움직이면 이 영수증은 저절로 무효가 된다.');
    exit(0);
  }
  stdout.writeln('');
  stdout.writeln('실패 ${failures.length}건: ${failures.join(', ')}');
  stdout.writeln('');
  stdout.writeln('**변경 때문이 아닐 수 있다.** 위 선행 조건과 네트워크를 먼저');
  stdout.writeln('의심한다(pub get 과 테마 CLI 의 폰트 페치가 망을 탄다).');
  stdout.writeln('원인을 못 가르면 초록이 아닌 것을 초록으로 읽지 말고 batch 로.');
  exit(1);
}

/// 커밋 안 된 템플릿 변경은 생성물로 그대로 실려 나가서 **변경과 무관한 이유로**
/// 증명을 죽인다. `dependency_overrides:` 가 대표적이다 —
/// `_withoutDependencies` 는 `dependencies:` 와 `dev_dependencies:` 만 보고
/// `copyEntries` 는 pubspec 을 통째로 복사하므로, 로컬 path override 가 생성되는
/// 모든 프로젝트로 나가고 그 경로는 사용자 머신에 없다.
Future<bool> _precondition() async {
  var ok = true;

  // **더러운 트리는 막지 않는다 — 알리기만 한다.**
  // 커밋 안 한 template 변경을 검증하려고 이 증명을 돌리는 것이 정상 경로다.
  // 처음엔 이걸 하드 실패로 걸어놨는데, 그러면 정확히 써야 할 때 못 쓴다.
  // 여기서 값이 있는 것은 "무엇이 같이 실려 나가는지" 를 눈앞에 두는 것이다.
  final status = await Process.run('git', [
    'status',
    '--short',
    'template/',
  ], runInShell: true);
  final dirty = (status.stdout as String).trim();
  if (dirty.isNotEmpty) {
    stdout.writeln('커밋 안 된 template 변경이 결과물로 같이 간다:');
    for (final l in dirty.split('\n')) {
      stdout.writeln('    $l');
    }
    stdout.writeln('  의도한 것이면 그대로 진행한다.');
  }

  // 이쪽은 하드 실패다. 로컬 개발용 override 는 사용자 머신에 없는 상대
  // 경로를 가리키므로, 결과물의 pub get 이 **변경과 무관한 이유로** 죽는다.
  // `_withoutDependencies` 는 `dependencies:` 와 `dev_dependencies:` 만 보고
  // `copyEntries` 는 pubspec 을 통째로 복사한다.
  final pubspec = File('template/pubspec.yaml');
  if (pubspec.existsSync() &&
      pubspec.readAsStringSync().contains('dependency_overrides:')) {
    stdout.writeln('! template/pubspec.yaml 에 dependency_overrides 가 있다.');
    stdout.writeln('  통째로 복사되고, 그 상대 경로는 사용자 머신에 없다.');
    stdout.writeln('  결과물의 pub get 이 변경과 무관하게 죽는다.');
    ok = false;
  }

  if (ok) stdout.writeln('선행 조건 통과 — template/ 이 생성 가능한 상태다.');
  return ok;
}

/// 결과물이 최소한 프로젝트 모양인지. 여기서 걸리면 analyze 를 돌릴 것도 없다.
Future<bool> _outputSane(String out) async {
  final pubspec = File('$out/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('결과물에 pubspec.yaml 이 없다.');
    return false;
  }
  final text = pubspec.readAsStringSync();
  if (text.contains('name: mobile_init_project')) {
    stderr.writeln('결과물의 pubspec name 이 치환되지 않았다.');
    return false;
  }
  if (text.contains('dependency_overrides:')) {
    stderr.writeln('결과물에 dependency_overrides 가 실려 나갔다.');
    return false;
  }
  return true;
}

Map<String, String> _parse(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--')) continue;
    final key = args[i].substring(2);
    final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
    out[key] = hasValue ? args[++i] : '';
  }
  return out;
}

/// bare 로 돌린다. runInShell 은 Windows 의 flutter.bat 때문에 필요하다.
Future<bool> _run(String dir, String exe, List<String> args) async {
  stdout.writeln('-- $exe ${args.join(' ')}');
  final p = await Process.start(
    exe,
    args,
    workingDirectory: dir,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await p.exitCode;
  if (code != 0) stdout.writeln('   실패 (exit $code)');
  return code == 0;
}
