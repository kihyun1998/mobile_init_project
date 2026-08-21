# CLAUDE.md

Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고하는 지침.

## 이 저장소는 앱이 아니라 도구다

루트에 `pubspec.yaml`이 없다. Flutter 프로젝트가 **두 개** 들어있고, 루트에서 `flutter` 명령을 치면 실패하는 게 정상이다. `cd template` 이나 `cd builder` 를 먼저 해야 한다.

```
template/    뿌릴 템플릿. 그 자체로 flutter run 되는 모바일 앱이다.
builder/     template/ 을 찍어내는 데스크톱 GUI (macOS + Windows).
```

목표: 빌더를 켜서 이름·org·플랫폼을 넣고 tweakcn CSS를 붙여넣어 미리보기로 확인한 뒤, 생성 버튼을 누르면 바로 `flutter run` 되는 새 프로젝트가 나오는 것.

빌더가 하는 일:

1. `flutter create <name> --org <org> --platforms=...` 실행 후 대기
2. `template/` 에서 **allowlist에 있는 것만** 새 프로젝트로 복사
3. `package:mobile_init_project/` → `package:<name>/` 치환, `pubspec.yaml`의 `name:` 교체, 붙여넣은 CSS로 `tweakcn.css` 덮어쓰기
4. `flutter pub get` → `dart run flutter_tweakcn_generator` → `dart run intl_utils:generate` → `dart run build_runner build`

**테마를 다시 만드는 것은 `build_runner` 가 아니다.** 상류 패키지의 `build.yaml` 은 `.tweakcn.css` → `.tweakcn.dart` 만 걸고, `pubspec.yaml` 의 `flutter_tweakcn_generator:` 블록(`input`/`output`)은 CLI 만 읽는다. 우리 파일 이름은 `tweakcn.css` 라 builder 패턴에 애초에 걸리지 않는다. `dart run flutter_tweakcn_generator` 를 빼면 `tweakcn.css` 를 아무리 고쳐도 `tweakcn_theme.g.dart` 는 한 글자도 안 바뀐다 — 컴파일은 되므로 조용하다.

**`template/` 전체를 복사하면 안 된다.** `android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`, `build/`, `.dart_tool/`, `.metadata` 는 `flutter create` 가 새로 만드는 것들이라 덮어쓰면 오히려 망가진다. 복사 대상은 `lib/`, `pubspec.yaml`, `tweakcn.css`, `analysis_options.yaml`, `assets/`, `test/` 다.

**그런데 `pubspec.yaml` 은 파일 하나가 아니라 섹션 여럿이라 allowlist 의 보호가 그 안에서 끝난다.** 섹션마다 무엇을 할지는 **`docs/adr/0002-generated-pubspec-must-be-valid-on-the-users-machine.md`** 가 정한다 — `copyEntries` 에 무엇을 더하기 전에 읽는다. 요지만: 축이 둘이고, **지워도 결과물이 성립하면 드롭**(`dependency_overrides`), **지우면 안 되는데 빌더가 올바른 값을 알 수 없으면 거절**(`dependencies:` 의 `path:`/`git:`) 이다. 추측해서 채우면 결과물은 컴파일되고 화면만 다르다.

## builder/ 작업 규칙

- **`template/` 을 `path:` 의존성으로 문다.** 미리보기 캔버스는 `package:mobile_init_project/...` 를 import해서 **진짜 컴포넌트**를 렌더한다. 미리보기용 사본을 따로 만들지 말 것 — 그 순간 미리보기가 거짓말을 시작한다.
- 미리보기 캔버스는 `template/lib/example/shadcn_components_page.dart` 를 재사용한다. `ProviderScope` 와 `localizationsDelegates` 로 감싸주면 된다.
- 붙여넣은 CSS는 `CssParser.parse()` (flutter_tweakcn_generator가 공개 API로 export한다) 로 파싱해 `Theme(data: ...)` 에 실어 캔버스에 넘긴다. 컴포넌트가 `context.tweakcnColors` = `Theme.of(context).extension<TweakcnColors>()` 로 색을 읽기 때문에 런타임 교체가 그냥 된다.
- **`preview_theme.dart` 의 파생 규칙은 생성기(`DartThemeGenerator`)가 하는 것과 한 글자도 다르면 안 된다.** 색→ColorScheme 매핑, 없는 토큰 처리, `--radius` 기본 8.0 까지 전부. 없는 토큰은 **경로마다 규칙이 다르다** — `TweakcnColors` extension 에서는 투명이지만, `ColorScheme` 에서는 생성기가 `ColorSchemeResolver` 로 파생 fallback 을 넣고 optional 프로퍼티는 아예 생략한다. 미리보기도 그대로 따라간다(`preview_colorscheme_parity_test.dart` 가 진짜 생성기를 돌려 대조한다). "미리보기에서 더 예쁘게 보이도록" 하는 처리를 넣는 순간 미리보기가 거짓말을 시작한다. 반영하지 못하는 것(폰트 등)은 감추지 말고 화면에 알린다.
- **빌더 UI에서는 `.w` `.h` `.sp` `.r` 을 쓰지 말 것.** 미리보기 캔버스가 `ScreenUtil` 싱글톤을 폰 크기(375×812)로 설정하는데 이건 프로세스 전역이다. 데스크톱 폼에서 이 단위를 쓰면 폰 배율이 딸려온다. 데스크톱 쪽은 생짜 논리 픽셀을 쓴다.
- **macOS와 Windows 양쪽에서 돈다.** 경로는 반드시 `package:path` 의 `p.join` 을 쓰고 `/` 를 문자열로 이어붙이지 말 것. `Process.run` 으로 `flutter` 를 부를 땐 `runInShell: true` — Windows에선 `flutter.bat` 이다.
- **macOS 앱 샌드박스를 켜지 말 것.** `builder/macos/Runner/*.entitlements` 의 `com.apple.security.app-sandbox` 는 빼둔 상태다. 켜면 `Directory.current` 가 `~/Library/Containers/…/Data` 가 되어 `../template` 이 해석되지 않고, `Process.run('flutter', …)` 도 실패한다. 즉 이 도구가 하는 일이 전부 막힌다. `flutter create` 로 `macos/` 를 다시 만들면 기본값으로 되살아나므로 주의 — `builder/test/macos_sandbox_test.dart` 가 지키고 있다.
- `template/` 실제 경로는 **저장된 경로 → `../template` → 저장소 루트의 `template`** 순으로 본다. 아무 데도 없으면 폴더를 묻고 `shared_preferences` 에 **절대 경로로** 저장한다. 저장된 것을 기본 위치보다 먼저 보는 이유는, 설정에서 바꿔둔 경로가 조용히 무시되면 바꾼 의미가 없기 때문이다. 고른 폴더가 템플릿인지(필수 항목 + pubspec 의 `name`) 확인한 뒤에 저장한다.

## template/ 작업 규칙

Riverpod + flutter_screenutil + tweakcn 테마 + intl 기반 모바일 앱.

- **크기는 항상 `.w` `.h` `.sp` `.r`.** 생짜 픽셀을 쓰지 말 것. 기준 디자인은 375×812.
- **색·모서리·그림자는 `context.tweakcnColors` / `.tweakcnRadius` / `.tweakcnShadows`.** 하드코딩 금지. 테마를 바꾸려면 `tweakcn.css` 를 고치고 `dart run flutter_tweakcn_generator` 를 돌린다 — `build_runner` 는 이 파일을 보지 않는다. 생성물은 커밋한다.
  - **어느 컴포넌트가 어느 단계를 쓰는지는 shadcn 원본이 정한 것을 따라간다** — 우리가 고르지 않는다. `--radius` 는 #23, `--shadow-*` 는 #25 에서 `shadcn-ui/ui` 의 `apps/v4/registry/new-york-v4/ui/*.tsx` 를 실측해 정했고, 각 컴포넌트가 `file:line` 으로 근거를 달고 있다. 새 컴포넌트를 만들면 형제에서 유추하지 말고 그 파일을 읽는다.
  - **원본이 안 거는 자리에는 우리도 안 건다.** 그림자는 카드(`shadow-sm`)·입력·outline 버튼·라디오 표시기·스위치 트랙·select 트리거·체크박스(`shadow-xs`)·select 메뉴(`shadow-md`)·날짜 다이얼로그(`shadow-lg`) 뿐이고, 기본 버튼·뱃지·아바타·구분선·표·달력은 원본에도 없다.
  - **체크박스만 `BlurStyle.outer` 로 싣는다.** CSS 의 바깥 `box-shadow` 는 요소 뒤로 잘리는데 Flutter 의 기본값은 도형 밑까지 칠하고, 체크박스의 `inactiveColor` 가 투명이라 그대로 실으면 안 켜진 상자를 통과해 비친다. 값을 바꾸는 게 아니라 CSS 의미론을 미러링하는 것이고, 상류가 릴리스 노트에서 직접 권한 방법이다. 다른 컴포넌트는 배경이 불투명해서 이 문제가 없다.
  - 그림자 값은 `context.tweakcnShadows.shadowSm.r` 처럼 **`.r` 을 걸어 읽는다** (`shadcn_shadow.dart` 의 확장). 모서리가 배율을 타므로 그림자도 타야 한다.
- **provider를 추가하면 codegen을 돌려야 한다.** `@riverpod` 애노테이션 + `part 'x.g.dart';` + `dart run build_runner build --delete-conflicting-outputs`.
- **번역 추가**는 `lib/core/localization/l10n/intl_{ko,en}.arb` 를 고치고 `dart run intl_utils:generate`. 생성물은 커밋한다.
- 생성 파일(`*.g.dart`, `generated/`)은 전부 커밋되어 있다. 빌더가 복사만으로 컴파일되게 하려는 의도이니 gitignore에 넣지 말 것.
- **예제 페이지를 import 하는 테스트는 `test/example/` 안에 둔다.** 빌더가 예제를 끌 때 `lib/example` 과 함께 이 폴더를 지운다. 밖에 두면 지워진 파일을 import 하는 테스트가 결과물에 남아 `flutter test` 에서만 터진다 — `flutter analyze` 는 통과시키므로 조용하다.
- shadcn 컴포넌트는 `lib/ui/components/` 에 `shadcn_*.dart` **15개**로 있고 **provider·l10n·navigation 을 물지 않는다.** 끌어들이는 순간 빌더 미리보기가 깨진다 — 이게 격리의 이유다. **개수의 단위는 파일이고**(위젯 수가 아니다) `builder/test/component_count_test.dart` 가 지킨다 — 근거는 #49. `app_bottom_nav_bar.dart` 는 이 디렉토리에 있지만 shadcn 컴포넌트가 아니고 l10n·navigation 을 문다. 끌어들이는 순간 빌더 미리보기가 깨진다 — 이게 격리의 이유다. `app_bottom_nav_bar.dart` 는 이 디렉토리에 있지만 shadcn 컴포넌트가 아니고 l10n·navigation 을 문다.
  - 컴포넌트끼리 서로 import 하는 것은 된다 (`shadcn_date_picker` → `shadcn_calendar`).
  - **순수 UI 패키지를 무는 것도 된다** (`shadcn_checkbox` → `flutter_checkbox`, `shadcn_select` → `flutter_dropdown_button`). 절차와 근거는 **`docs/adr/0001-external-ui-package-adoption.md`** 에 있다 — 새 패키지를 들이기 전에 읽는다. 요지만: 판정의 축은 "패키지가 좋은가" 가 아니라 **"안 넘긴 색이 어디서 오는가"** 이고, 그 답이 `colorScheme` 파생이면 안 넘겨도 되지만 `ThemeData` 레거시 필드면 **도달 가능한 슬롯을 전부 명시적으로 채워야 한다.** 빠뜨린 색은 컴파일도 테스트도 통과하고 화면만 다르다.
  - **`package:flutter/widgets.dart` 의 기본형 위에 앉는 것도 된다** (`shadcn_radio_group` → `RawRadio` + `RadioGroup`, `shadcn_switch` → `ToggleableStateMixin`). 둘 다 **그림은 우리가 그리게** 두면서 시맨틱·포커스·키보드를 맡는다. 색과 치수를 한 글자도 안 바꾸고 옮길 수 있다.
- **접근성은 손으로 `Semantics` 를 붙이기 전에 상류 기본형부터 찾고, 플래그 이름을 형제에서 유추하지 않는다.** 라디오는 `checked` 인데 **스위치는 `toggled`** 다 (`material/switch.dart:1074`). 자명해 보이는 자리가 아니다 — `RawRadio` 는 `selected` 와 `hint` 를 **플랫폼마다 다르게** 싣고(iOS 는 `selected` 로 이미 알리므로 둘 다 세우면 중복 안내), 그 `hint` 는 `flutter_localizations` 가 언어별로 들고 있다(ko = `"선택되지 않음"`). 손으로 붙이면 두 분기를 다 놓치고 문구를 우리 arb 에 새로 만들게 되는데 **테스트는 초록이다.**
  - 시맨틱에 플랫폼 분기가 있으면 `testWidgets(..., variant: TargetPlatformVariant.only(...))` 로 바꾼다 — `ThemeData.platform` 을 바꾸는 것으로는 분기가 안 돈다. 스위치에는 분기가 없다(Cupertino 의 `defaultTargetPlatform` 분기는 햅틱용이다).
  - **`matchesSemantics` 는 그 노드 하나만 본다.** 밑에 자식 노드가 더 붙어도 통과하므로, 컨트롤을 겹쳐 넣지 않았는지 보려면 `node.childrenCount` 를 함께 본다. 라벨 붙은 컨트롤은 안쪽에 또 컨트롤을 두지 말고 **그림만** 넣는다.
- **날짜·요일 계산도, 날짜를 *읽어주는 문구*도 `MaterialLocalizations` 를 거친다.** 날짜 셀의 시맨틱 라벨은 `formatDecimal(일) + ', ' + formatFullDate(날짜)` 이고 오늘이면 `', ' + currentDateLabel` 을 붙인다 — Material 의 날짜 셀과 같은 형태다 (`material/calendar_date_picker.dart:1295`). 숫자를 앞에 한 번 더 붙이는 것은 상류가 이유를 주석으로 적어둔 결정이고(보조기술 사용자는 몇 일인지를 먼저 찾는다), 문구가 전부 상류에서 오므로 우리 arb 에 만들 것이 없다.
- **날짜·요일 계산은 손으로 만들지 말고 `MaterialLocalizations` 를 거친다.** `narrowWeekdays` 는 일요일 시작 고정 배열이라 `firstDayOfWeekIndex` 로 회전시켜야 하고(`shadcn_calendar.dart` 의 `shadcnWeekdayOrder`), 날짜 산술은 `add(Duration(days: 1))` 이 아니라 `DateTime` 생성자로 한다 — 서머타임 경계에서 하루를 건너뛴다. 참고로 ko·en 은 둘 다 일요일 시작이라 회전 경로가 두 언어만으로는 검증되지 않는다.

## 상류 대기

우리 쪽에서 할 일이 없고 **상류가 고쳐줘야 풀리는 것**들. 여기 있는 동안은
하류에서 덧씌우지 않는다 — 그 판단의 근거는 `docs/adr/0001-…` 과 #27 이다.

| 무엇이 없나 | 상류 | 풀리면 할 일 | 자동으로 알 수 있나 |
|---|---|---|---|
| _(비어 있음)_ | | | |

**이 표가 한 번 제 역할을 다했다 (2026-08-17).** 유일한 항목이었던 *"select 트리거에
`isButton`, 열린 메뉴의 선택된 행에 `isSelected` 가 없다"* 가
`kihyun1998/flutter_dropdown_button` 4.2.0 에서 풀렸다(#88, #91). 제약을 `^4.2.0` 으로
올리자 **"자동으로 알 수 있나 = 예" 에 적어둔 그대로** `shadcn_select_test.dart` 의 두
테스트가 빨개졌고 — `matchesSemantics` 가 안 적은 플래그를 전부 false 로 보므로 —
그 자리에서 없음이 아니라 **있음**을 못박도록 뒤집었다. 실측된 트리거 플래그는
`[isButton, hasEnabledState, isEnabled, isFocusable, hasExpandedState]`.

같이 확인된 것: **덧씌우지 않고 기다린 판단(#27, `docs/adr/0001-…`)이 옳았다.** 하류에서
`Semantics` 를 붙였다면 지금 상류 노드와 충돌하는 것을 걷어내고 있었을 것이다.

이 표는 열린 이슈가 들고 있는 항목을 옮겨 적지 않는다. 이 파일은 매 세션 자동으로
읽히지만 `gh issue list` 는 아니라서, 닫힌 이슈에만 남겨두면 아무도 다시 안 본다 —
**이슈가 없는** 항목은 여기에 전부 적는다.

**전에 여기 있던 체크박스 그림자 항목은 풀렸다** — `flutter_checkbox` 0.3.2 가
`CheckboxStyle.shadows` 를 줬고 우리가 넘긴다. 같은 릴리스가 시맨틱 결함
(`flutter_checkbox#7`)도 고쳐서 라벨 붙은 체크박스가 `isFocusable` 과 `focus` 를
되찾았다 — `shadcn_checkbox_test.dart` 의 "라벨이 있든 없든 focusable 이 나간다" 가
그 수정을 잠근다. 재계수는 `docs/adr/0001-…` §3 의 2026-08-16 항목에 있다.

**그 절차가 어떻게 발견됐는지는 적어둘 값이 있다.** "자동으로 알 수 있나" 열이
**아니오**였고 실제로 아무도 몰랐다. 드러난 것은 임시 폴더에 진짜 프로젝트를 한 번
만들어 본 것(`scripts/thegraph/generate.dart`) 덕이다 — 새로 만들어지는 프로젝트는
`pubspec.lock` 을 물려받지 않아 `^0.3.1` 안에서 **0.3.2 를 새로 해석**했고, 그
차이가 테스트 두 개를 빨갛게 만들면서 릴리스 노트를 읽게 했다.

## 명령어

```bash
cd template && flutter run                                  # 템플릿 앱 실행
cd template && dart run build_runner build --delete-conflicting-outputs
cd template && dart run intl_utils:generate
cd template && dart run flutter_tweakcn_generator     # tweakcn.css → tweakcn_theme.g.dart
cd builder  && flutter run -d macos                         # 빌더 실행
```

## Agent skills

### 작업 방식

기능 슬라이스·버그 수정·공개 표면을 건드리는 리팩토링은 `thegraph` 를 따른다. **프로젝트별 값은 전부 `docs/agents/thegraph.md` 에 있고 그것이 계약이다** — 노드 로스터, 레퍼런스 라우팅, 경계 규칙, 층별 tie-breaker, 증명 방법, 성역 경로, 게이트 매트릭스, 트래커 사용법, war story.

`theflow` 도 계속 돌아간다. 다만 `docs/agents/theflow.md` 는 이제 **일곱 단계 구조와 포인터만** 들고 있고 값은 `thegraph.md` 에서 읽는다 — 같은 값을 두 곳에 두면 갈리고, 갈렸을 때 아무것도 그것을 검사하지 않는다.

### 이슈 트래커

이슈는 `kihyun1998/mobile_init_project`의 GitHub 이슈로 관리하며 `gh` CLI를 사용한다. `docs/agents/issue-tracker.md` 참고.

### 트리아지 라벨

다섯 가지 표준 트리아지 역할을 사용하며, 라벨 문자열은 역할 이름과 동일하다. `docs/agents/triage-labels.md` 참고.

### 도메인 문서

싱글 컨텍스트 구성 — 루트의 `CONTEXT.md` + `docs/adr/`. `docs/agents/domain.md` 참고.
