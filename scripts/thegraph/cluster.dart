// thegraph — `search` 후보 라우팅
//
// 빌드 스탬프: thegraph/SKILL.md sha256 ec9136b5f672
// 값의 출처는 docs/agents/thegraph.md 의 `search` 절이다. 갈리면 그쪽이 기준이다.
//
// **artifact 로 검색한다. 기능 이름으로 찾지 않는다** — 관련 이슈는 거의 우리
// 어휘를 안 쓴다.
//
// 실행: dart scripts/thegraph/cluster.dart copyEntries shadcn_switch

import 'dart:io';

/// 이미 record 를 가진 영역. 후보가 여기 걸리면 **앵커를 새로 열지 않는다** —
/// record 아래 conformance item 으로 붙는다.
const _recordAreas = {
  'template/lib/ui/components/ 에 외부 UI 패키지를 들이는 것':
      'docs/adr/0001-external-ui-package-adoption.md (accepted 2026-08-05)',
};

/// 후보가 이 이름들에 걸리면 위 record 영역이다.
const _recordKeywords = [
  'flutter_checkbox',
  'flutter_dropdown_button',
  'flutter_table_plus',
  'flutter_otp_widget',
  'CheckboxStyle',
  'DropdownAmbientColors',
];

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('사용: dart scripts/thegraph/cluster.dart <artifact> [...]');
    stdout.writeln('');
    stdout.writeln('이 저장소에서 잘 듣는 키:');
    stdout.writeln('  상수 이름   copyEntries, colorTokens, _textExtensions');
    stdout.writeln('  파일 경로   preview_theme.dart, project_generator.dart');
    stdout.writeln('  컴포넌트    shadcn_switch, shadcn_select');
    stdout.writeln('  pubspec 키  flutter_tweakcn_generator, environment');
    exit(64);
  }

  for (final artifact in args) {
    stdout.writeln('== $artifact ==');
    final issues = await _search(artifact);
    if (issues == null) {
      stderr.writeln('  gh 질의 실패 — 인증과 remote 를 볼 것.');
      continue;
    }
    if (issues.isEmpty) {
      stdout.writeln('  걸리는 것 없음 → 평범한 단일 이슈 후보다.');
    }
    for (final line in issues) {
      stdout.writeln('  $line');
    }
    _recordNote(artifact);
    stdout.writeln('');
  }

  stdout.writeln('--- 닫힌 이슈 규칙 ---');
  stdout.writeln('이 트래커는 거의 다 닫혀 있다(2026-08-14 실측: 22개 중 21개).');
  stdout.writeln('닫힌 이슈가 그 결함을 소유하면:');
  stdout.writeln('  같은 결함의 재발  → **다시 연다**');
  stdout.writeln('  다른 결함        → 새로 열고 `related to #N` 으로 건다');
  stdout.writeln('어느 쪽이든 **그 이슈가 무엇을 기각했는지 먼저 읽는다.**');
  stdout.writeln('닫혔다고 기록이 사라지지 않고, 그 기각이 이 변경의 방향까지');
  stdout.writeln('묶고 있을 수 있다.');
  stdout.writeln('');
  stdout.writeln('#1 은 닫혀 있고 하위 12개가 100% 다 — 새 작업을 그 밑에 달지 않는다.');
  stdout.writeln('');
  stdout.writeln('무엇을 열든 `batch` 를 거친다. 이 스크립트는 아무것도 만들지 않는다.');
}

Future<List<String>?> _search(String artifact) async {
  final r = await Process.run('gh', [
    'issue',
    'list',
    '--state',
    'all',
    '--search',
    artifact,
    '--json',
    'number,title,state,labels',
    '--jq',
    r'.[] | "#\(.number) [\(.state)] \(.title)"',
  ], runInShell: true);
  if (r.exitCode != 0) return null;
  return (r.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

void _recordNote(String artifact) {
  final lower = artifact.toLowerCase();
  if (!_recordKeywords.any((k) => lower.contains(k.toLowerCase()))) return;
  stdout.writeln('  ! 이 영역은 이미 record 를 갖고 있다:');
  for (final e in _recordAreas.entries) {
    stdout.writeln('    ${e.key}');
    stdout.writeln('    → ${e.value}');
  }
  stdout.writeln('    앵커를 새로 열지 말고 **conformance item** 으로 붙인다.');
  stdout.writeln('    §3 의 도달성은 채택 시점에 한 번 하는 판정이 아니다 —');
  stdout.writeln('    슬롯이 움직였으면 다시 센다.');
}
