// thegraph — 게이트 러너
//
// 빌드 스탬프: thegraph/SKILL.md sha256 ec9136b5f672
// 값의 출처는 docs/agents/thegraph.md 의 `gate` 절이다. 갈리면 그쪽이 기준이다.
//
// **각 명령을 bare 로 부른다.** 파이프라인의 종료 코드는 마지막 명령의 것이라
// `flutter test | tail -1 && commit` 은 언제나 커밋된다. 실패할 수 없는 게이트는
// 게이트가 아니다 — 이 파일이 스크립트인 이유가 그것이고, 여기서 파이프를 쓰면
// 이 파일의 존재 이유가 사라진다.
//
// 실행: dart scripts/thegraph/gates.dart

import 'dart:io';

import '_pipeline_proof.dart';

/// 무조건 도는 여섯. (디렉토리, 실행 파일, 인자)
const _unconditional = [
  ('template', 'flutter', ['analyze']),
  ('template', 'flutter', ['test']),
  ('builder', 'flutter', ['analyze']),
  ('builder', 'flutter', ['test']),
  (
    'template',
    'dart',
    ['format', '--output=none', '--set-exit-if-changed', 'lib', 'test'],
  ),
  (
    'builder',
    'dart',
    ['format', '--output=none', '--set-exit-if-changed', 'lib', 'test'],
  ),
];

/// diff 가 여기 닿으면 재생성 후 git diff --exit-code.
/// 도구가 셋이고 서로 다르다. 테마는 build_runner 가 만들지 않는다.
const _codegenPaths = [
  'template/tweakcn.css',
  'template/lib/core/localization/l10n/',
  'template/pubspec.lock',
];

const _regenerators = [
  ('테마', 'dart', ['run', 'flutter_tweakcn_generator']),
  ('l10n', 'dart', ['run', 'intl_utils:generate']),
  (
    'codegen',
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
  ),
];

Future<void> main(List<String> args) async {
  final failures = <String>[];

  final changed = await _changedPaths();
  if (changed == null) {
    stderr.writeln('! diff base 를 못 잡았다 — 조건부 게이트를 판정할 수 없다.');
    stderr.writeln('  origin/main 이 있는지 확인할 것. 무조건 게이트만 돌린다.');
  }

  for (final (dir, exe, cmdArgs) in _unconditional) {
    if (!await _run(dir, exe, cmdArgs)) {
      failures.add('$dir: $exe ${cmdArgs.first}');
    }
  }

  if (changed != null && _touches(changed, _codegenPaths)) {
    stdout.writeln('\n== codegen 게이트 — 생성물을 덮어쓴다 ==');
    for (final (label, exe, cmdArgs) in _regenerators) {
      if (!await _run('template', exe, cmdArgs, label: label)) {
        failures.add('template: $label 재생성');
      }
    }
    // **생성기가 쓰는 경로로 좁힌다.** 저장소 전체에 걸면 CI 에서는 맞게 돌지만
    // (체크아웃 직후라 트리가 깨끗하다) 로컬에서는 **항상** 빨개진다 — 작업 중인
    // 트리는 언제나 더럽기 때문이다. 실측으로 걸렸다: 테스트 파일을 고치고
    // 돌렸더니 "생성물이 낡았다" 가 떴는데 정작 `.g.dart` 는 한 글자도 안
    // 바뀌어 있었다. 로컬로 당겨오려고 만든 검사가 로컬에서만 거짓말을 했다.
    if (!await _run('.', 'git', [
      'diff',
      '--exit-code',
      '--',
      '*.g.dart',
      'template/lib/core/localization/generated/',
    ], label: '생성물 최신성')) {
      failures.add('커밋된 생성물이 소스보다 낡았다 — 재생성 결과를 커밋할 것');
    }
  }

  if (changed != null && _touches(changed, pipelinePaths)) {
    // 이 스크립트는 1층을 돌리지 않는다 — 수 분짜리에 네트워크를 타고 사용자
    // 파일시스템에 폴더를 만든다. 대신 **영수증**을 본다. generate.dart 가
    // 통과할 때 파이프라인 파일들의 지문을 적어두고, 그 뒤 파이프라인이 한
    // 글자라도 움직이면 지문이 달라져 영수증이 무효가 된다.
    if (receiptIsCurrent()) {
      stdout.writeln('\n1층 진짜 생성 — 지금 파이프라인 상태로 통과한 영수증이 있다.');
    } else {
      stdout.writeln('\n! 1층 진짜 생성 게이트가 필요하다 (diff 가 파이프라인에 닿았다).');
      stdout.writeln('  dart scripts/thegraph/generate.dart --out <경로> 로 돌린다.');
      if (receiptFile.existsSync()) {
        stdout.writeln('  영수증이 있지만 그 뒤로 파이프라인이 움직였다 — 다시 돌린다.');
      }
      failures.add('1층 진짜 생성 — 이 상태로는 아직 안 돌았다');
    }
  }

  stdout.writeln('');
  if (failures.isEmpty) {
    stdout.writeln('게이트 통과.');
    exit(0);
  }
  stdout.writeln('실패 ${failures.length}건:');
  for (final f in failures) {
    stdout.writeln('  - $f');
  }
  exit(1);
}

/// merge-base 부터의 변경 경로. **추적 안 되는 새 파일까지 센다.**
///
/// 인자 없는 git diff 는 워킹트리와 인덱스를 비교하므로 base 를 반드시 주고,
/// `git diff` 는 add 안 한 새 파일을 아예 안 보므로 `ls-files --others` 를
/// 합친다. 새 `.arb` 나 새 provider 파일을 더하는 것이 조건부 게이트가 걸려야
/// 하는 전형적인 모양인데, 그것이 전부 새 파일이다.
Future<List<String>?> _changedPaths() async {
  final base = await Process.run('git', [
    'merge-base',
    'origin/main',
    'HEAD',
  ], runInShell: true);
  if (base.exitCode != 0) return null;

  final tracked = await Process.run('git', [
    'diff',
    '--name-only',
    (base.stdout as String).trim(),
  ], runInShell: true);
  if (tracked.exitCode != 0) return null;
  final untracked = await Process.run('git', [
    'ls-files',
    '--others',
    '--exclude-standard',
  ], runInShell: true);

  final out = <String>{};
  for (final r in [tracked, untracked]) {
    if (r.exitCode != 0) continue;
    out.addAll(
      (r.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty),
    );
  }
  return out.toList();
}

bool _touches(List<String> changed, List<String> prefixes) =>
    changed.any((c) => prefixes.any(c.startsWith));

/// 하나를 bare 로 돌린다. runInShell 은 Windows 의 flutter.bat 때문에 필요하다.
Future<bool> _run(
  String dir,
  String exe,
  List<String> args, {
  String? label,
}) async {
  final name = label ?? '$exe ${args.join(' ')}';
  stdout.writeln('-- $dir: $name');
  final r = await Process.start(
    exe,
    args,
    workingDirectory: dir,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await r.exitCode;
  if (code != 0) stdout.writeln('   실패 (exit $code)');
  return code == 0;
}
