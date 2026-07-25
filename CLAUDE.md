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
3. `package:mobile_init_project/` → `package:<name>/` 치환, `pubspec.yaml`의 `name:` 교체
4. `flutter pub get` → `dart run intl_utils:generate` → `dart run build_runner build`

**`template/` 전체를 복사하면 안 된다.** `android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`, `build/`, `.dart_tool/`, `.metadata` 는 `flutter create` 가 새로 만드는 것들이라 덮어쓰면 오히려 망가진다. 복사 대상은 `lib/`, `pubspec.yaml`, `tweakcn.css`, `analysis_options.yaml`, `assets/`, `test/` 다.

## builder/ 작업 규칙

- **`template/` 을 `path:` 의존성으로 문다.** 미리보기 캔버스는 `package:mobile_init_project/...` 를 import해서 **진짜 컴포넌트**를 렌더한다. 미리보기용 사본을 따로 만들지 말 것 — 그 순간 미리보기가 거짓말을 시작한다.
- 미리보기 캔버스는 `template/lib/example/shadcn_components_page.dart` 를 재사용한다. `ProviderScope` 와 `localizationsDelegates` 로 감싸주면 된다.
- 붙여넣은 CSS는 `CssParser.parse()` (flutter_tweakcn_generator가 공개 API로 export한다) 로 파싱해 `Theme(data: ...)` 에 실어 캔버스에 넘긴다. 컴포넌트가 `context.tweakcnColors` = `Theme.of(context).extension<TweakcnColors>()` 로 색을 읽기 때문에 런타임 교체가 그냥 된다.
- **macOS와 Windows 양쪽에서 돈다.** 경로는 반드시 `package:path` 의 `p.join` 을 쓰고 `/` 를 문자열로 이어붙이지 말 것. `Process.run` 으로 `flutter` 를 부를 땐 `runInShell: true` — Windows에선 `flutter.bat` 이다.
- `template/` 실제 경로는 `../template` 을 먼저 보고, 없으면 사용자에게 폴더를 묻고 `shared_preferences` 에 저장한다.

## template/ 작업 규칙

Riverpod + flutter_screenutil + tweakcn 테마 + intl 기반 모바일 앱.

- **크기는 항상 `.w` `.h` `.sp` `.r`.** 생짜 픽셀을 쓰지 말 것. 기준 디자인은 375×812.
- **색·모서리·그림자는 `context.tweakcnColors` / `.tweakcnRadius` / `.tweakcnShadows`.** 하드코딩 금지. 테마를 바꾸려면 `tweakcn.css` 를 고치고 재생성한다.
- **provider를 추가하면 codegen을 돌려야 한다.** `@riverpod` 애노테이션 + `part 'x.g.dart';` + `dart run build_runner build --delete-conflicting-outputs`.
- **번역 추가**는 `lib/core/localization/l10n/intl_{ko,en}.arb` 를 고치고 `dart run intl_utils:generate`. 생성물은 커밋한다.
- 생성 파일(`*.g.dart`, `generated/`)은 전부 커밋되어 있다. 빌더가 복사만으로 컴파일되게 하려는 의도이니 gitignore에 넣지 말 것.
- shadcn 컴포넌트 13개는 `lib/ui/components/` 에 있고 `material` + `screenutil` + 생성된 테마 외엔 아무것도 import하지 않는다. **이 격리를 깨지 말 것** — provider나 l10n을 끌어들이는 순간 빌더 미리보기가 깨진다.

## 명령어

```bash
cd template && flutter run                                  # 템플릿 앱 실행
cd template && dart run build_runner build --delete-conflicting-outputs
cd template && dart run intl_utils:generate
cd builder  && flutter run -d macos                         # 빌더 실행
```

## Agent skills

### 이슈 트래커

이슈는 `kihyun1998/mobile_init_project`의 GitHub 이슈로 관리하며 `gh` CLI를 사용한다. `docs/agents/issue-tracker.md` 참고.

### 트리아지 라벨

다섯 가지 표준 트리아지 역할을 사용하며, 라벨 문자열은 역할 이름과 동일하다. `docs/agents/triage-labels.md` 참고.

### 도메인 문서

싱글 컨텍스트 구성 — 루트의 `CONTEXT.md` + `docs/adr/`. `docs/agents/domain.md` 참고.
