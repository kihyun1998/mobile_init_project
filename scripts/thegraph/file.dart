// thegraph — `batch` 파일링 헬퍼
//
// 빌드 스탬프: thegraph/SKILL.md sha256 ec9136b5f672
// 값의 출처는 docs/agents/thegraph.md 의 `batch` 절이다. 갈리면 그쪽이 기준이다.
//
// **기본이 dry-run 이다.** 이슈를 실제로 만드는 유일한 스크립트이고 되돌릴 수
// 없다. 불변식 ③ 이 "아무것도 요청 없이 트래커에 닿지 않는다" 이므로 기본값도
// 그쪽에 맞춘다 — `--apply` 를 명시해야 친다.
//
// 이 스크립트는 **무엇을 filing 할지 정하지 않는다.** 후보 봉투를 사람에게
// 보이고 사람이 남긴 것만 여기로 온다.
//
// 실행:
//   dart scripts/thegraph/file.dart --title "..." --body-file /tmp/b.md \
//        --parent 26 --blocked-by 3 --label ready-for-agent [--apply]

import 'dart:io';

/// docs/agents/triage-labels.md 의 다섯. 트래커에 실재하는 것으로 확인했다.
const _labels = [
  'needs-triage', // 메인테이너가 검토해야 한다
  'needs-info', // 제보자의 추가 정보를 기다린다
  'ready-for-agent', // 명세가 충분해 AFK 에이전트가 처리 가능
  'ready-for-human', // 사람이 직접 구현해야 한다
  'wontfix', // 처리하지 않는다
];

Future<void> main(List<String> args) async {
  final opts = _parse(args);
  final title = opts['title'];
  final bodyFile = opts['body-file'];

  if (title == null || bodyFile == null) {
    stdout.writeln('사용: --title <제목> --body-file <경로>');
    stdout.writeln('      [--parent <n>] [--blocked-by <n>] [--label <이름>]');
    stdout.writeln('      [--apply]   ← 없으면 dry-run');
    stdout.writeln('');
    stdout.writeln('라벨: ${_labels.join(' · ')}');
    exit(64);
  }

  final body = File(bodyFile).existsSync()
      ? File(bodyFile).readAsStringSync()
      : null;
  if (body == null) {
    stderr.writeln('본문 파일이 없다: $bodyFile');
    exit(1);
  }

  final apply = opts.containsKey('apply');
  final repo = await _repo();
  if (repo == null) {
    stderr.writeln('저장소를 못 잡았다 — clone 안에서 실행할 것.');
    exit(1);
  }

  stdout.writeln('저장소: $repo');
  stdout.writeln('제목:   $title');
  stdout.writeln('라벨:   ${opts['label'] ?? '(없음)'}');
  stdout.writeln('부모:   ${opts['parent'] ?? '(없음)'}');
  stdout.writeln('차단:   ${opts['blocked-by'] ?? '(없음)'}');
  stdout.writeln('');

  if (!apply) {
    stdout.writeln('== dry-run == --apply 를 주면 아래를 실제로 친다.');
    stdout.writeln('  gh issue create --title ... --body-file $bodyFile');
    if (opts['parent'] != null) {
      stdout.writeln(
        '  gh api .../issues/<new>/sub_issues  (부모 ${opts['parent']})',
      );
    }
    if (opts['blocked-by'] != null) {
      stdout.writeln(
        '  gh api repos/$repo/issues/${opts['blocked-by']} --jq .id',
      );
      stdout.writeln(
        '  gh api --method POST .../dependencies/blocked_by -F issue_id=<그 id>',
      );
    }
    exit(0);
  }

  final created = await _create(title, bodyFile, opts['label']);
  if (created == null) {
    stderr.writeln('이슈 생성 실패.');
    exit(1);
  }
  stdout.writeln('만들었다: #$created');

  final parent = opts['parent'];
  if (parent != null) {
    final childId = await _databaseId(repo, created);
    if (childId == null) {
      stderr.writeln('! 하위 이슈 등록 실패 — #$created 의 database id 를 못 얻었다.');
    } else {
      final ok = await _gh([
        'api',
        '--method',
        'POST',
        'repos/$repo/issues/$parent/sub_issues',
        '-F',
        'sub_issue_id=$childId',
      ]);
      stdout.writeln(ok ? '부모 #$parent 아래로 넣었다.' : '! 하위 이슈 등록 실패.');
    }
  }

  final blocker = opts['blocked-by'];
  if (blocker != null) {
    // **숫자 database id 다.** `#number` 도 `node_id` 도 아니다 — 여기가 조용히
    // 틀리는 자리라 이 스크립트가 존재한다.
    final blockerId = await _databaseId(repo, blocker);
    if (blockerId == null) {
      stderr.writeln('! 차단 등록 실패 — #$blocker 의 database id 를 못 얻었다.');
    } else {
      final ok = await _gh([
        'api',
        '--method',
        'POST',
        'repos/$repo/issues/$created/dependencies/blocked_by',
        '-F',
        'issue_id=$blockerId',
      ]);
      stdout.writeln(ok ? '#$blocker 로 차단 걸었다.' : '! 차단 등록 실패.');
    }
  }

  stdout.writeln('');
  stdout.writeln('확인: gh issue view $created --comments');
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

Future<String?> _repo() async {
  final r = await Process.run('gh', [
    'repo',
    'view',
    '--json',
    'nameWithOwner',
    '--jq',
    '.nameWithOwner',
  ], runInShell: true);
  if (r.exitCode != 0) return null;
  final out = (r.stdout as String).trim();
  return out.isEmpty ? null : out;
}

Future<String?> _create(String title, String bodyFile, String? label) async {
  final args = ['issue', 'create', '--title', title, '--body-file', bodyFile];
  if (label != null && label.isNotEmpty) args.addAll(['--label', label]);
  final r = await Process.run('gh', args, runInShell: true);
  if (r.exitCode != 0) {
    stderr.writeln(r.stderr);
    return null;
  }
  // gh 는 만든 이슈의 URL 을 뱉는다. 끝의 번호가 이슈 번호다.
  final url = (r.stdout as String).trim().split('\n').last;
  final n = RegExp(r'/(\d+)$').firstMatch(url)?.group(1);
  return n;
}

/// GitHub 의 의존성 API 는 **숫자 database id** 를 받는다.
Future<String?> _databaseId(String repo, String issueNumber) async {
  final r = await Process.run('gh', [
    'api',
    'repos/$repo/issues/$issueNumber',
    '--jq',
    '.id',
  ], runInShell: true);
  if (r.exitCode != 0) return null;
  final out = (r.stdout as String).trim();
  return out.isEmpty ? null : out;
}

Future<bool> _gh(List<String> args) async {
  final r = await Process.run('gh', args, runInShell: true);
  if (r.exitCode != 0) stderr.writeln(r.stderr);
  return r.exitCode == 0;
}
