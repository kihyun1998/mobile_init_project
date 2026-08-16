---
name: thegraph-sweep
description: thegraph 의 `sweep` 노드. 변경이 낡게 만든 표면을 이 저장소의 표면 목록 8개에 대고 훑는다. 표면마다 읽는 법과 해야 할 일이 다르다.
tools: Read, Grep, Glob, Bash, Edit
---

빌드 스탬프: `thegraph/SKILL.md` sha256 `ec9136b5f672`.
값의 출처는 `docs/agents/thegraph.md` 의 `sweep` 절이다. 갈리면 그쪽이 기준이다.

**왜 훑는지는 방법이고 `thegraph` 에 있다.** 여기에는 이 저장소의 표면 목록만 있다.

변경이 아래 중 무엇을 낡게 만들었으면 **같은 변경에서** 쓸어낸다.

## 1 — `CLAUDE.md`

이 저장소의 정체성과 불변식. 작업 규칙이 바뀌면 1순위다.
**전문이 아니라 한 줄 포인터만 둔다** — 전문을 두 곳에 두면 갈린다.

"상류 대기" 표도 여기다. 상류가 고쳐줘서 풀린 항목이 있으면 그 행을 지우고, 그 행이
지시하는 후속(버전 올리기 → 값 넘기기 → 테스트 뒤집기)을 같은 변경에서 한다.

## 2 — `docs/agents/*.md`

`thegraph.md` 가 값의 기준이고 `theflow.md` 는 **포인터**다.
포인터가 가리키는 절 이름을 바꿨으면 양쪽을 고친다.

## 3 — 코드 doc-comment

`preview_theme.dart` · `project_generator.dart` · `application_id.dart`.

**이것들이 hidden state 목록을 겸하므로 낡으면 틀린 주석이 아니라 틀린 목록이 된다.**
상수를 더하거나 지웠으면 `thegraph.md` 의 `enumerate` 절도 같이 고친다.

`project_generator.dart` 의 `emptyHomeScreenSource`(:387) 안에 있는 문장은 **주석이
아니라 생성물로 나가는 문서**다 — 예제를 끄면 모든 생성 프로젝트의 `home_screen.dart`
에 그대로 찍힌다.

## 4 — 이슈 본문

#1 이 PRD 다(**닫혀 있다**). 구현 결정이 뒤집히면 해당 절을 고친다.
자식이 닫힐 때 앵커에 접어 넣는 것(확인/반증된 가정, 측정한 숫자, 아직 열린 것)은
`spine` 의 flush 다 — 판정은 본문에 편집해 넣고 증거는 append-only 코멘트로.

## 5 — `template/tweakcn.css`

고쳤으면 **`dart run flutter_tweakcn_generator`** 로 `tweakcn_theme.g.dart` 까지
만들어 **커밋한다.**

**`build_runner` 가 아니다.** 상류 `build.yaml` 은 `.tweakcn.css` → `.tweakcn.dart`
만 걸고 pubspec 의 `flutter_tweakcn_generator:` 블록은 CLI 만 읽는다. 우리 파일
이름은 `tweakcn.css` 라 builder 패턴에 애초에 안 걸린다. 실측(#9): `--primary` 를
바꾸고 `build_runner` 를 돌리면 생성물이 **한 글자도** 안 바뀐다.

## 6 — `template/lib/core/localization/l10n/intl_{ko,en}.arb`

고쳤으면 `dart run intl_utils:generate` 로 생성물까지 만들어 **커밋한다.**
생성물이 커밋되어 있어야 빌더가 복사만으로 컴파일된다.

## 7 — 툴체인 하한

양쪽 `pubspec.yaml` 의 `environment:`. 이 값은 생성되는 **모든** 프로젝트로 따라가므로
**실제로 확인한 값만** 적는다. 거짓으로 두면 낮은 SDK 를 쓰는 사람의 `pub get` 은
통과시키면서 컴파일만 실패시킨다(커밋 `b081ae1` 이 실제로 고친 것).

## 8 — `docs/adr/`

**write 표면이다.** 변경이 어떤 record 의 전제를 거짓으로 만들었으면 그 record 를 같은
변경에서 수정한다 — 상태 노트, superseded-by 줄.

ADR-0001 §3 의 도달성은 **채택 시점에 한 번 하는 판정이 아니다.** 슬롯이 움직였으면
다시 센다.

---

## 없는 표면 — 찾지 않는다

- **changelog / 릴리스 노트: 없다.** publish 하지 않으므로 스냅샷 문제도 없다.
- **공개 API 문서: 없다.** pub.dev 에 올라가는 패키지가 아니다.
- **`README.md`** 는 `flutter create` 스텁이다. 표면으로 세지 않는다.
- **루트 `CONTEXT.md` 는 없고, 없는 것이 답이다.** `domain.md` 가 "부재를 지적하지
  말고 먼저 만들라고 제안하지도 말 것" 을 명시한다.

## 낡은 근거를 회수한다

연속된 변경에서 **앞서 쓴 정당화가 뒤의 변경으로 거짓이 되는데 아무도 다시 안 읽는다.**
최근 근거를 훑어 새 행동이 거짓으로 만든 것을 철회한다. 살아남는 이유는 대개
전이적인 것들이다.

실물: 상류 0.5.0 을 받았을 때 `process_runner.dart` 의 감시견 근거,
`system_process_runner_test` 의 재현 대상, `_postProcessing` 의 순서 이유가 전부 옛
버전에 묶여 있었다. **버전만 올리고 끝나지 않는다.**
