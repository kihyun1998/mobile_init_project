# theflow 바인딩

`theflow` 스킬은 방법만 들고 있고 프로젝트별 값은 전부 이 문서에서 읽는다. 여기
적힌 것이 계약이다 — 스킬의 일곱 단계가 "무엇과 대조하고, 어디에 선을 긋고, 무엇을
증명이라 부르고, 어떤 게이트를 돌리는지" 를 이 파일에 위임한다.

이 문서는 `/grill-the-flow` 로 작성됐다. 값이 실제와 갈리기 시작하면 다시 돌린다.

---

## Reasoning bindings (전 단계에 적용)

**교차 확인하는 prior art** — [tweakcn](https://tweakcn.com) 의 CSS 토큰 체계,
shadcn/ui 의 컴포넌트 의미론, Flutter `ColorScheme` 의 Material 의미론.

**Tie-breaker — 생성기가 실제로 뱉는 것이 이긴다.** 미리보기의 진실 기준은 "예쁨"
도 "Material 규범" 도 아니고 **"생성 결과와 같은가"** 하나다. 규범은 교차 확인용일
뿐이며, 규범과 어긋난다는 사실은 미리보기를 고칠 이유가 **아니라 상류 이슈를 올릴
이유**다. (예: `input → outlineVariant`, `card → surfaceContainerLowest` 는 Material
의미론으로 보면 어색하지만 생성기가 실제로 그렇게 매핑한다. 미리보기는 생성기를
따라간다.)

이 규칙은 3층 경계선(Step 2)과 한 몸이다 — 규범 쪽이 옳아 보여도 하류에서
"고쳐두는" 것이 금지이므로, 판단은 항상 *상류에 보고하고 하류는 상류를 미러링* 으로
떨어진다.

---

## 모듈 맵

루트에 `pubspec.yaml` 이 없다. Flutter 프로젝트 **둘**이고 워크스페이스로 묶여 있지
않다.

| 모듈 | 정체 | 테스트 |
|---|---|---|
| `template/` | 뿌릴 원본이자 그 자체로 `flutter run` 되는 모바일 앱 | `template/test/` |
| `builder/` | `template/` 을 찍어내는 데스크톱 GUI (macOS + Windows) | `builder/test/` |

`builder/pubspec.yaml` 이 `mobile_init_project: {path: ../template}` 로 template 을
문다. 미리보기는 사본이 아니라 **같은 파일**을 컴파일해 렌더한다.

**Step 7 사각지대 — top-level 테스트 명령이 존재하지 않는다.** 워크스페이스가 없으니
`cd builder && flutter test` 는 `template/test/` 를 돌리지 않고 그 반대도 마찬가지다.
`builder` 테스트가 `path:` 덕에 template **코드를 컴파일하기는** 하지만, 그건 컴파일이지
template 자체 테스트가 아니다. 항상 양쪽을 따로 돌린다.

---

## Step 1 — 레퍼런스 라우팅

| 변경 종류 | 읽을 진짜 소스 |
|---|---|
| 테마 / CSS 파싱 / 색 파생 | **1차** 핀 박힌 버전의 실제 소스: `~/AppData/Local/Pub/Cache/hosted/pub.dev/flutter_tweakcn_generator-<ver>/lib/src/` (macOS: `~/.pub-cache/hosted/pub.dev/…`). 특히 `generator/color_scheme_resolver.dart`, `generator/dart_theme_generator.dart`, `parser/css_parser.dart`. **2차** `gh api repos/kihyun1998/flutter_tweakcn_generator/contents/<path> --jq .content \| base64 -d` 로 upstream main 과 교차 — 이미 고쳐졌는지 확인한다. |
| 생성 파이프라인 (`flutter create`, 복사, 치환) | 실제 `flutter create` 출력물. 기억이나 문서가 아니라 임시 폴더에 진짜 만들어 놓고 `ls`/`grep` 한다. Flutter 버전이 올라가면 스캐폴드가 바뀌므로 옛 관찰을 재사용하지 않는다. |
| 템플릿 앱 코드 (컴포넌트, provider, l10n) | `template/lib/` 의 형제 구현. shadcn 13종은 서로가 서로의 prior art 다 — 새 컴포넌트는 기존 것의 토큰 사용법·`.w/.h/.sp` 관례를 그대로 따른다. |
| 빌더 UI | `builder/lib/src/ui/` 의 형제 페이지. **`.w/.h/.sp/.r` 금지** (ScreenUtil 싱글톤이 프로세스 전역이라 폰 배율이 딸려온다). |

**1차가 pub cache 인 이유:** 지금 실제로 컴파일되는 것이 그것이다. upstream main 은
"고쳐야 하나 / 버전을 올려야 하나" 를 판단하는 재료이지 대조 기준이 아니다. 둘이
다르면 그 차이 자체가 소견이다.

**요약 fetch 를 쓰지 말 것.** 큰 파일에서 메서드 본문이 조용히 날아가서, 있는 핸들러가
없는 것으로 읽힌다. 파일을 받아 `grep -n` / `sed -n` 으로 실제 줄을 본다.

### hidden state 목록이 사는 곳

별도 파일을 두지 않는다. **상수와 그 doc-comment 가 목록이다** — 이것들을 먼저 읽고,
늘어나면 여기에 추가한다:

- `builder/lib/src/preview/preview_theme.dart` — `colorTokens`, 그리고 클래스
  doc-comment 가 "아직 사본으로 남은 두 곳"을 명시한다.
- `builder/lib/src/generation/project_generator.dart` — `copyEntries`,
  `themeCssEntry`, `templatePackageName`, `templateDisplayName`,
  `_preservedPrefixes`, `exampleOnlyDependencies`, `exampleDirSegments`,
  `exampleTestDirSegments`, `homeScreenSegments`, `arbDirSegments`. 각각이
  "템플릿이 이렇게 생겼다" 는 가정이고, 템플릿이 움직이면 조용히 낡는 자리다.
  `themeCssEntry` 는 템플릿 pubspec 의 `flutter_tweakcn_generator: input:` 과
  묶여 있고, 테스트가 대조한다.
  `exampleTestDirSegments` 는 `exampleDirSegments` 와 **한 쌍이다** —
  `copyEntries` 가 `test` 를 통째로 복사하므로 `lib/example` 만 지우면 그것을
  import 하는 테스트가 남아 결과물이 컴파일되지 않는다. **예제에 의존하는
  테스트는 `test/example/` 안에 둔다는 것이 규칙이다.** 밖에 두면 이 상수가
  못 잡고, `project_generator_test.dart` 의 "예제를 가리키는 참조가 남지 않는다"
  가 뒤늦게 잡는다 (#24 에서 실제로 그렇게 걸렸다).

템플릿에 파일·의존성·언어를 추가했다면 **이 상수들부터** 확인한다. 컴파일러가
봐주지 않는다.

---

## Step 2 — 경계 규칙 (3층)

```
flutter_tweakcn_generator (상류, 별도 저장소, 손 못 댐)
        ↑ 결함은 우회 금지 — 상류 이슈로 올린다
template/   = core / mechanism   (앱 런타임: 컴포넌트, 테마 소비, provider, l10n)
        ↑ path: 의존. 사본 금지
builder/    = consumer / policy  (생성 정책: allowlist, 치환, 옵션, 폼, 미리보기)
```

**mechanism (template 이 갖는다)** — 컴포넌트가 색을 `context.tweakcnColors` 로 읽는
방식, 화면 골격, 로컬라이제이션 구조. template 은 **builder 의 존재를 모른다.**
"빌더가 치환하기 좋게" 코드를 비트는 순간 템플릿은 그 자체로 돌아가는 앱이기를
멈춘다.

**policy (builder 가 갖는다)** — 무엇을 복사할지, 무엇을 치환할지, 예제를 뺄지,
어떤 언어를 남길지, 어떤 플랫폼을 만들지. 전부 사용자가 폼에서 고르는 것이고
template 안에 흔적이 없어야 한다.

**consumer 가 정의상 갖는 것** — 폼 검증, 진행 상황/로그 표시, 파일 다이얼로그,
경로 저장(`shared_preferences`), 프로세스 실행, 데스크톱 레이아웃.

**상류 결함은 하류에서 우회하지 않는다.** 생성기의 동작이 틀렸거나 필요한 API 가
private 이면, builder 안에 "임시 매핑" 을 넣고 넘어가는 것이 아니라 상류 이슈로
올린다. 전례가 실물로 있다 — 미리보기 파생 매핑을
`kihyun1998/flutter_tweakcn_generator#11` 로 올려 0.4.0 의
`TweakcnColors.fromMap` · `TweakcnRadius.fromRadius` · `TweakcnShadows.fromShadowMap`
으로 받아왔고, 그만큼 사본이 사라졌다. 당장 받을 수 없어 사본을 둬야 한다면
**낡았을 때의 증상을 doc-comment 에 적어둔다** (현재 `preview_theme.dart` 가 그렇게
하고 있다).

### 크로스레포 규칙의 적용 범위

**"두 consumer 가 같은 우회에 도달하면 신호" 와 after-merge downstream loop 는 N/A.**
이 저장소는 아무것도 publish 하지 않는다(양쪽 `publish_to: none`). template → builder
seam 은 저장소 안에 있어서 드리프트가 **같은 PR·같은 게이트에서 즉시 터진다** — 볼 수
없는 consumer 가 없다.

**이미 생성된 프로젝트는 consumer 가 아니다.** 생성 순간 손을 떠난 포크이고 역전파
경로가 없다 (이슈 #1 이 "템플릿 업그레이드 diff 제공" 을 out-of-scope 로 명시).
template 을 고쳐도 기존 생성물에 대해 할 일은 없다.

단, **상류 방향은 살아 있다** — SDK 하한 같은 것은 상류에서 내려와 template 을 거쳐
생성되는 모든 프로젝트로 그대로 따라간다. `template/pubspec.yaml` 의 `environment:`
를 거짓으로 두면 낮은 SDK 를 쓰는 사람의 `pub get` 은 통과시키면서 컴파일만
실패시킨다 (커밋 `b081ae1` 이 실제로 고친 것).

---

## Step 4 — 층별 증명 방법

| 층 | 진짜 왕복 |
|---|---|
| **생성 파이프라인** | **슬라이스당 최소 1회 진짜 생성.** 임시 폴더에 실제로 만들고, 그 결과물 안에서 `flutter analyze` 와 `flutter test` 를 돌린다. 예제를 끄는 변경이면 끈 상태로도 한 번. fake runner 테스트는 여기서 smoke 이지 증명이 아니다. |
| **미리보기** | CSS 문자열을 넣고 **렌더된 픽셀의 색**을 확인한다 (`builder/test/support/rendered_color.dart`). 파싱 함수를 단위 테스트하지 않는다 — 파싱이 맞아도 테마에 실리지 않으면 사용자에겐 실패다. |
| **미리보기 ↔ 생성 결과 일치** | 같은 CSS 로 진짜 생성해서 앱을 띄우고 주요 색을 눈으로 대조한다. 자동화할 수 없는 마지막 한 칸이고, 이슈 #9 의 수용 기준이기도 하다. |
| **템플릿 앱** | `template/` 에서 `flutter test`, 그리고 화면이 걸린 변경이면 `flutter run`. |

### 함정

- **fake runner 는 `flutter create` 도 `build_runner` 도 돌리지 않는다.** 복사·치환이
  전부 초록인데 결과물이 컴파일 안 되는 상태가 얼마든지 가능하다. 그래서 위의 "진짜
  생성 1회" 가 협상 대상이 아니다.
- **템플릿 CSS 는 여러 토큰 쌍이 같은 값이다.** `border`/`input`, `background`/`card`
  가 그렇다. 매핑을 틀려도 기본 CSS 로는 티가 나지 않는다 — **자기 자신을 오독할 수
  있는 측정**이다. 매핑을 건드렸으면 쌍이 서로 다른 값인 CSS 로 확인한다.
- **밝은 테마만 재는 것도 같은 함정이다.** 토큰 충돌은 light 에서만 일어나는 것이
  아니라 **light 에서 유독 심하다.** 실측(#31): `ThemeData.cardColor` 는 light 에서
  `card`·`background`·`popover` 와 전부 같아 어느 것에 매핑해도 맞아 보이지만
  dark 에서는 `background` 뿐이고, `ThemeData.primaryColor` 는 light 에서
  `colorScheme.primary` 인데 **dark 에서는 `colorScheme.surface`** 다. 매핑을
  건드렸으면 **dark 로도 잰다** — 실제로 변이 테스트에서 light 는 통과시키고
  dark 만 잡아낸 매핑 오류가 나왔다.
- **위젯 테스트가 초록인 것은 "그 위젯이 소비한 것" 까지만 증명한다.** 색을 assert
  하지 않는 렌더 테스트는 테마 회귀를 못 잡는다.

---

## Step 5 — 무조건 완전성 패스가 도는 경로 (성역)

판단과 무관하게 돈다. diff 가 작아 보인다는 이유로 빠져나갈 수 없고, **두 번째
반박 렌즈(stance 분리)를 사는 예산도 이 둘에서만 쓴다.**

1. **`builder/lib/src/preview/preview_theme.dart` 의 파생·매핑.**
   상류 생성기가 하는 것과 한 글자라도 갈리면 미리보기가 거짓말을 시작하고, 그
   순간 이 도구의 존재 이유가 사라진다. 증상이 컴파일 에러가 아니라 "색이 좀 다름"
   이라 조용히 지나간다. 위 Step 1 의 pub cache 소스와 토큰 단위로 대조한다.

2. **`builder/lib/src/generation/project_generator.dart` 의 복사 allowlist 와 파괴적
   파일 조작.** `copyEntries`, `_copyTemplate` 의 `deleteSync(recursive: true)`,
   `_validate` 의 기존 디렉토리 가드. **사용자 파일시스템을 지우는 유일한 곳이고
   되돌릴 수 없다.** allowlist 가 새면 `flutter create` 가 방금 만든 플랫폼
   스캐폴드를 낡은 것으로 덮어쓴다. blocklist 로 바꾸자는 제안은 여기서 막는다 —
   allowlist 누락은 컴파일 실패로 즉시 드러나지만 blocklist 누락은 조용히 통과한다.

그 외 경로는 기본 규칙대로 **열거 위험**으로 판단한다. 닫힌 표면이라 건너뛰었다면
건너뛴 이유를 명시한다.

---

## Step 6 — 행동을 기술하는 표면

변경이 이 중 무엇이든 낡게 만들었으면 같은 변경에서 쓸어낸다.

- **`CLAUDE.md`** — 이 저장소의 정체성과 불변식. 작업 규칙이 바뀌면 여기가 1순위다.
- **`docs/agents/*.md`** — 이 문서 포함. 바인딩이 실제와 갈리면 고친다.
- **코드 doc-comment** — 특히 `preview_theme.dart` 와 `project_generator.dart` 의
  상수 주석. 이것들이 hidden state 목록 역할을 겸하므로(Step 1) 낡으면 그냥 틀린
  주석이 아니라 **틀린 목록**이 된다.
- **이슈 본문** — #1 이 사실상 PRD 다. 구현 결정이 뒤집히면 #1 의 해당 절을 고친다.
  자식 이슈가 닫힐 때 spine 에 접어 넣는 것(확인/반증된 가정, 측정한 숫자, 아직 열린
  것)도 여기다.
- **`template/tweakcn.css`** — 고치면 `dart run flutter_tweakcn_generator` 로
  `tweakcn_theme.g.dart` 까지 만들어 **커밋한다**. 이게 미리보기가 import 하는 바로
  그 파일이라, 낡으면 "붙여넣지 않았을 때의 미리보기" 가 생성 결과와 갈린다.
- **`template/lib/core/localization/l10n/*.arb`** — 문구가 바뀌면 `intl_utils:generate`
  로 생성물까지 만들어 **커밋한다** (생성물이 커밋되어 있어야 빌더가 복사만으로
  컴파일된다).

**changelog / 릴리스 노트: 없다.** publish 하지 않으므로 스냅샷 문제도 없다.
**공개 API 문서 표면: 없다.** pub.dev 에 올라가는 패키지가 아니다.

**툴체인 하한 매니페스트** — `template/pubspec.yaml` 과 `builder/pubspec.yaml` 의
`environment:`. 이 값은 생성되는 모든 프로젝트로 따라가므로 실제로 확인한 값만 적는다.

### 결정 기록 (promotion 목적지)

`docs/adr/0001-<slug>.md` 부터 **필요해지는 그때 만든다** (`docs/agents/domain.md` 가
싱글 컨텍스트 구조로 이미 그려둔 자리). 용어 자체가 바랬으면 루트 `CONTEXT.md` 도
같이 만든다.

- ADR 은 **도출을 담는다** — 이미 내린 답을 나열하기만 하면 서류함이고, 다음 조합은
  또 개별 결정이 된다.
- 작업 방식까지 바꾸는 규칙이면 `CLAUDE.md` 에는 **한 줄 포인터만** 남긴다. 전문을 두
  곳에 두면 갈라진다.

**현재 record 를 가진 영역: 없다 (accepted 0, proposed 0).** 그러므로 지금은 어떤
sibling 을 만나도 conformance item 으로 붙을 곳이 없고, 첫 클러스터는 spine 이슈로
연다.

### 트래커

GitHub 이슈, `gh` CLI (`docs/agents/issue-tracker.md`). **parent/child 와 native
dependency 를 둘 다 실제로 쓰고 있다** — #9 가 #1 의 하위 이슈이고 #3·#4 에
blocked-by 로 걸려 있다. 따라서 follow-up 트리와 spine 로스터 모두 트래커가 지탱한다.
본문에 손으로 유지하는 로스터를 만들지 않는다.

라벨은 `docs/agents/triage-labels.md` 의 다섯 가지.

---

## Step 7 — 게이트 매트릭스

**top-level 명령이 없다. 항상 양쪽을 따로 돌린다.**

```bash
cd template && flutter analyze && flutter test
cd builder  && flutter analyze && flutter test
```

파이프라인을 건드렸으면 여기에 **생성 결과물 게이트**(Step 4)가 붙는다:

```bash
# 임시 폴더에 진짜 생성한 뒤
cd <생성된 프로젝트> && flutter analyze && flutter test
```

### 사각지대

- **`builder` 테스트는 `template/test/` 를 돌리지 않는다.** `path:` 의존이라 template
  코드를 **컴파일** 할 뿐이다. template 만 고쳤어도 양쪽 다 돌린다 — 컴포넌트 변경이
  빌더 미리보기를 깨는 것이 정확히 이 저장소가 막으려는 사고다.
- **생성물은 커밋되어 있다.** 고친 것에 따라 **도구가 다르다** — 셋을 한 덩어리로
  묶어 기억하면 안 된다.
  - provider → `dart run build_runner build --delete-conflicting-outputs`
  - arb → `dart run intl_utils:generate`
  - `tweakcn.css` → **`dart run flutter_tweakcn_generator`**

  **테마는 `build_runner` 가 만들지 않는다.** 상류의 `build.yaml` 은
  `.tweakcn.css` → `.tweakcn.dart` 만 걸고, pubspec 의
  `flutter_tweakcn_generator:` 블록(`input`/`output`)은 `bin/` 의 CLI 만 읽는다.
  우리 파일 이름은 `tweakcn.css` 라 builder 패턴에 애초에 걸리지 않는다.
  실측(#9): 템플릿의 `--primary` 를 바꾸고 `build_runner` 를 돌리면
  `tweakcn_theme.g.dart` 가 **한 글자도** 안 바뀌고, CLI 를 돌리면 바뀐다.

  **로컬 게이트는 이걸 안 본다** — analyze 도 test 도 낡은 생성물을 초록으로
  통과시킨다. CI 의 `codegen` 잡이 재생성 후 `git diff --exit-code` 로 잡아주지만,
  그건 PR 을 올린 뒤에야 알려주므로 로컬에서 먼저 돌리는 편이 빠르다.
  - 전례: PR #16 이 `theme_provider.dart` 를 고치고 재생성을 잊어서 riverpod 소스
    해시가 낡은 채로 머지됐다. 그때 4개 잡이 전부 초록이었다 — `codegen` 잡은
    그 사건 때문에 생겼다.
  - 전례: #9 까지 그 `codegen` 잡이 **테마 CLI 를 안 돌리고 있었다.** 같은 사고를
    막으려고 만든 잡에 정작 세 도구 중 하나가 빠져 있었던 것이고, "생성물 =
    build_runner" 라는 이 문서의 문장 자체가 그 구멍의 출처였다.
- **생성물의 줄바꿈은 `.gitattributes` 가 `eol=lf` 로 못박고 있다.** 생성 도구는
  항상 LF 로 쓰는데 `text=auto` 아래 Windows 체크아웃은 CRLF 라, 못박지 않으면
  도구를 한 번 돌리는 것만으로 **커밋된 생성물이 통째로 수정으로 뜬다** —
  내용은 한 글자도 안 바뀐 채로. (`git diff` 는 아무것도 못 보여주는데 `status`
  만 더러운 상태가 된다.) 생성물을 새로 추가하면 그 규칙에도 넣는다. 지금 무엇이
  덮여 있는지는 `git ls-files --eol` 로 본다 — `w/crlf` 인 생성물이 있으면 빠진
  것이다.
- **`builder/test/macos_sandbox_test.dart`** — `flutter create` 로 `macos/` 를 다시
  만들면 app-sandbox 가 기본값으로 되살아나고, 그러면 `Directory.current` 가 컨테이너로
  바뀌어 `../template` 해석과 `Process.run('flutter', …)` 이 둘 다 죽는다.
- **`builder/test/template_link_test.dart`** — template 컴포넌트가 빌더 위젯 트리에서
  렌더된다는 전제. 이게 깨지면 미리보기의 약속이 무너진 것이다.
- **지금 개발 머신이 아닌 OS** — 프로세스 실행과 경로 조합이 첫 번째로 터지는
  자리다. `p.join` 을 쓰고 `runInShell: true` 로 부른다(Windows 는 `flutter.bat`).
  로컬에서는 한 OS 만 볼 수 있으므로 **이 사각지대는 CI 가 덮는다** — 아래 참고.
- **포맷은 게이트다.** `dart format --output=none --set-exit-if-changed lib test` 를
  양쪽 모듈에서 통과해야 한다. CI 는 이 검사를 **ubuntu 에서만** 돌린다 —
  `.gitattributes` 가 `* text=auto` 라 Windows 체크아웃은 CRLF 이고, 줄바꿈 때문에
  코드가 멀쩡한데 빨개지는 것을 피하기 위해서다. 포맷은 OS 를 타지 않는다.

### 브랜치 / PR / CI

- 브랜치: `<type>/<slug>` — 실물 전례 `feat/tweakcn-0.4.0`, `test/windows-process-runner`.
- **squash PR** 로 병합하고 제목에 이슈 번호를 남긴다 (`feat: 지원 언어 선택 (#8)`).
  PR 이 이슈를 닫는다.
- **CI 는 `.github/workflows/gates.yml` 하나다** (워크플로 이름 `gates`). 위 매트릭스를
  그대로 돌리며, PR 과 main 푸시에서 뜬다. 갈리면 **바인딩이 기준이고 워크플로를
  맞춘다** — 워크플로 주석에도 그렇게 적어뒀다.
  - `format` 잡 — ubuntu 에서 포맷만.
  - `codegen` 잡 — ubuntu 에서 l10n·codegen 을 재생성하고 `git diff --exit-code`.
    커밋된 생성물이 소스보다 낡았는지를 보는 유일한 게이트다.
  - `gates` 잡 — **ubuntu · macOS · Windows 3종**에서 두 모듈의 analyze + test.
    `fail-fast: false` 라 한 OS 가 깨져도 나머지 결과가 남는다. 어느 OS 에서만
    깨지는지가 진단의 절반이다.
  - Flutter 버전은 워크플로의 `FLUTTER_VERSION` 으로 **고정**한다. 값은 그 파일이
    출처이니 여기 옮겨 적지 않는다 — 두 곳에 두면 한쪽이 낡는다. `channel: stable`
    로 두면 Flutter 가 새로 나오는 날 아무도 코드를 안 건드렸는데 main 이 빨개진다.
    올릴 때는 로컬 게이트를 돌려보고 의도적으로 올린다.
- **CI 가 로컬 게이트를 대체하지 않는다.** 구현 중에 CI 를 쳐다보고 있지 말 것 —
  로컬 게이트가 같은 것을 훨씬 빨리 돌려준다. CI 의 값은 **다른 OS** 와 머지 게이트다.
- 게이트를 파이프에 물려 돌리지 않는다 — `flutter test | tail -1 && commit` 은 항상
  커밋된다.

### 릴리스 / downstream loop

**N/A — publish 하는 것이 없다.** 빌더는 저장소를 받아 `flutter run` 하거나 로컬에서
`.app`/`.exe` 로 빌드해 쓰는 도구이고, 서명·공증·스토어 배포는 이슈 #1 에서
out-of-scope 다. 생성된 프로젝트는 포크라 마이그레이션 대상이 아니다(Step 2).

**consumer 링크 메커니즘도 이미 상시 켜져 있다** — `builder/pubspec.yaml` 의
`path: ../template`. 별도로 링크할 일이 없고, template 변경은 다음 `flutter test` 에서
바로 드러난다.

---

## War-story index

규칙이 추상론으로 읽히지 않게 하는, 실제로 뭔가를 잡은 전례들.

- **#1 (spec)** — "미리보기용 사본을 만들지 않는다". 사본을 만드는 순간 드리프트가
  구조적으로 가능해지고, 그게 이 도구의 유일한 가치를 죽인다.
  → Step 2 의 `path:` 의존과 `template_link_test.dart` 가 이 결정의 집행부다.
- **`kihyun1998/flutter_tweakcn_generator#11` → 0.4.0** — 하류에 임시 매핑을 두는
  대신 상류에 런타임 팩토리를 요청해서 받아왔다. 사본이 셋 사라졌다.
  → "상류 결함은 하류에서 우회하지 않는다" 의 실물 증거 (커밋 `df0df47`).
- **`kihyun1998/flutter_tweakcn_generator#23·#24·#27·#28` → 0.5.0** — 위 항목의
  **나머지 반쪽**이다. #11 이 "우회하지 말고 상류에 올린다" 였다면 이쪽은 **상류가
  고쳐준 뒤에 하류의 우회를 실제로 걷어내는** 쪽이다. 0.4.0 은 폰트 하나를 못 받은
  것과 아무것도 생성 못한 것이 똑같이 `1` 이라, 빌더가 테마 단계를 파이프라인
  **맨 뒤로 미루는** 우회를 이고 있었다 (상류 `bin/` 주석이 우리를 실명 없이
  인용한다). 0.5.0 이 `2`(테마는 썼고 필요한 것이 빠짐)를 갈라준 뒤에도 빌더는
  non-zero 를 전부 하드 실패로 읽어서, **`flutter run` 이 그냥 되는 결과물을 "실패"로
  띄우고 있었다** — 상류가 애써 갈라준 것을 하류에서 도로 뭉갠 셈이다.
  → 상류를 올리는 변경은 **버전만 올리고 끝나지 않는다.** 그 버전이 낡게 만든 하류의
  근거·우회·주석까지 같은 변경에서 쓸어내야 한다 (Step 6 "reclaim now-false
  rationale"). 실물: `process_runner.dart` 의 감시견 근거, `system_process_runner_test`
  의 재현 대상, `_postProcessing` 의 순서 이유가 전부 그 버전에 묶여 있었다.
- **커밋 `b081ae1`** — SDK 하한이 `flutter create` 가 찍어둔 값(그때 개발 머신에 깔려
  있던 것)이라 실제 필요값보다 9개 마이너 높았다. 반대 방향으로 틀렸다면 `pub get` 은
  통과시키면서 컴파일만 실패시켰을 값이다.
  → "external fact 는 검증 대상" + "하한은 상류에서 하류로 그대로 내려간다".
- **커밋 `aec8583`** — 프로세스 러너 검증이 macOS 에서만 돌고 있었다.
  → "게이트가 안 닿는 곳" 은 다른 머신에서 처음 발견된다.
- **#31 (`shadcn_select` → `flutter_dropdown_button`)** — 티켓 본문이 들고 있던 실측표가
  **두 줄 틀렸다.** light 에서만 쟀기 때문이다: `cardColor` 를 CSS `card` 로,
  `primaryColor` 를 CSS `primary` 로 적었는데 실제 출처는 `colorScheme.surface` 와
  `colorScheme.primary` 이고, dark 에서 각각 `background` 와 **`surface`** 로 갈린다.
  즉 "액센트가 배경색이 되는" 경로가 표에는 통과로 적혀 있었다.
  → **Step 1 의 "external fact 는 검증 대상" 은 자기 저장소의 이슈 본문에도 걸린다.**
  티켓의 숫자를 물려받지 말고 다시 잰다. 덤으로 변이 테스트에서 같은 구조가 재현됐다
  — `popover`→`card` 로 바꾸는 변이를 **light 테스트는 통과시키고 dark 만 잡았다.**
- **`_withoutDependencies` 의 섹션 판정** — pubspec 에는 `flutter:`, `flutter_intl:`,
  `flutter_tweakcn_generator:` 처럼 같은 들여쓰기를 쓰는 설정 블록이 여럿이라, 섹션을
  안 보고 이름만 맞추면 엉뚱한 설정이 통째로 사라진다.
  → 성역 경로 2번이 왜 성역인지.

새 전례가 쌓이면 `docs/agents/lessons.md` 로 뽑아낸다 (아직 없다).
