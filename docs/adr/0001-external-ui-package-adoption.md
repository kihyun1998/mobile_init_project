# ADR-0001 — 외부 UI 패키지를 template 에 들이는 규칙

- **상태:** accepted (2026-08-05)
- **도달한 경로:** #27(`flutter_checkbox`) → #31(`flutter_dropdown_button`). 두 번째에서
  첫 번째의 판정 기준이 **거짓인 경우**가 나와서, 개별 결정으로 두면 남은 패키지마다
  같은 발견을 다시 해야 한다는 것이 드러났다.
- **적용 대상:** `template/lib/ui/components/` 의 shadcn 컴포넌트가 무는 순수 UI 패키지.
- **아직 안 잰 후보:** `flutter_table_plus`, `flutter_otp_widget`.

## 무엇을 결정하는가

"이 패키지를 써도 되는가" 가 아니다. 그건 답이고, 이 문서는 **답을 만드는 절차**다.
답만 나열하면 세 번째 패키지는 또 개별 결정이 된다.

## 왜 이 규칙이 필요한가 — 이 저장소에서만 성립하는 이유

빌더의 유일한 가치는 **미리보기가 생성 결과와 같다**는 것이다. 그 등식은 미리보기와
생성물이 `path:` 의존으로 **같은 파일을 컴파일**하기 때문에 성립한다.

외부 패키지는 이 등식을 깨지 않는다. 양쪽이 같은 패키지를 쓰니까. 깨는 것은 다른
등식이다 — **"화면의 색 = 붙여넣은 CSS"**. 패키지가 색을 어딘가 **우리가 안 채우는
곳**에서 가져오면, 미리보기와 생성물은 사이좋게 **똑같이 틀린 색**을 그린다. 패리티
테스트는 초록이고, 아무도 모른다.

그래서 판정의 축은 "패키지가 좋은가" 가 아니라 **"안 넘긴 값이 어디서 오는가"** 다.

## 절차

### 1. 색을 우리가 주입할 수 있는가 — 통과 못 하면 여기서 끝

입력 테마의 색 필드가 `Color?` 인지 본다. non-nullable 이 하나라도 있으면 패키지가
자기 색을 정한다는 뜻이고, 그 매핑이 새 표면이 되므로 **쓰지 않는다**.

- 전례: #23 에서 `table_calendar` 를 이 기준으로 거부했다.
- 통과 실물: `flutter_checkbox` 의 `CheckboxStyle` 7개, `flutter_dropdown_button` 의
  7개 서브테마 합 24개 — 양쪽 다 non-nullable 0.

**`Color?` 만 세면 안 된다.** 색은 `Border?`, `BoxDecoration?`, `TextStyle?` 안에도
들어 있다. #31 에서 `Color?` 24개 밖에 테두리 3개와 글자색 4개가 더 있었다.

### 2. 안 넘긴 값이 어디서 오는가 — **여기가 작업량을 가른다**

패키지 소스에서 fallback 표현(`x ?? something`)의 오른쪽을 전부 찾아 분류한다.

| 출처 | 뜻 | 해야 할 일 |
|---|---|---|
| `theme.colorScheme.*` | `TweakcnTheme` 가 채우는 곳 → 결국 CSS 에서 온다 | 안 넘겨도 된다 |
| `ThemeData` 레거시 필드 | `TweakcnTheme` 가 **안** 채운다 → Material 기본색 | **전부 명시적으로 채운다** |
| 패키지 자체 상수 | CSS 와 무관 | **전부 명시적으로 채운다** |

- `flutter_checkbox` → 1행. `resolve()` 가 hover/focus/splash 를 `colorScheme.primary`
  에서 파생한다 (`checkbox_style.dart:213-232`).
- `flutter_dropdown_button` → 2행. `DropdownAmbientColors.of(context)` 가
  `splashColor`·`highlightColor`·`hoverColor`·`disabledColor`·`hintColor`·
  `iconTheme.color` 를 읽는다 (`resolved_dropdown_style.dart:24-37`).

**이 판정에는 유효 조건이 붙는다.** 1행 판정은 `TweakcnTheme` 가 `colorScheme` 을
CSS 로 채우는 한 유효하고, `preview_colorscheme_parity_test` 가 그 매핑을 지킨다.

### 3. 도달성으로 분할한다 — "전부 채운다" 는 "존재하는 전부" 가 아니다

2번이 2·3행이면 슬롯을 **우리 구성에서 실제로 그려지는 것**과 아닌 것으로 나눈다.
도달 못 하는 슬롯을 채우는 것은 완전함이 아니라 **낡을 근거를 하나 더 만드는 것**이다.

- 도달하는 것 → 전부 채운다.
- 도달 못 하는 것 → **`file:line` 으로 근거를 doc-comment 에 적는다.** "안 쓰니까"
  는 근거가 아니다. 그 코드에 들어갈 수 없는 이유를 소스에서 짚는다.

#31 실물: 24개 중 16 도달 / 8 불가 (checkbox 4 = 단일선택이 그 경로를 안 탄다
`item_presentation.dart:375`, search 2 = `dropdown_menu_shell.dart:593` 의 게이트,
tooltip 2 = 커스텀 모드가 `tooltipTheme` 을 안 받는다).

> **갱신 (2026-08-08, #25) — 위 16/8 은 더 이상 현재 값이 아니다. 도달성은
> 우리가 무엇을 넘기느냐로도 바뀐다.** 아래 "구성이 도달성을 바꾼다" 의 더 강한
> 형태다. #25 에서 select 트리거와 메뉴에 그림자를 실으려고 `decoration` 을
> 통째로 넘겼는데, 그 슬롯은 `backgroundColor`·`border`·`borderRadius` 를
> **대신하는** 것이라 (`dropdown_button_theme.dart:52-54`) 그 순간 다섯이
> 도달 불가가 됐다: `button.backgroundColor`, `button.border`,
> `button.disabledBackgroundColor`, `button.disabledBorder`, `overlay.border`.
> 그래서 안 채우고, 그리는 값은 `decoration` 안에서 본다.
>
> **`overlay.backgroundColor` 는 반대다 — `decoration` 을 넘겨도 계속 도달한다.**
> `resolveOverlay` 가 그것을 `decoration` 과 별개로 계산해 스크롤 페이드의
> `fadeInto` 로 넘긴다 (`dropdown_overlay_theme.dart:73, 85` →
> `dropdown_menu_shell.dart:562`). "같은 서브테마에 나란히 있는 두 필드" 라는
> 이유로 함께 판정하면 여기서 틀린다.
>
> 즉 3번은 채택 시점에 **한 번** 하는 판정이 아니다. 넘기는 슬롯을 바꾸는
> 변경마다 다시 센다 — 안 그러면 "빈 슬롯 없음" 테스트가 **그리지도 않는 값**을
> 지키게 되고, 그건 초록인 채로 아무것도 증명하지 않는다.

**구성 자체가 도달성을 바꿀 수 있다.** #31 은 텍스트 모드 대신 커스텀 모드를 골라
tooltip 2개를 도달 불가로 만들었다. 슬롯을 줄이는 구성이 있으면 그쪽이 낫다.

### 4. 플랫폼 — `android`/`ios` 가 있는가

모바일 템플릿이다. `flutter_password_input` 이 이 기준으로 탈락했다(`windows`·
`macos`·`web` 뿐).

### 5. SDK 하한을 대조한다

하한은 상류에서 하류로 **그대로 내려가** 생성되는 모든 프로젝트에 붙는다. 움직이면
`template/pubspec.yaml` 의 `environment:` 를 고치고 **왜 움직였는지 적는다**
(커밋 `b081ae1` 이 반대 방향으로 틀렸던 전례).

## 증명 방법 — 통과했다고 말하려면

절차를 밟았다는 것과 맞다는 것은 다르다.

1. **넘긴 값을 렌더 트리에서 꺼내 확인한다.** 같은 계산을 다시 돌려 비교하면
   동어반복이다 — #27 에서 그렇게 썼다가 색을 형광초록으로 바꾸는 변이에도 12개가
   전부 초록이었다.
2. **"빈 슬롯이 없다" 를 값 비교보다 먼저 본다.** 빠뜨린 색은 컴파일도 테스트도
   통과하고 화면만 다르다.
3. **변이를 실제로 돌린다.** 슬롯 하나를 지우고 빨개지는 것을 본다.
4. **dark 로도 잰다.** light 는 토큰이 충돌해서 틀린 매핑을 통과시킨다 —
   `ThemeData.cardColor` 가 light 에서 `card`·`background`·`popover` 와 전부 같고,
   `primaryColor` 는 **dark 에서만** `colorScheme.surface` 로 떨어진다. #31 에서
   `popover`→`card` 변이를 **light 는 통과시키고 dark 만 잡았다.**
5. **미리보기에서 렌더된 픽셀을 본다.** 토큰 쌍이 서로 다른 값인 CSS 로.
6. **진짜 생성 1회.** 예제를 끄는 경로도 같이 — 새 의존성이
   `exampleOnlyDependencies` 에 안 걸리는지가 거기서 드러난다.

## 이 규칙이 재현하는 결정과 뒤집는 결정

**재현(증거):** `table_calendar` 거부(1번), `flutter_password_input` 거부(4번),
`flutter_checkbox` 채택 + 색 안 넘겨도 됨(2번 1행), `flutter_dropdown_button` 채택 +
16개 명시(2번 2행 + 3번).

**뒤집음:** #27 이 남긴 판정 기준 2번 문장 — "`resolve()` 가 `colorScheme.primary`
에서 파생하므로 테마 밖 색이 새지 않는다" 는 **그 패키지에 한해서만** 참이다.
일반 규칙으로 읽으면 거짓이고, #31 이 그것을 실측으로 뒤집었다. 이 ADR 의 2번 표가
그 자리를 대신한다.

## 안 정한 것

- **안 쓰는 컴포넌트의 패키지를 생성물에서 빼는가.** `--example` 이 `fl_chart` 를
  빼듯 할지는 별개 결정이다. 네 패키지를 다 넣어본 뒤에 판단한다 (#27 이 미룬 것).
- **패키지 업그레이드 시 재열거.** `^` 범위 안에서 새 ambient 소비 슬롯이 생기면
  "빈 슬롯 없음" 테스트는 아는 슬롯만 보므로 못 잡는다. 지금은 각 컴포넌트의
  doc-comment 에만 적어 두고, 세 번째 패키지에서 다시 본다.
