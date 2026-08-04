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
- **색은 `context.tweakcnColors`.** 하드코딩 금지. (**모서리·그림자는 이 규칙이 코드와 어긋나 있다** — `tweakcnRadius`/`tweakcnShadows` 를 읽는 컴포넌트가 하나도 없고 전부 `.r` 하드코딩이다. 규칙과 코드 중 어느 쪽을 움직일지는 #25 가 들고 있다. 그때까지 새 컴포넌트는 형제 관례대로 하드코딩한다.) 테마를 바꾸려면 `tweakcn.css` 를 고치고 `dart run flutter_tweakcn_generator` 를 돌린다 — `build_runner` 는 이 파일을 보지 않는다. 생성물은 커밋한다.
- **provider를 추가하면 codegen을 돌려야 한다.** `@riverpod` 애노테이션 + `part 'x.g.dart';` + `dart run build_runner build --delete-conflicting-outputs`.
- **번역 추가**는 `lib/core/localization/l10n/intl_{ko,en}.arb` 를 고치고 `dart run intl_utils:generate`. 생성물은 커밋한다.
- 생성 파일(`*.g.dart`, `generated/`)은 전부 커밋되어 있다. 빌더가 복사만으로 컴파일되게 하려는 의도이니 gitignore에 넣지 말 것.
- **예제 페이지를 import 하는 테스트는 `test/example/` 안에 둔다.** 빌더가 예제를 끌 때 `lib/example` 과 함께 이 폴더를 지운다. 밖에 두면 지워진 파일을 import 하는 테스트가 결과물에 남아 `flutter test` 에서만 터진다 — `flutter analyze` 는 통과시키므로 조용하다.
- shadcn 컴포넌트 15개는 `lib/ui/components/` 에 있고 **provider·l10n·navigation 을 물지 않는다.** 끌어들이는 순간 빌더 미리보기가 깨진다 — 이게 격리의 이유다. `app_bottom_nav_bar.dart` 는 이 디렉토리에 있지만 shadcn 컴포넌트가 아니고 l10n·navigation 을 문다.
  - 컴포넌트끼리 서로 import 하는 것은 된다 (`shadcn_date_picker` → `shadcn_calendar`).
  - **순수 UI 패키지를 무는 것도 된다** (`shadcn_checkbox` → `flutter_checkbox`). 조건은 **색을 우리가 주입할 수 있어야 한다**는 것이다 — 패키지가 자기 테마로 색을 정하면 그 매핑이 미리보기와 생성 결과를 가르는 새 표면이 되므로 쓰지 않는다. `flutter_checkbox` 는 `CheckboxStyle` 의 색 필드가 전부 `Color?` 라 우리가 주는 값이 그대로 그려지고, 안 넘긴 오버레이 색도 `theme.colorScheme.primary` 파생이라 결국 붙여넣은 CSS 에서 온다.
  - 패키지를 들일 때 **pub.dev 가 선언하는 플랫폼에 `android`/`ios` 가 있는지 먼저 본다.** 이건 모바일 템플릿이다 (`flutter_password_input` 이 그 이유로 탈락했다).
- **날짜·요일 계산은 손으로 만들지 말고 `MaterialLocalizations` 를 거친다.** `narrowWeekdays` 는 일요일 시작 고정 배열이라 `firstDayOfWeekIndex` 로 회전시켜야 하고(`shadcn_calendar.dart` 의 `shadcnWeekdayOrder`), 날짜 산술은 `add(Duration(days: 1))` 이 아니라 `DateTime` 생성자로 한다 — 서머타임 경계에서 하루를 건너뛴다. 참고로 ko·en 은 둘 다 일요일 시작이라 회전 경로가 두 언어만으로는 검증되지 않는다.

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

기능 슬라이스·버그 수정·공개 표면을 건드리는 리팩토링은 `theflow` 를 따른다. 프로젝트별 값(모듈 맵, 레퍼런스 라우팅, 경계 규칙, 증명 방법, 성역 경로, 게이트 매트릭스)은 전부 `docs/agents/theflow.md` 에 있다.

### 이슈 트래커

이슈는 `kihyun1998/mobile_init_project`의 GitHub 이슈로 관리하며 `gh` CLI를 사용한다. `docs/agents/issue-tracker.md` 참고.

### 트리아지 라벨

다섯 가지 표준 트리아지 역할을 사용하며, 라벨 문자열은 역할 이름과 동일하다. `docs/agents/triage-labels.md` 참고.

### 도메인 문서

싱글 컨텍스트 구성 — 루트의 `CONTEXT.md` + `docs/adr/`. `docs/agents/domain.md` 참고.
