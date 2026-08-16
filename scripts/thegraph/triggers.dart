// thegraph — `verify` 인바운드 가드
//
// 빌드 스탬프: thegraph/SKILL.md sha256 ec9136b5f672
// 값의 출처는 docs/agents/thegraph.md 의 `verify` 절이다. 갈리면 그쪽이 기준이다.
//
// 성역 경로에 닿으면 완전성 패스가 **판단과 무관하게** 돈다. 이 판정이 스크립트인
// 이유는 "diff 가 작아 보인다" 로 빠져나가지 못하게 하기 위해서다.
//
// 실행: dart scripts/thegraph/triggers.dart
// 종료 코드: 0 = 히트 없음 · 2 = 성역 히트 · 1 = 판정 불가

import 'dart:io';

/// (가) 경로. 접두사로 맞춘다.
const _sacredPaths = [
  // 상류 생성기가 하는 것과 한 글자라도 갈리면 미리보기가 거짓말을 시작한다.
  // 증상이 컴파일 에러가 아니라 "색이 좀 다름" 이라 조용히 지나간다.
  'builder/lib/src/preview/preview_theme.dart',
  // 사용자 파일시스템을 지우는 유일한 곳이고 되돌릴 수 없다.
  'builder/lib/src/generation/project_generator.dart',
  // 시맨틱이 조용한 표면. 문서화된 near-miss 가 전부 여기서 나왔고 CLAUDE.md 가
  // 그 위험들을 하나같이 "테스트는 초록이다" 로 닫는다.
  'template/lib/ui/components/',
];

/// (나) 의존성. 경로로는 안 잡힌다 — 사본이 버전에 *의미로* 묶여 있지
/// *텍스트로* 묶여 있지 않아서, 버전이 오르면 사본이 틀려지는데 파일의 바이트는
/// 안 바뀐다.
const _sacredDeps = {
  // preview_theme.dart 의 사본 둘(colorTokens, _colorSchemeFrom)이 이것에 묶인다.
  'flutter_tweakcn_generator': '미리보기 사본이 이 버전에 묶여 있다',
  // ADR-0001 §3 의 도달성은 채택 시점에 한 번 하는 판정이 아니다.
  'flutter_checkbox': 'ADR-0001 §3 도달성을 다시 센다',
  'flutter_dropdown_button': 'ADR-0001 §3 도달성을 다시 센다',
};

const _lockFiles = ['template/pubspec.lock', 'builder/pubspec.lock'];

Future<void> main(List<String> args) async {
  final base = await _mergeBase();
  if (base == null) {
    stderr.writeln('판정 불가 — merge-base 를 못 잡았다. origin/main 이 있는지 볼 것.');
    exit(1);
  }

  final hits = <String>[];

  for (final path in await _changedPaths(base)) {
    for (final sacred in _sacredPaths) {
      if (path.startsWith(sacred)) hits.add('경로  $path  →  $sacred');
    }
  }

  for (final lock in _lockFiles) {
    final before = _versions(await _fileAt(base, lock));
    // **워킹 트리를 읽는다. `HEAD` 가 아니다.**
    // 경로 절은 `git diff <base>` 로 워킹 트리를 보는데 여기만 `HEAD` 를 보면
    // 아직 커밋 안 한 버전 이동을 양쪽 다 옛 값으로 읽어 히트가 안 난다.
    // 실측으로 걸렸다 — `^0.3.1` → `^0.3.2` 로 올리고 `pub get` 을 돌린
    // 직후, 즉 이 절이 존재하는 이유 그 자체인 변경에서 가드가 통과했다.
    final after = _versions(_workingTree(lock));
    for (final entry in _sacredDeps.entries) {
      final b = before[entry.key];
      final a = after[entry.key];
      if (b == null && a == null) continue;
      if (b != a) {
        hits.add(
          '의존성  $lock: ${entry.key}  ${b ?? '없음'} → ${a ?? '없음'}'
          '  (${entry.value})',
        );
      }
    }
  }

  if (hits.isEmpty) {
    stdout.writeln('성역 히트 없음.');
    stdout.writeln('가드는 이제 **열거 위험**(AI)이다 — 간선 수, 도메인 의미론,');
    stdout.writeln('기능 간 상호작용으로 판단하고 그 판정을 상태에 적는다.');
    exit(0);
  }

  stdout.writeln('성역 히트 ${hits.length}건 — 완전성 패스가 **무조건** 돈다.');
  for (final h in hits) {
    stdout.writeln('  - $h');
  }
  stdout.writeln('');
  stdout.writeln('반박 렌즈(stance=refute)도 여기서 예산을 받는다.');
  exit(2);
}

Future<String?> _mergeBase() async {
  final r = await Process.run('git', [
    'merge-base',
    'origin/main',
    'HEAD',
  ], runInShell: true);
  if (r.exitCode != 0) return null;
  final out = (r.stdout as String).trim();
  return out.isEmpty ? null : out;
}

/// base 부터 지금까지 손댄 경로. **추적 안 되는 새 파일까지 센다.**
///
/// 두 가지를 합친다.
///
/// - `git diff --name-only <base>` — 이미 추적되는 파일의 변경. 인자 없는
///   `git diff` 는 워킹트리와 인덱스를 비교해서 커밋한 뒤에는 항상 빈 결과를
///   내므로 base 를 반드시 준다.
/// - `git ls-files --others --exclude-standard` — **아직 add 안 한 새 파일.**
///   `git diff` 는 이것을 아예 안 본다. 새 shadcn 컴포넌트를 만드는 것이 이
///   저장소에서 제일 흔한 변경인데, 그것이 정확히 이 경로로 새 파일 하나를
///   더하는 모양이다. 이 줄이 없으면 성역 3번이 **가장 흔한 경우에** 안 걸린다.
///   실측으로 확인했다 — `shadcn_progress.dart` 를 만들어놓고 돌렸더니
///   히트 없음이 나왔다.
Future<List<String>> _changedPaths(String base) async {
  final tracked = await Process.run('git', [
    'diff',
    '--name-only',
    base,
  ], runInShell: true);
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

Future<String> _fileAt(String ref, String path) async {
  final r = await Process.run('git', ['show', '$ref:$path'], runInShell: true);
  return r.exitCode == 0 ? r.stdout as String : '';
}

/// 디스크의 지금 내용. 커밋 여부와 무관하게 **실제로 컴파일되는 것**이다.
String _workingTree(String path) {
  final f = File(path);
  return f.existsSync() ? f.readAsStringSync() : '';
}

/// pubspec.lock 에서 패키지 → 해석된 버전. diff 텍스트를 파싱하는 것보다
/// 양쪽 ref 의 해석 결과를 각각 읽어 비교하는 편이 오독이 적다.
///
/// `source: path` 인 항목은 버전 뒤에 `(path)` 를 붙인다 — pub cache 가 아니라
/// 로컬 형제 저장소를 컴파일하고 있다는 뜻이고, 그 자체가 변화다.
Map<String, String> _versions(String lock) {
  final out = <String, String>{};
  String? current;
  String? source;
  String? version;

  void flush() {
    final name = current;
    final resolved = version;
    if (name != null && resolved != null) {
      out[name] = source == 'path' ? '$resolved (path)' : resolved;
    }
    source = null;
    version = null;
  }

  for (final line in lock.split('\n')) {
    final entry = RegExp(r'^  ([A-Za-z_][A-Za-z0-9_]*):\s*$').firstMatch(line);
    if (entry != null) {
      flush();
      current = entry.group(1);
      continue;
    }
    if (current == null) continue;
    final src = RegExp(r'^    source:\s*"?(\w+)"?').firstMatch(line);
    if (src != null) source = src.group(1);
    final ver = RegExp(r'^    version:\s*"?([^"\s]+)"?').firstMatch(line);
    if (ver != null) version = ver.group(1);
  }
  flush();
  return out;
}
