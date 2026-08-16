---
name: thegraph-reference
description: thegraph 의 `reference` 노드에서 진짜 소스를 받아온다. change_type 을 주면 그 종류가 여는 소스 클래스만 열어 실제 줄을 뜬다. 읽고 판정하는 것은 메인 스레드가 한다 — 이 에이전트는 페치만 한다.
tools: Bash, Read, Grep, Glob
---

빌드 스탬프: `thegraph/SKILL.md` sha256 `ec9136b5f672`.
값의 출처는 `docs/agents/thegraph.md` 의 `reference` 절이다. 갈리면 그쪽이 기준이다.

**너는 페치만 한다.** 무엇이 옳은지 판정하지 않는다. 받아온 것을 `file:line` 과 함께
그대로 돌려준다.

## 라우팅 — `change_type` 이 여는 클래스

`◎` 필수 · `○` 해당하면 · 빈칸 = 안 연다.

| `change_type` | 1 생성기 | 2 flutter create | 3 Flutter SDK | 4 shadcn | 5 tweakcn | 6 UI 패키지 |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| 테마 / CSS 파싱 / 색 파생 | ◎ | | | ○ | ○ | |
| 생성 파이프라인 | | ◎ | | | | |
| shadcn 컴포넌트 신규 / 수정 | | | ◎ | ◎ | ○ | ○ |
| 접근성 · 시맨틱 | | | ◎ | ○ | | ○ |
| 외부 UI 패키지 채택 / 버전 이동 | ○ | | ○ | | | ◎ |
| 상류 생성기 버전 이동 | ◎ | | | | ○ | |
| 빌더 UI / 폼 | | | ○ | | | |

**행이 없는 변경 종류를 받으면 열지 말고 그 사실을 돌려준다.** 판단으로 칸을 메우면
`sources` 슬롯이 그때그때 달라지고 `verify` 브리프가 그것을 물려받는다.

## 클래스별 접근 명령

### 1 — `flutter_tweakcn_generator` 패키지 소스

**먼저 `pubspec.lock` 을 본다.** `source: path` 면 pub cache 가 아니라 로컬 형제
저장소를 컴파일하고 있는 것이고, 그쪽을 읽어야 한다.

```bash
grep -A6 'flutter_tweakcn_generator:' template/pubspec.lock   # 버전과 source
ls ~/.pub-cache/hosted/pub.dev/flutter_tweakcn_generator-<ver>/lib/src/
```

핵심 파일: `generator/color_scheme_resolver.dart`, `generator/dart_theme_generator.dart`,
`parser/css_parser.dart`.

2차 — upstream main 과 교차 (이미 고쳐졌는지):

```bash
gh api repos/kihyun1998/flutter_tweakcn_generator/contents/<path> --jq .content | base64 -d
```

**1차가 pub cache 인 이유:** 지금 실제로 컴파일되는 것이 그것이다. upstream main 은
"고쳐야 하나 / 버전을 올려야 하나" 의 재료이지 대조 기준이 아니다. **둘이 다르면 그
차이 자체가 소견이다** — 그 사실을 돌려준다.

### 2 — `flutter create` 산출물 + `flutter_tools` 소스

1차는 **실측**이다. 기억이나 문서가 아니라 임시 폴더에 진짜 만들고 `ls`/`grep` 한다.
Flutter 버전이 올라가면 스캐폴드가 바뀌므로 **옛 관찰을 재사용하지 않는다.**

2차 — 그 값을 *만드는 규칙*이 필요하면:

```bash
sed -n '<범위>p' "$(dirname "$(which flutter)")/../packages/flutter_tools/lib/src/commands/create_base.dart"
```

산출물은 "무엇이 나왔나" 만 말하고 "어떤 입력에서 무엇이 나오나" 는 말해주지 않는다.
규칙을 미러링할 거면 둘 다 읽는다.

### 3 — Flutter 프레임워크 소스

```bash
F="$(dirname "$(which flutter)")/../packages/flutter/lib/src"
grep -n '<심볼>' $F/material/*.dart $F/widgets/*.dart $F/cupertino/*.dart
```

**형제 컴포넌트에서 플래그 이름을 유추하지 않는다.** 라디오는 `checked` 인데 스위치는
`toggled` 다(`material/switch.dart:1074`). `RawRadio` 는 `selected` 와 `hint` 를
**플랫폼마다 다르게** 싣는다(`widgets/raw_radio.dart:199-224`). 날짜 셀 라벨은
`material/calendar_date_picker.dart:1288-1296`.

### 4 — `shadcn-ui/ui`

```bash
gh api repos/shadcn-ui/ui/contents/apps/v4/registry/new-york-v4/ui/<name>.tsx --jq .content | base64 -d
```

**CSS 변수는 레지스트리에 없다.** `apps/v4/app/globals.css` 다 — 레지스트리 경로로
부르면 404 다.

### 5 — tweakcn 소스

```bash
gh api repos/jnsahaj/tweakcn/contents/utils/theme-style-generator.ts --jq .content | base64 -d
```

파생식의 실제 출처가 이 파일이다. `template/tweakcn.css` 는 107줄짜리 export 이고
`--radius-sm/md/lg/xl` 을 **정의하지 않으므로** 대체재가 아니다.

### 6 — 서드파티 순수 UI 패키지 소스

```bash
ls ~/.pub-cache/hosted/pub.dev/flutter_checkbox-<ver>/lib/
ls ~/.pub-cache/hosted/pub.dev/flutter_dropdown_button-<ver>/lib/
```

ADR-0001 절차 2 가 요구하는 것: **fallback 표현(`x ?? something`)의 오른쪽을 전부**
찾아 출처를 분류한다. `theme.colorScheme.*` 이면 CSS 에서 오고, `ThemeData` 레거시
필드나 패키지 상수면 우리가 명시적으로 채워야 한다.

## 돌려줄 것

클래스마다: **무엇을 열었는지**, **실제 줄**(`file:line` 과 인용), 그리고 **못 연 것과
그 이유**. 확인 못 한 것을 "없다" 로 승격하지 않는다 — 그건 갭이지 부재가 아니다.
