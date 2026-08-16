# thegraph 빌드

`thegraph` 스킬은 노드 타입 카탈로그와 네 불변식과 추론 습관만 들고 있고, **이
저장소의 그래프** — 어떤 노드가 존재하고, 몇 개이고, 각각의 가드가 무엇인지 — 는 이
문서에서 읽는다. **이 파일이 계약이다.**

`/grill-the-graph` 로 컴파일했다. 1차 입력은 `docs/agents/theflow.md` 이고
`CLAUDE.md`·`docs/adr/0001`·`.github/workflows/gates.yml`·양쪽 `pubspec.yaml`·트래커로
대조했다. 값이 실제와 갈리기 시작하면 다시 돌린다.

**빌드 스탬프:** `thegraph/SKILL.md` sha256 `ec9136b5f672` · 2026-08-14 컴파일.

## `theflow.md` 와의 관계

**겹치는 값은 전부 이 문서로 옮겼고 `theflow.md` 는 그 자리에 포인터를 남긴다.**
같은 값을 두 곳에 두면 갈리고, 갈렸을 때 아무것도 그것을 검사하지 않는다 — 실제로
컴파일 시점에 이미 여섯 군데가 갈려 있었다.

`theflow.md` 에 남는 것은 `theflow` 스킬의 일곱 단계 구조와 그 스킬 전용 서술뿐이다.
`theflow` 로 시작한 작업은 계속 돌아가되, **값은 여기서 읽는다.**

## 이슈 번호 표기

**`#NN` 은 이 저장소의 이슈다.** 상류 이슈는 저장소를 붙여 쓴다:

- `ftg#NN` — `kihyun1998/flutter_tweakcn_generator`
- `fcb#NN` — `kihyun1998/flutter_checkbox`
- `fdb#NN` — `kihyun1998/flutter_dropdown_button`

이 규약이 없으면 상류 `ftg#28` 과 이 저장소의 `#28`(존재하지 않는다)이 구별되지
않는다. 컴파일 전 문서가 실제로 그 상태였다.

---

## 실행 상태

런 중에는 저장소 루트의 `.thegraph/`, 영속은 GitHub 이슈다.
`.gitignore` 가 `.thegraph/` 를 덮는다.

---

## 노드 로스터

`개수` 열은 **이 저장소의 사실이 정한 것만** 적는다. `카탈로그대로` 인 행은 thegraph
의 카탈로그가 정하며, 여기 숫자를 옮겨 적으면 그것이 카탈로그를 이긴다.

| 노드 | 개수 | 무엇이 이렇게 정했나 |
|---|---|---|
| `classify` | 카탈로그대로 | — |
| `spine` | 카탈로그대로 | 트래커에 parent/child 가 **있으므로** 로스터는 관계다 |
| `map` | **1** | `docs/adr/` + `CLAUDE.md` 의 상류 대기 표 |
| `reference` | **6** | 소스 클래스 6개 |
| `enumerate` | 카탈로그대로 | — |
| `boundary` | **1** | 3층이고 seam 은 저장소 안에 있다 |
| `implement` | **4** | 아래 claim class 4개 |
| `proof` | **4** | 같은 4개 |
| `verify` | **2** | 갭 렌즈 1 + 반박 렌즈 1. 성역 경로 목록이 비어있지 않다 |
| `sweep` | **1** | 표면 8개로 팬아웃 |
| `gate` | **1** | 무조건 6 + 조건부 2 |
| `search` | 카탈로그대로 | — |
| `batch` | 카탈로그대로 | — |
| `stop` · `decide` | 카탈로그대로 | — |
| `promote` | **1** | `docs/adr/NNNN-slug.md` 형식이 있고 승격 목적지로 지명돼 있다 |
| `downstream` | **0** | 아래 부재 사유 |

### `downstream` 이 없는 이유

양쪽 `pubspec.yaml` 이 `publish_to: "none"` 이다(실측, 각 4행). 생성된 프로젝트는 생성
순간 손을 떠난 **포크**이고 역전파 경로가 없다 — #1 의 Out of Scope 가 "생성한 프로젝트
목록 관리, 템플릿 업그레이드 diff 제공" 과 "빌더의 서명·공증·스토어 배포·자동
업데이터" 를 둘 다 명시한다.

**되돌아오는 조건:** 빌더가 서명된 릴리스를 배포하기 시작하거나 `template` 이 pub.dev
패키지가 되면. 그날 이 슬롯을 다시 연다.

**상류 방향은 살아 있고 그건 `boundary` 의 일이다.** SDK 하한 같은 것은 상류에서
`template` 을 거쳐 생성되는 모든 프로젝트로 그대로 내려간다(커밋 `b081ae1`).

---

## `reference` — 소스 클래스 6개

### 라우팅 — `change_type` → 어느 클래스를 여는가

`◎` 필수 · `○` 해당하면 · 빈칸 = 안 연다.

| `change_type` | 1 생성기 | 2 flutter create | 3 Flutter SDK | 4 shadcn | 5 tweakcn | 6 UI 패키지 |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| 테마 / CSS 파싱 / 색 파생 | ◎ | | | ○ | ○ | |
| 생성 파이프라인 (`flutter create`·복사·치환) | | ◎ | | | | |
| shadcn 컴포넌트 신규 / 수정 | | | ◎ | ◎ | ○ | ○ |
| 접근성 · 시맨틱 | | | ◎ | ○ | | ○ |
| 외부 UI 패키지 채택 / 버전 이동 | ○ | | ○ | | | ◎ |
| 상류 생성기 버전 이동 | ◎ | | | | ○ | |
| 빌더 UI / 폼 | | | ○ | | | |

**행이 없는 변경 종류를 만나면 그것부터 `batch` 에 올린다.** 표에 없는 칸을 판단으로
메우면 `sources` 슬롯이 그때그때 달라지고, `verify` 브리프가 그것을 물려받는다.

**`template/lib/` 의 형제 컴포넌트와 `builder/lib/src/ui/` 의 형제 페이지는 소스
클래스가 아니다.** 그건 `verify` 의 자기 저장소 코퍼스다.

### 클래스와 접근 방법

| # | 클래스 | 어떻게 닿나 |
|---|---|---|
| 1 | `flutter_tweakcn_generator` 패키지 소스 | **1차** 핀 박힌 버전의 pub cache — macOS `~/.pub-cache/hosted/pub.dev/flutter_tweakcn_generator-<ver>/lib/src/`, Windows `~/AppData/Local/Pub/Cache/hosted/pub.dev/…`. 특히 `generator/color_scheme_resolver.dart`, `generator/dart_theme_generator.dart`, `parser/css_parser.dart`. **2차** `gh api repos/kihyun1998/flutter_tweakcn_generator/contents/<path> --jq .content \| base64 -d` |
| 2 | `flutter create` 산출물 + `flutter_tools` 소스 | **1차** 임시 폴더에 진짜 만들고 `ls`/`grep`. **2차** `$(dirname $(which flutter))/../packages/flutter_tools/lib/src/commands/create_base.dart` |
| 3 | Flutter 프레임워크 소스 | `$(dirname $(which flutter))/../packages/flutter/lib/src/` 의 `material/`·`widgets/`·`cupertino/` |
| 4 | `shadcn-ui/ui` | `gh api repos/shadcn-ui/ui/contents/apps/v4/registry/new-york-v4/ui/<name>.tsx --jq .content \| base64 -d`. **CSS 변수는 레지스트리가 아니라 `apps/v4/app/globals.css` 에 있다** (레지스트리 경로로 부르면 404) |
| 5 | tweakcn 소스 | `gh api repos/jnsahaj/tweakcn/contents/utils/theme-style-generator.ts --jq .content \| base64 -d`. 공개 저장소이고 이 파일이 파생식의 실제 출처다 |
| 6 | 서드파티 순수 UI 패키지 소스 | pub cache 의 `flutter_checkbox-<ver>`, `flutter_dropdown_button-<ver>`. 후보 `flutter_table_plus`·`flutter_otp_widget` |

**요약본으로 표시된 클래스는 없다 — 여섯 전부 raw 다.** 따라서 등급 상한이 걸리는
소견도 없다.

**pub cache 를 볼 때 `pubspec.lock` 을 먼저 본다.** `source: path` 로 해석된 항목은
pub cache 에 없고 로컬 형제 저장소에 있다. 지금 실제로 컴파일되는 것을 읽는 것이
1차의 정의이므로, lock 이 가리키는 곳을 읽는다.

**요약 fetch 를 쓰지 않는 이유는 방법 쪽에 있다** (`thegraph` 의 `reference` 절).
여기에는 어디를 어떻게 여는지만 적는다.

---

## `enumerate` — hidden state 목록이 사는 곳

별도 파일을 두지 않는다. **상수와 그 doc-comment 가 목록이다.** 늘어나면 **여기에**
추가한다.

### `builder/lib/src/generation/project_generator.dart`

| 상수 | 줄 | 무엇을 가정하나 |
|---|---|---|
| `copyEntries` | 40 | 템플릿에서 복사할 것의 allowlist |
| `themeCssEntry` | 55 | **템플릿 pubspec 의 `flutter_tweakcn_generator: input:` 과 묶여 있고 테스트가 대조한다** |
| `templatePackageName` | 58 | 치환의 원본 이름 |
| `templateDisplayName` | 64 | 표시 이름 |
| `_textExtensions` | 67 | **치환 sweep 전체를 게이트한다** (:314). `{.dart .yaml .arb .md}` 뿐이므로 다른 텍스트 형식을 템플릿에 넣으면 `package:mobile_init_project/` 치환이 **조용히 건너뛴다** |
| `_preservedPrefixes` | 260 | `flutter create` 산출물 중 덮으면 안 되는 것 |
| `exampleDirSegments` | 353 | 예제 디렉토리 |
| `exampleTestDirSegments` | 365 | **`exampleDirSegments` 와 한 쌍이다.** `copyEntries` 가 `test` 를 통째로 복사하므로 `lib/example` 만 지우면 그것을 import 하는 테스트가 남아 결과물이 컴파일되지 않는다. **예제에 의존하는 테스트는 `test/example/` 안에 둔다는 것이 규칙이고**, 밖에 두면 이 상수가 못 잡는다 (#24 에서 실제로 걸렸다) |
| `homeScreenSegments` | 366 | 홈 화면 위치 |
| `exampleOnlyDependencies` | 376 | 예제를 끌 때 함께 빠지는 의존성 |
| `emptyHomeScreenSource` | 387 | 예제를 끌 때 써 넣는 홈 화면 **전문**. 안에 "shadcn 13종" 이 적혀 있고 **이 문자열이 생성물로 나간다** |
| `_postProcessing` | 135 | 파이프라인 단계 순서. 순서의 이유가 상류 버전에 묶여 있다 |
| `arbDirSegments` | 488 | arb 위치 |

**`_withoutDependencies` 가 보는 섹션은 `dependencies:` 와 `dev_dependencies:` 둘뿐**
(:442)이고 `copyEntries` 는 pubspec 을 통째로 복사한다. 즉 **template pubspec 에
`dependency_overrides:` 를 걸어두면 생성되는 모든 프로젝트로 그대로 실려 나가고**, 그
상대 경로는 사용자 머신에 없어 `flutter pub get` 에서 죽는다.

### `builder/lib/src/preview/preview_theme.dart`

`colorTokens` (:136), 그리고 클래스 doc-comment 가 **아직 사본으로 남은 두 곳**
(`colorTokens`, `_colorSchemeFrom`)을 명시한다. 상류에 export 를 요청한 `ftg#22` 는
아직 **열려 있다**.

### `builder/lib/src/generation/application_id.dart`

상류 `flutter_tools` 의 `createAndroidIdentifier` 를 미러링한 사본이다. doc-comment 가
"왜 그냥 이어붙이기여도 되는가" 의 **조건**(값 타입 패턴이 상류 정규화보다 좁다)을
들고 있고, `Organization`·`PackageName` 의 패턴을 넓히면 그 조건이 깨진다. 컴파일은
되고 화면에 적힌 applicationId 만 실제와 달라진다.

**템플릿에 파일·의존성·언어를 추가했다면 이 목록부터 확인한다. 컴파일러가 봐주지
않는다.**

---

## `map` — territory

| 읽는 것 | 지금 무엇이 있나 |
|---|---|
| `docs/adr/` | `0001-external-ui-package-adoption.md` 하나 |
| `CLAUDE.md` 의 "상류 대기" 표 | 2행 — 체크박스 `shadow-xs`(`fcb#8`), select 시맨틱(`fdb#88`, #26 이 들고 있다) |
| 루트 `CONTEXT.md` | **없다** |

**상류 대기 표는 행 수가 아니라 절차로 읽는다.** 1행은 "풀리면 할 일" 을 네 단계로
적어두고 "자동으로 알 수 있나" 에 **아니오** 라고 답한다 — 게이트가 절대 못 잡는
체크리스트이므로 해당 변경에서 그대로 실행한다.

**용어집 부재는 기록된 답이다.** `docs/agents/domain.md` 가 "이 파일들이 없으면 조용히
진행한다. 부재를 지적하지 말고, 먼저 만들라고 제안하지도 않는다" 를 명시하고,
`/domain-modeling` 이 실제로 용어가 정리될 때 lazy 하게 만든다.

`domain.md` 의 "ADR 충돌은 드러낼 것" 이 이 노드의 출력 규칙이다.

---

## `boundary` — 경계 규칙 (3층)

```
flutter_tweakcn_generator (상류, 별도 저장소, 손 못 댐)
        ↑ 결함은 우회 금지 — 상류 이슈로 올린다
template/   = core / mechanism   (앱 런타임: 컴포넌트, 테마 소비, provider, l10n)
        ↑ path: 의존. 사본 금지
builder/    = consumer / policy  (생성 정책: allowlist, 치환, 옵션, 폼, 미리보기)
```

**seam 은 저장소 안에 있다** — `builder/pubspec.yaml:35-36` 의
`mobile_init_project: / path: ../template`. 미리보기는 사본이 아니라 **같은 파일**을
컴파일해 렌더한다. 이 결정의 근거는 #1 이고, 집행부는 `builder/test/template_link_test.dart`
다.

- **mechanism (template)** — 컴포넌트가 `context.tweakcnColors` 로 색을 읽는 방식, 화면
  골격, 로컬라이제이션 구조. template 은 **builder 의 존재를 모른다.** "빌더가 치환하기
  좋게" 코드를 비트는 순간 템플릿은 그 자체로 돌아가는 앱이기를 멈춘다. (실측:
  `template/` 안에 builder 를 가리키는 참조가 0개다.)
- **policy (builder)** — 무엇을 복사할지, 치환할지, 예제를 뺄지, 어떤 언어·플랫폼을
  남길지. 전부 사용자가 폼에서 고르는 것이고 template 안에 흔적이 없어야 한다.
- **consumer 가 정의상 갖는 것** — 폼 검증, 진행 상황/로그 표시, 파일 다이얼로그, 경로
  저장(`shared_preferences`), 프로세스 실행, 데스크톱 레이아웃.

**"두 consumer 가 같은 우회에 도달하면 신호" 는 N/A.** 볼 수 없는 consumer 가 없다 —
template → builder 드리프트는 같은 PR·같은 게이트에서 즉시 터진다. 이미 생성된
프로젝트는 consumer 가 아니라 포크다.

**`stop` 엣지의 가드:** 상류(생성기)의 결함이나 private API. builder 안에 "임시 매핑"
을 넣고 넘어가지 않는다. 당장 받을 수 없어 사본을 둬야 한다면 **낡았을 때의 증상을
doc-comment 에 적는다** (`preview_theme.dart` 가 그렇게 하고 있다).

---

## Tie-breaker — 층마다 다르다

**하나가 아니다.** `verify` 브리프는 *그 변경이 앉은 층의 행*을 싣는다. 층을 안 보고
하나를 실으면 렌즈가 권위가 없는 층에 규칙을 적용하고, 그것을 **긴급한 것처럼**
보고한다.

| 층 | 무엇이 이기나 | 근거 |
|---|---|---|
| 1 **생성 파이프라인** | **상류 `flutter_tools`** — 우리가 정하는 규칙이 아니라 미러링이다 | `application_id.dart` 의 doc-comment. #36 이 "규칙을 미러링할 거면 산출물과 소스를 둘 다 읽는다" 를 세웠다 |
| 2 **미리보기** | **생성기가 실제로 뱉는 것** | 아래 |
| 3 **미리보기 ↔ 생성 결과 일치** | **생성기가 실제로 뱉는 것** | 같음 |
| 4 **템플릿 컴포넌트** | **어느 단계를 쓰는지는 shadcn 원본**, **단계의 값을 어떻게 파생하는지는 tweakcn** | `CLAUDE.md`: "shadcn 원본이 정한 것을 따라간다 — 우리가 고르지 않는다". 파생식은 갈림 목록 1행 |

### 2·3층 — 생성기가 이긴다

미리보기의 진실 기준은 "예쁨" 도 "Material 규범" 도 아니고 **"생성 결과와 같은가"**
하나다. 규범은 교차 확인용일 뿐이며, 규범과 어긋난다는 사실은 미리보기를 고칠 이유가
**아니라 상류 이슈를 올릴 근거**다 (올리는 것은 `batch` 를 거친다).

실측 예: `color_scheme_resolver.dart:51-52` 가 `'input': 'outlineVariant'`,
`'card': 'surfaceContainerLowest'` 로 매핑한다. Material 의미론으로는 어색하지만
미리보기는 생성기를 따라간다.

이 규칙은 3층 경계선과 한 몸이다 — 규범 쪽이 옳아 보여도 하류에서 "고쳐두는" 것이
금지이므로, 판단은 항상 *상류에 보고하고 하류는 상류를 미러링* 으로 떨어진다.

**교차 확인하는 prior art:** tweakcn 의 CSS 토큰 체계, shadcn/ui 의 컴포넌트 의미론,
Flutter `ColorScheme` 의 Material 의미론.

---

## 일부러 갈리는 자리 (deliberate divergences)

tie-breaker 는 "누가 이기는가" 를 말하고, 이 목록은 **"어떤 논쟁이 이미 끝났나"** 를
말한다. `verify` 브리프에 tie-breaker 행과 **함께** 실린다. 안 실으면 렌즈는 이것들을
매번 `DELIBERATE` + 인용이 아니라 **`CONFIRMED` + 제안**으로 다시 올린다. 가정이
아니다 — 1행에서 실제로 그렇게 상류 이슈를 올렸다가 기각됐다.

| 자리 | 무엇이 갈리나 | 기록 |
|---|---|---|
| **radius 파생식** | 우리 생성기는 뺄셈(`base -4 / -2 / +4`), shadcn/ui `apps/v4/app/globals.css` 는 곱셈(`×0.6 / 0.8 / 1.4`). 두 식은 `--radius: 10px` 에서만 일치한다 | **#23.** 그 뺄셈은 **tweakcn 자신의 것**이고(소스 클래스 5, `utils/theme-style-generator.ts`) 사용자가 복사해오는 CSS 가 그렇게 계산하므로 이 층을 지배한다. 결함으로 읽고 상류에 올렸다가 **기각됐다** — `ftg#31` 종결 코멘트 *"The premise is falsified… tweakcn emits the subtractive derivation itself"*, 0.5.1 이 식을 그대로 두고 근거를 doc-comment 로 못박았다 (`dart_theme_generator.dart:382-390`, `:496`) |
| **라디오 그룹의 타일** | shadcn `radio-group.tsx` 에 타일이 없다. 우리는 옵션마다 테두리 상자를 두른다 | **#25** (`shadcn_radio_group.dart:169-171` 이 근거를 in-code 로 들고 있다). 그래서 그림자는 **표시기**가 받고 타일은 안 받는다. "타일에 `shadow-xs` 가 없다" 는 결함이 아니다 |
| **날짜 선택 오버레이** | shadcn 은 팝오버(`popover.tsx:33`, `shadow-md`), 우리는 `Dialog` 다 | **#25** (`shadcn_date_picker.dart:226-229`). 그래서 `shadow-lg` 를 쓴다(`dialog.tsx:64`). 단계가 틀린 것이 아니라 **자리가 다른 것** |

**Material 의미론과 갈리는 것은 여기 적지 않는다.** 위 2·3층 tie-breaker 가 이미
다루고, 그건 개별 예외가 아니라 규칙 자체다. 여기 옮겨 적으면 규칙이 예외 목록으로
바랜다.

**짧아서 값이 있다** — 셋뿐이면 렌즈에 통째로 실어줄 수 있다. 새 항목이 생기면 그
이슈를 닫는 변경에서 더한다. **갈림이 해소되면 지운다** — select 팝오버 그림자가
그랬다(#31 이 일부러 꺼둔 것을 #25 가 되살렸다).

---

## `implement` / `proof` — 층 4개

각 행이 claim class 다. **싼 도구가 다음 행의 축에 구조적으로 눈이 멀기 때문에**
따로 있다.

| # | 층 | 코드가 사는 곳 | 진짜 왕복 | 이 증명이 못 보는 것 |
|---|---|---|---|---|
| 1 | **생성 파이프라인** | `builder/lib/src/generation/` | 아래 절차대로 **진짜 생성 1회** | 색. analyze/test 는 테마를 아예 안 본다 |
| 2 | **미리보기** | `builder/lib/src/preview/` | CSS 문자열을 넣고 **렌더된 픽셀의 색** 확인 (`builder/test/support/rendered_color.dart`). 파싱 함수를 단위 테스트하지 않는다 | 생성기가 같은 매핑을 하는지. 자기끼리만 일관된 매핑도 통과한다 |
| 3 | **미리보기 ↔ 생성 결과 일치** | 코드 없음 — 1·2층에 걸린 **성질**이다. 자동화된 절반은 `preview_colorscheme_parity_test.dart`·`preview_shadow_parity_test.dart`·`generator_version_parity_test.dart` | 같은 CSS 로 진짜 생성해 앱을 띄우고 주요 색을 눈으로 대조. **자동화 불가** — #9 의 수용 기준 | **아무것도.** 이 층이 마지막 그물이다 — 단, 사람이 실제로 돌려야만 존재한다 |
| 4 | **템플릿 앱** | `template/lib/` | `template/` 에서 `flutter test`, 화면이 걸린 변경이면 `flutter run` | 빌더의 복사 allowlist 가 그것을 실어 나르는지 |

**한 변경이 여러 층에 걸리면 걸린 층 전부를 인스턴스화한다.** 새 컴포넌트 하나가 4층
(컴포넌트) · 2층(미리보기 캔버스가 예제 페이지를 렌더한다) · 1층(arb 키가 생성물로
간다) 에 동시에 앉는 것이 정상이다. 층은 파일이 아니라 **주장**이다.

**3층은 `gate` 스크립트가 못 덮는다.** decider 는 **human** 이다 — `batch` 에 "이 변경이
3층에 앉았나, 왕복을 돌았나" 로 올린다.

### 1층의 진짜 생성 절차

fake runner 테스트는 여기서 smoke 이지 증명이 아니다. **협상 대상이 아니다.**

**선행 조건 — 먼저 확인한다.** `git status --short template/` 가 깨끗해야 한다.
커밋 안 된 템플릿 변경(특히 `dependency_overrides:`)은 생성물로 그대로 실려 나가서
**변경과 무관한 이유로** `flutter pub get` 을 죽인다. 더러우면 그것부터 처리한다.

1. 임시 폴더를 만든다. `_validate` 가 **기존 디렉토리에 throw** 하므로 대상 경로는
   비어 있어야 한다. 재실행 전에 반드시 지운다.
2. 빌더의 폼 값으로 생성한다 — 이름·org 는 값 타입 패턴을 통과하는 것으로, 플랫폼은
   **변경이 닿는 것**을 고른다.
3. **네트워크가 필요하다** — `flutter pub get` 과 테마 CLI 의 폰트 페치.
4. 결과물 안에서 `flutter analyze` 와 `flutter test`.
5. **예제를 끄는 변경이면 끈 상태로도 한 번.** 옵션이 늘면 매트릭스도 늘어난다.
6. **정리는 `verify` 가 결과물을 읽은 뒤에** 한다. 먼저 지우면 렌즈가 볼 것이 없다.

**증명이 실패했는데 변경 때문이 아닐 수 있다.** 위 선행 조건과 네트워크가 먼저
의심 대상이다. 원인을 못 가르면 `batch` 로 올린다 — 초록이 아닌 것을 초록으로
읽지 않는다.

### 자기 자신을 오독할 수 있는 측정

- **fake runner 는 `flutter create` 도 `build_runner` 도 돌리지 않는다.** 복사·치환이
  전부 초록인데 결과물이 컴파일 안 되는 상태가 얼마든지 가능하다.
- **템플릿 CSS 는 여러 토큰 쌍이 같은 값이다.** light 에서 `--background` = `--card` =
  `--popover` = `oklch(1 0 0)` 이고 `--border` = `--input` = `oklch(0.9220 0 0)` 이다.
  **dark 에서는 갈린다** (`card 0.2050` vs `background 0.1450`, `border 0.2750` vs
  `input 0.3250`). 매핑을 건드렸으면 쌍이 서로 다른 값인 CSS 로 확인한다.
- **`template/tweakcn.css` 의 `--radius` 가 `0.625rem` = 정확히 10px 이다** (37행 light,
  92행 dark). 갈림 목록 1행이 "두 식은 `--radius: 10px` 에서만 일치한다" 고 적은 바로
  그 값이다. **기본 CSS 로 radius 파생을 재면 뺄셈식과 곱셈식을 구별할 수 없다.**
  이 파일은 107줄이고 `--radius-sm/md/lg/xl` 을 **정의하지 않는다.**
- **밝은 테마만 재는 것.** 실측(#31): `ThemeData.cardColor` 는 light 에서
  `card`·`background`·`popover` 와 전부 같지만 dark 에서는 `background` 뿐이고,
  `ThemeData.primaryColor` 는 light 에서 `colorScheme.primary` 인데 **dark 에서는
  `colorScheme.surface`** 다. 변이 테스트에서 `popover`→`card` 변이를 **light 는
  통과시키고 dark 만 잡았다.**
- **위젯 테스트가 초록인 것은 "그 위젯이 소비한 것" 까지만 증명한다.** 색을 assert
  하지 않는 렌더 테스트는 테마 회귀를 못 잡는다.
- **`matchesSemantics` 는 그 노드 하나만 본다.** 자식이 더 붙어도 통과하므로
  `node.childrenCount` 를 함께 본다.
- **`Theme.of(context).platform` 을 바꿔도 `RawRadio` 의 분기는 안 돈다** — 전역
  `defaultTargetPlatform` 을 본다. `testWidgets(..., variant: TargetPlatformVariant.only(...))`
  를 쓴다. `debugDefaultTargetPlatformOverride` 를 손으로 세우고 `addTearDown` 으로
  되돌리면 프레임워크 불변식 검사가 **먼저** 돌아 터진다.

---

## `verify` — 성역 경로와 두 렌즈

### 인바운드 가드 — `code`

**diff base 는 `git merge-base origin/main HEAD`** 다. 인자 없는 `git diff` 는 워킹
트리와 인덱스를 비교하므로, 브랜치에 커밋한 뒤에는 항상 빈 결과를 낸다.

가드는 **두 종류**다. 하나라도 걸리면 판단과 무관하게 돈다.

**변경 목록은 `git diff --name-only <base>` **와** `git ls-files --others
--exclude-standard` 를 합친 것이다.** `git diff` 는 아직 add 안 한 새 파일을 아예
안 본다 — 그런데 **새 shadcn 컴포넌트를 만드는 것이 이 저장소에서 제일 흔한
변경이고, 그것이 정확히 성역 3번에 새 파일 하나를 더하는 모양이다.** 합치지 않으면
가드가 가장 흔한 경우에 안 걸린다. 실측으로 걸렸다 — 빌드 직후
`shadcn_progress.dart` 를 만들어놓고 돌렸더니 히트 없음이 나왔다.

**(가) 경로 — 그 목록에 아래가 있으면**

1. **`builder/lib/src/preview/preview_theme.dart`** — 파생·매핑. 상류 생성기가 하는
   것과 한 글자라도 갈리면 미리보기가 거짓말을 시작하고 이 도구의 존재 이유가
   사라진다. 증상이 컴파일 에러가 아니라 "색이 좀 다름" 이라 조용히 지나간다.
2. **`builder/lib/src/generation/project_generator.dart`** — 복사 allowlist 와 파괴적
   파일 조작(`copyEntries`, `_copyTemplate` 의 `deleteSync(recursive: true)` :282,
   `_validate` 의 기존 디렉토리 가드 :219). **사용자 파일시스템을 지우는 유일한 곳이고
   되돌릴 수 없다.** allowlist 가 새면 `flutter create` 가 방금 만든 플랫폼 스캐폴드를
   낡은 것으로 덮어쓴다. blocklist 로 바꾸자는 제안은 여기서 막는다 — allowlist 누락은
   컴파일 실패로 즉시 드러나지만 blocklist 누락은 조용히 통과한다.
3. **`template/lib/ui/components/`** — 컴포넌트의 시맨틱·접근성·토큰 사용. 문서화된
   near-miss 가 전부 여기서 나왔고(#26 라디오의 플랫폼 분기, #26 스위치의 `toggled`,
   `matchesSemantics` 의 자식 노드, `RawRadio` 의 전역 플랫폼), `CLAUDE.md` 가 그
   위험들을 하나같이 같은 문장으로 닫는다 — **"테스트는 초록이다."** 1·2번이 *색이
   조용한* 표면이라면 여기는 *시맨틱이 조용한* 표면이다.

**(나) 의존성 — 경로로는 안 잡히는 것**

`template/pubspec.lock` 또는 `builder/pubspec.lock` 에서 **`flutter_tweakcn_generator`
의 버전이 움직였으면** 성역 히트다. `preview_theme.dart` 의 사본은 그 버전에 *의미로*
묶여 있지 *텍스트로* 묶여 있지 않다 — 버전이 오르면 사본이 틀려지는데 **파일의
바이트는 안 바뀌므로 (가) 가 못 잡는다.** `flutter_checkbox`·`flutter_dropdown_button`
의 버전 이동도 같은 이유로 히트다 (ADR-0001 §3 의 도달성 재계수가 걸린다).

경로도 의존성도 안 걸리면 가드는 **열거 위험**(`AI`)이다.

### 두 렌즈

성역 경로 목록이 비어있지 않으므로 **반박 렌즈를 산다.** 예산은 위 성역 히트에서만
쓴다.

### 두 코퍼스

- **자기 저장소 형제** — `template/lib/ui/components/` 의 컴포넌트들(서로가 서로의
  prior art), `builder/lib/src/ui/` 의 형제 페이지, 위 hidden state 목록.
- **레퍼런스** — 라우팅 표가 이 `change_type` 에 대해 연 클래스.

---

## `sweep` — 행동을 기술하는 표면 8개

| # | 표면 | 무엇을 하나 |
|---|---|---|
| 1 | `CLAUDE.md` | 작업 규칙이 바뀌면 1순위. 전문이 아니라 **한 줄 포인터**만 둔다. 상류 대기 표도 여기 |
| 2 | `docs/agents/*.md` | 이 문서가 값의 기준이고 `theflow.md` 는 포인터다. 포인터가 가리키는 절 이름을 바꾸면 양쪽을 고친다 |
| 3 | 코드 doc-comment | `preview_theme.dart`, `project_generator.dart`, `application_id.dart`. **이것들이 hidden state 목록을 겸하므로** 낡으면 틀린 주석이 아니라 **틀린 목록**이 된다. `emptyHomeScreenSource` 안의 문장은 **생성물로 나가는 문서**다 |
| 4 | 이슈 본문 | #1 이 PRD 다 (**닫혀 있다** — 아래 `search` 참고). 자식이 닫힐 때 anchor 에 접어 넣는 것은 `spine` 의 flush 다 |
| 5 | `template/tweakcn.css` | 고치면 `dart run flutter_tweakcn_generator` 로 `tweakcn_theme.g.dart` 까지 만들어 **커밋한다** |
| 6 | `template/lib/core/localization/l10n/intl_{ko,en}.arb` | 고치면 `dart run intl_utils:generate` 로 생성물까지 만들어 **커밋한다** |
| 7 | 툴체인 하한 | 양쪽 `pubspec.yaml` 의 `environment:` (지금 `sdk: ^3.9.0`, `flutter: ">=3.35.0"`). 생성되는 모든 프로젝트로 따라가므로 **실제로 확인한 값만** 적는다 |
| 8 | `docs/adr/` | **write 표면이다.** 변경이 어떤 record 의 전제를 거짓으로 만들면 그 record 를 같은 변경에서 수정한다 (상태 노트, superseded-by) |

**changelog / 릴리스 노트: 없다** — publish 하지 않으므로 스냅샷 문제도 없다.
**공개 API 문서 표면: 없다** — pub.dev 에 올라가는 패키지가 아니다.
**`README.md` 는 `flutter create` 스텁이다** — 표면으로 세지 않되, 손대는 김에 고치는
것은 자유다.

---

## `gate` — 명령 목록

**top-level 명령이 존재하지 않는다.** 워크스페이스가 없으니 항상 양쪽을 따로 돌린다.
각 명령은 **bare** 로 부른다.

무조건:

```
cd template && flutter analyze
cd template && flutter test
cd builder  && flutter analyze
cd builder  && flutter test
cd template && dart format --output=none --set-exit-if-changed lib test
cd builder  && dart format --output=none --set-exit-if-changed lib test
```

조건부 — **경로로 판정한다** (`code`, diff base 는 위와 같다):

| diff 가 닿으면 | 무엇 |
|---|---|
| `builder/lib/src/generation/**` · `template/pubspec.yaml` · `template/pubspec.lock` | 1층 진짜 생성 절차 → 결과물 안에서 `flutter analyze && flutter test` |
| `template/tweakcn.css` · `template/lib/**/*.arb` · `@riverpod` 를 담은 `template/lib/**/*.dart` · `template/pubspec.lock` | 세 도구 재생성 후 `git diff --exit-code` |

**재생성 도구가 셋이고 서로 다르다. 한 덩어리로 기억하면 안 된다.**

- provider → `dart run build_runner build --delete-conflicting-outputs`
- arb → `dart run intl_utils:generate`
- `tweakcn.css` → **`dart run flutter_tweakcn_generator`**

**테마는 `build_runner` 가 만들지 않는다.** 상류의 `build.yaml` 은
`.tweakcn.css` → `.tweakcn.dart` 만 걸고, pubspec 의 `flutter_tweakcn_generator:`
블록(`input`/`output`)은 `bin/` 의 CLI 만 읽는다. 우리 파일 이름은 `tweakcn.css` 라
builder 패턴에 애초에 걸리지 않는다. 실측(#9): `--primary` 를 바꾸고 `build_runner` 를
돌리면 `tweakcn_theme.g.dart` 가 **한 글자도** 안 바뀌고, CLI 를 돌리면 바뀐다.

### 사각지대

1. **`builder` 테스트는 `template/test/` 를 돌리지 않는다.** `path:` 의존이라 template
   코드를 **컴파일**할 뿐이다. template 만 고쳤어도 양쪽 다 돌린다 — 컴포넌트 변경이
   빌더 미리보기를 깨는 것이 정확히 이 저장소가 막으려는 사고다.
2. **로컬 analyze·test 가 낡은 생성물을 초록으로 통과시킨다.** 커밋 `5199915`(#16)가
   `theme_provider.dart` 를 고치고 재생성을 안 해서 riverpod 소스 해시가 낡은 채로
   머지됐고(`.g.dart` 는 `fc03ba5`(#18) 에서야 갱신됐다), CI 의 `codegen` 잡이 그
   사건 때문에 생겼다. **그때는 `gates.yml` 이 아직 없었다** — 워크플로 첫 커밋은
   `31347f5`(#17) 다. 그리고 그 잡은 **#9 까지 테마 CLI 를 안 돌리고 있었다**
   (`0b52c75` 가 추가했다).
3. **`.gitattributes` 의 `eol=lf`.** 생성 도구는 항상 LF 로 쓰는데 `text=auto` 아래
   Windows 체크아웃은 CRLF 라, 못박지 않으면 도구를 한 번 돌리는 것만으로 커밋된
   생성물이 통째로 수정으로 뜬다 — 내용은 한 글자도 안 바뀐 채로. 생성물을 새로
   추가하면 그 규칙에도 넣는다. `git ls-files --eol` 로 `w/crlf` 를 찾는다.
4. **`builder/test/macos_sandbox_test.dart`** — `flutter create` 로 `macos/` 를 다시
   만들면 app-sandbox 가 기본값으로 되살아나고, 그러면 `Directory.current` 가
   컨테이너로 바뀌어 `../template` 해석과 `Process.run('flutter', …)` 이 둘 다 죽는다.
5. **`builder/test/template_link_test.dart`** — template 컴포넌트가 빌더 위젯 트리에서
   렌더된다는 전제. 깨지면 미리보기의 약속이 무너진 것이다.
6. **`builder/test/preview/generator_version_parity_test.dart`** — 상류 생성기 버전
   이동을 지키는 **유일한** 테스트다. 그 doc-comment 가 `preview_colorscheme_parity_test`
   는 버전 갈림을 "구조적으로 못 본다" 고 적어둔다.
7. **지금 개발 머신이 아닌 OS.** 프로세스 실행과 경로 조합이 첫 번째로 터지는 자리다.
   `p.join` 을 쓰고 `runInShell: true` 로 부른다(Windows 는 `flutter.bat`). 로컬에서는
   한 OS 만 볼 수 있으므로 **CI 가 덮는다.**
8. **포맷은 ubuntu 에서만 돈다 — 일부러 그렇다.** `.gitattributes` 가 `* text=auto` 라
   Windows 체크아웃은 CRLF 이고, 줄바꿈 때문에 코드가 멀쩡한데 빨개지는 것을 피한다.
   포맷은 OS 를 타지 않는다.
9. **포맷터 핀.** 로컬은 `PATH` 의 `dart format`, CI 는 `FLUTTER_VERSION` 고정이다.
   두 SDK 의 포맷터가 다르면 로컬 초록이 CI 빨강이 된다. 로컬 SDK 를 워크플로 핀에
   맞춰두는 것이 최선이고, 안 맞으면 그 사실을 알고 있는다.

### 브랜치 / PR / CI

- 브랜치: `<type>/<slug>` — 실물 `feat/tweakcn-0.4.0`(PR #11), `test/windows-process-runner`(PR #10).
- **squash PR** 로 병합하고 제목에 이슈 번호를 남긴다. PR 이 이슈를 닫는다.
  (`feat: 지원 언어 선택 (#8)` 은 제목 형식의 예시이지 PR 의 예시가 아니다 — 그건
  커밋 `fbb6aaf` 로 직접 푸시된 것이고 PR 이 아니었다. PR 번호는 #10 부터다.)
- **CI 는 `.github/workflows/gates.yml` 하나**(워크플로 이름 `gates`). `format`(ubuntu,
  양쪽 모듈), `codegen`(ubuntu, 테마 CLI + intl_utils + build_runner 후 `git diff
  --exit-code`), `gates`(ubuntu·macOS·Windows 3종, 양쪽 모듈 analyze+test,
  `fail-fast: false`, template 이 먼저). Flutter 버전은 그 파일의 `FLUTTER_VERSION`
  으로 고정한다 — **값을 여기 옮겨 적지 않는다.**
- 워크플로가 위 매트릭스와 갈리면 **이 문서가 기준이고 워크플로를 맞춘다.**
  `gates.yml` 의 헤더 주석이 그렇게 적혀 있다.
- **CI 가 로컬 게이트를 대체하지 않는다.** 구현 중에 CI 를 쳐다보고 있지 말 것. CI 의
  값은 **다른 OS** 와 머지 게이트다.

---

## `search` — 트래커의 실제 모양

**이 트래커는 거의 다 닫혀 있다.** 실측 2026-08-14: 이슈 22개 중 **21개 CLOSED**,
열린 것은 **#26 하나**이고 그것의 parent 는 `null` 이다.

그래서 `search` 의 네 갈래에 **닫힌 이슈 규칙**이 붙는다:

- **닫힌 이슈가 이 결함을 소유한다** — 같은 결함이 재발한 것이면 **다시 연다**. 다른
  결함이면 새로 열고 `related to #N` 으로 건다. 어느 쪽이든 **그 이슈가 무엇을
  기각했는지 먼저 읽는다** — 닫혔다고 기록이 사라지지 않는다.
- **#1 은 닫혀 있고 하위 12개가 100% 다.** 새 작업을 그 밑에 달지 않는다. #1 은 PRD
  로서 `sweep` 표면 4번으로만 남는다.
- **`spine` 이 앵커를 못 찾는 것이 정상이다.** 지금 열린 유일한 이슈에 parent 가
  없으므로 `code` 결과가 "앵커 없음" 이고, 그때는 "이웃의 추론을 다시 도출하고 있는가"
  가 신호가 된다 — 그것이 후보이지 여는 이슈가 아니다.

**artifact 로 검색한다** — 이 저장소에서 잘 듣는 키는 상수 이름(`copyEntries`,
`colorTokens`), 파일 경로, pubspec 키, 컴포넌트 파일명(`shadcn_*`) 이다.

### 이미 record 를 가진 영역

**accepted 1, proposed 0.**

| 영역 | record |
|---|---|
| 외부 UI 패키지를 `template/lib/ui/components/` 에 들이는 것 | `docs/adr/0001-external-ui-package-adoption.md` (accepted, 2026-08-05) — #27·#31 에서 승격. `flutter_table_plus`·`flutter_otp_widget` 은 이 record 아래 **conformance item** 으로 붙는다 (앵커를 새로 열지 않는다). §3 의 도달성은 **채택 시점에 한 번 하는 판정이 아니다** — 슬롯이 움직이면 다시 센다 (2026-08-08 갱신) |

그 외 영역은 record 가 없으므로 첫 클러스터를 만나면 앵커 이슈로 연다.

---

## `batch` — 어떻게 트래커에 닿는가

트래커는 **GitHub 이슈, `gh` CLI** 다 (`docs/agents/issue-tracker.md`). 라벨은
`docs/agents/triage-labels.md` 의 다섯 가지.

**parent/child 와 native dependency 를 둘 다 실제로 쓰고 있다** — GraphQL 로 #9 의
`parent` 가 #1 이고, `/issues/9/dependencies/blocked_by` 가 #3 을 돌려준다(본문의 텍스트가
아니라 진짜 관계다). 따라서 follow-up 트리와 앵커 로스터 모두 트래커가 지탱한다.
**본문에 손으로 유지하는 로스터를 만들지 않는다.**

관계를 거는 방법 — 이 두 줄이 조용히 틀리는 자리다:

- **하위 이슈:** GitHub 하위 이슈 엔드포인트에 `gh api` 호출.
- **차단:** `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by
  -F issue_id=<blocker-db-id>`. **`<blocker-db-id>` 는 숫자 database id 다** —
  `gh api repos/<owner>/<repo>/issues/<n> --jq .id` 이며 `#number` 도 `node_id` 도
  아니다.

**필터링과 정확성 규칙은 방법 쪽에 있다** (`thegraph` 의 `batch` 절과 후보 봉투).
여기에는 이 트래커의 사용법만 적는다.

---

## `promote` — 결정 기록

**목적지:** `docs/adr/NNNN-<slug>.md`.

- ADR 은 **도출을 담는다.** ADR-0001 이 그 기준을 스스로 적어뒀다 — *"그건 답이고, 이
  문서는 **답을 만드는 절차**다."*
- 작업 방식까지 바꾸는 규칙이면 `CLAUDE.md` 에는 **한 줄 포인터만** 남긴다.
- 용어 자체가 바랬으면 루트 `CONTEXT.md` 도 같이 만든다 (`domain.md` 가 자리를
  그려뒀다).

---

## 추출 계획

**스크립트 언어: Dart.** `dart <path>` 로 pubspec 없이 standalone 실행된다(실측:
`dart:io` 만 쓰는 프로브가 빈 폴더에서 `exit=0`, `.dart_tool` 도 안 남긴다).
`CLAUDE.md` 의 "macOS 와 Windows 양쪽에서 돈다" 불변식과 같은 관례다.

여덟 개 전부 존재한다. **전부 빌드 스탬프를 달고 있다.**

| 파일 | 노드 | 들고 있는 데이터 |
|---|---|---|
| `scripts/thegraph/gates.dart` | `gate` | 무조건 6개 + 조건부 2개의 경로 목록. 전부 bare, 파이프 없음 |
| `scripts/thegraph/triggers.dart` | `verify` 가드 | 성역 경로 3개 + 의존성 절(양쪽 lock 의 해석된 버전을 base 와 비교). 종료 코드 `0` 히트 없음 · `2` 히트 · `1` 판정 불가 |
| `scripts/thegraph/generate.dart` | `proof` 1층 | 선행 조건 검사, 결과물 형태 검사, 예제 on/off 매트릭스, **정리는 별도 플래그** |
| `scripts/thegraph/cluster.dart` | `search` | artifact 별 질의 + 닫힌 이슈 규칙 + record 영역. **아무것도 만들지 않는다** |
| `scripts/thegraph/file.dart` | `batch` | 하위 이슈 등록 + `blocked_by`(database id 조회 포함). **기본이 dry-run 이고 `--apply` 를 명시해야 친다** |
| `.claude/agents/thegraph-reference.md` | `reference` | 라우팅 표 + 클래스 6개의 접근 명령 |
| `.claude/agents/thegraph-lens.md` | `verify` | 두 코퍼스 경로 + 층별 tie-breaker 4행 + 갈림 3행. **stance 를 인자로 받는다** — 반박 렌즈용 파일을 따로 두지 않는다 (한 문장만 다른 두 파일은 갈림의 씨앗이다) |
| `.claude/agents/thegraph-sweep.md` | `sweep` | 표면 8개와 각각 할 일 |

어느 파일도 등급표·재진술 테스트·후보 봉투·코퍼스 규칙을 들지 않는다 — 그건 방법이고
`thegraph` 에 산다.

### 스크립트가 아닌 것

`generate.dart` 는 **생성을 직접 돌리지 않는다.** `ProjectGenerator` 가 `builder/lib`
안에 있어서 standalone 스크립트가 import 할 수 없다. 생성 자체는 빌더 GUI 나
`builder/test/` 를 거치고, 스크립트는 **그 주위를** 한다 — 선행 조건, 결과물 검사,
analyze/test, 매트릭스, 정리 순서. 못 하는 것을 하는 척하면 fake runner 와 같은 실패를
한 겹 더 만든다.

`gates.dart` 도 1층 생성을 돌리지 않는다. 다만 **필요한데 안 돌았으면 실패로 센다** —
조용히 넘어가는 것이 이 빌드가 막으려는 모양이다.

---

## War-story index

규칙이 추상론으로 읽히지 않게 하는, 실제로 뭔가를 잡은 전례들. **전문이 여기 있다.**

### `boundary`

- **#1 (spec) — "미리보기용 사본을 만들지 않는다".** 사본을 만드는 순간 드리프트가
  구조적으로 가능해지고, 그게 이 도구의 유일한 가치를 죽인다. → `path:` 의존과
  `template_link_test.dart` 가 이 결정의 집행부다.
- **`ftg#11` → 0.4.0.** 하류에 임시 매핑을 두는 대신 상류에 런타임 팩토리를 요청해서
  받아왔다(`TweakcnColors.fromMap` 등). 사본이 셋 사라졌다 (커밋 `df0df47`).
- **`ftg#23·#24·#27·#28` → 0.5.0 — 위 항목의 나머지 반쪽.** #11 이 "우회하지 말고
  올린다" 였다면 이쪽은 **상류가 고쳐준 뒤에 하류의 우회를 걷어내는** 쪽이다. 0.4.0
  은 폰트 하나를 못 받은 것과 아무것도 생성 못한 것이 똑같이 `1` 이라, 빌더가 테마
  단계를 파이프라인 **맨 뒤로 미루는** 우회를 이고 있었다. 0.5.0 이 `2` 를 갈라준
  뒤에도 빌더는 non-zero 를 전부 하드 실패로 읽어서, **`flutter run` 이 그냥 되는
  결과물을 "실패" 로 띄우고 있었다.** → 상류를 올리는 변경은 **버전만 올리고 끝나지
  않는다.** 그 버전이 낡게 만든 하류의 근거·우회·주석까지 같은 변경에서 쓸어낸다.

### `reference`

- **커밋 `b081ae1`** — SDK 하한이 `flutter create` 가 찍어둔 값이라 실제 필요값보다
  **9개 마이너** 높았다. 반대 방향으로 틀렸다면 `pub get` 은 통과시키면서 컴파일만
  실패시켰을 값이다. → external fact 는 검증 대상이고, 하한은 상류에서 하류로 그대로
  내려간다.
- **#31 — 티켓 본문의 실측표가 두 줄 틀렸다.** light 에서만 쟀기 때문이다. 그 이슈의
  코멘트 제목이 그대로 *"본문의 실측표가 두 줄 틀렸다 — light 에서만 쟀기 때문이다"*
  다. → **"external fact 는 검증 대상" 이 자기 저장소의 이슈 본문에도 걸린다.**
- **#26 라디오 — 손으로 만들지 말고 프레임워크 기본형 위에 앉는다.** 손으로
  `Semantics(checked:, selected:, …)` 를 붙이는 것이 자명해 보였는데 상류
  `raw_radio.dart:199-224` 를 읽으니 **`selected` 와 `hint` 가 플랫폼마다 다르다** —
  iOS/macOS 에서만 싣고, 상류가 "중복 안내를 피한다" 는 주석까지 달아뒀다. 그 `hint` 는
  `flutter_localizations` 가 언어별로 들고 있다(ko = "선택되지 않음"). 손으로 붙였다면
  **두 분기를 다 놓치고 문구를 우리 arb 에 새로 만들었을 것**이고, 테스트는
  초록이었을 것이다.
- **#26 스위치 — 형제에서 플래그 이름을 유추하면 틀린다.** 라디오 바로 다음 작업이라
  `checked` 를 그대로 쓸 뻔했는데 Material 과 Cupertino 둘 다 **`toggled`** 를 쓴다
  (`switch.dart:1074-1075`). 변이로 확인했다 — 바꾸면 5개가 빨개진다. 반대로 라디오에
  있던 플랫폼 분기는 스위치에 **없다**(Cupertino 쪽 분기는 햅틱용). 이것도 읽어서
  확인한 것이지 "형제가 그랬으니" 로 옮겼으면 쓸데없는 `variant:` 장치를 달았을 것이다.

### `proof`

- **#31 의 변이 테스트** — `popover`→`card` 변이를 **light 는 통과시키고 dark 만
  잡았다.** 위 "밝은 테마만 재는 것" 함정의 실물.
- **`matchesSemantics` 는 자식 노드를 안 본다.** 라벨 붙은 스위치가 안쪽에 컨트롤을
  하나 더 들고 있으면 노드가 갈리는데 바깥 노드에 `matchesSemantics` 를 걸어도
  **통과한다.** "안쪽을 되돌리는" 변이가 1개밖에 안 잡혀서 드러났고, `childrenCount`
  를 함께 보게 고치니 2개가 잡힌다. → 변이 검사가 **테스트 이름이 주장하는 것과 실제로
  재는 것의 차이**를 잡은 사례.
- **`RawRadio` 는 `Theme.of(context).platform` 이 아니라 전역 `defaultTargetPlatform`
  을 본다.** 테마만 바꾸면 iOS 분기가 아예 안 돌면서 통과한다.

### `gate`

- **커밋 `aec8583`** — 프로세스 러너 검증이 `sh -c` 를 써서 **Windows 에서 통째로
  skip** 됐고, 하필 Windows 가 `flutter.bat` 때문에 가장 확인이 필요한 플랫폼이었다.
  (당시 CI 가 없었으므로 이건 로컬 커버리지 이야기다.) 지금 그 테스트는 진짜 프로세스를
  띄우므로 러너 OS 를 실제로 탄다.
- **커밋 `5199915`(#16)** — `theme_provider.dart` 를 고치고 재생성을 잊어 riverpod
  소스 해시가 낡은 채로 머지됐다. `codegen` 잡이 그 사건 때문에 생겼고(`fc03ba5`, #18),
  그 잡은 **#9 까지 테마 CLI 를 안 돌리고 있었다**(`0b52c75` 가 추가). 같은 사고를
  막으려고 만든 잡에 세 도구 중 하나가 빠져 있었던 것이다.

### `sweep`

- **#32 의 릴리스 왕복이 찾은 explorer 종료 코드.** `revealInFileManager` 는 OS 별로
  다른 실행 파일을 부르는데(`open`/`explorer`/`xdg-open`) 테스트는 **어느 것을
  부르는지만** 보고 종료 코드 해석은 안 봤다. 실측: `explorer <경로>` 는 **창이
  정상적으로 열려도 `1`** 을 돌려준다. `succeeded => exitCode == 0` 이므로 Windows 에서
  "폴더 열기" 는 **항상** 실패 배너를 띄우고 있었다 — 간헐적이 아니라 100%, 그런데
  폴더는 열리므로 아무도 버그로 보지 않는다. → 교훈 둘. (1) **OS 분기가 있는 함수는
  분기의 *결과 해석*까지 테스트한다** — 그래서 `revealFailed` 가 OS 를 **인자로** 받는다.
  (2) **AC 를 다 통과해도 못 잡는 결함이 있다.** #32 의 수용 기준에 이 버튼은 없었고,
  왕복을 실제로 돌린 것만이 이걸 드러냈다.

### `verify` 성역 2번

- **`_withoutDependencies` 의 섹션 판정.** pubspec 에는 `flutter:`, `flutter_intl:`,
  `flutter_tweakcn_generator:` 처럼 같은 들여쓰기를 쓰는 설정 블록이 여럿이라, 섹션을
  안 보고 이름만 맞추면 엉뚱한 설정이 통째로 사라진다. 그 함수의 doc-comment 가 이
  문장을 그대로 들고 있다.

### `spine`

- **#24** — `exampleTestDirSegments` 가 없어서 예제를 끈 결과물에 예제를 import 하는
  테스트가 남았다. `flutter analyze` 는 통과시키고 `flutter test` 에서만 터진다.
  `project_generator_test.dart` 의 "예제를 가리키는 참조가 남지 않는다" 가 뒤늦게
  잡았다.
