# ADR-0002 — 복사되는 pubspec 의 섹션마다 무엇을 하는지 정하는 규칙

- **상태:** accepted (2026-08-21)
- **도달한 경로:** #50(`dependency_overrides`) 을 하다가, 같은 질문이 섹션마다 **다른
  답**을 요구한다는 것이 드러났다. 세 자리에서 답이 갈렸고(드롭 / 거절 / 미처리),
  열려 있는 #58(`pubspec.lock`)·#59(`.github/`)가 같은 질문을 다시 묻는다. 개별
  결정으로 두면 섹션이 늘 때마다 같은 발견을 다시 한다.
- **적용 대상:** `ProjectGenerator.copyEntries` 가 결과물로 옮기는 `pubspec.yaml` 의
  톱레벨 섹션. 그리고 앞으로 그 목록에 더해지는 파일.
- **아직 안 정한 것:** 톱레벨 `resolution:` (아래 §4).

## 무엇을 결정하는가

"`dependency_overrides` 를 어떻게 하는가" 가 아니다. 그건 답이고, 이 문서는 **답을
만드는 절차**다. 답만 적으면 `pubspec.lock` 은 또 개별 결정이 된다.

## 왜 이 규칙이 필요한가 — 이 저장소에서만 성립하는 이유

`copyEntries` 는 **allowlist 다.** 파일 단위로 "이건 옮긴다" 를 정하고, 빠뜨리면
결과물이 컴파일되지 않아 즉시 드러난다. 그 성질이 이 파일을 성역 경로로 만든 이유이고
blocklist 제안을 막는 근거다.

그런데 `pubspec.yaml` 은 **파일 하나가 아니라 섹션 여럿**이다. allowlist 는 파일까지만
답하고 그 안은 안 본다. 그래서 pubspec 안에서는 allowlist 의 보호가 **끝난다** —
빠뜨린 섹션이 컴파일 실패로 드러나지 않고, 사용자 머신에서만 터진다.

실측이 그 모양을 보여준다. `_withoutDependencies` 는 `dependencies:` 와
`dev_dependencies:` 를 보고, 그것도 `exampleOnlyDependencies` 에 적힌 **이름으로만**
지운다. 나머지 섹션은 아무도 안 본다. 그 상태가 #50 이었고, 증상은 생성된 프로젝트의
`flutter pub get` 이 **exit 66** 으로 죽는 것이다.

**그래서 판정의 축은 "이 섹션이 위험한가" 가 아니다.** 위험한 것은 이미 알고 있다.
축은 **"위험을 알았을 때 우리가 무엇을 할 수 있는가"** 다.

## 절차 — 축이 둘이다

새 섹션(또는 `copyEntries` 에 더해지는 새 파일)을 만나면 순서대로 묻는다.

### 1. 지워도 결과물이 성립하는가

지웠을 때 pub 이 **스스로 메우면** 예다.

- **예** → **드롭한다.** 결과물에는 아예 안 실린다.
- **아니오** → 2번으로.

`dependency_overrides:` 가 예다. override 를 지우면 그 패키지는 `dependencies:` 의
제약으로 되돌아간다. 실측: pubspec 에서 override 를 뺀 뒤 `pub get` 을 돌리면
`* path 1.9.1 (was 9.9.9 from path ../dep)` 로 **조용히 고쳐지고 exit 0** 이다.
`pubspec.lock` 에 `source: path` 로 이미 구워진 항목도 같이 고쳐진다.

`pubspec.lock`(#58)도 예다 — 없으면 pub 이 새로 해석한다. 그래서 #58 은 이 문서의
1번에서 "드롭해도 되는 것을 **일부러 싣는가**" 라는 별개의 질문이고, 답이 무엇이든
안전하다. 이 문서는 그 질문을 열어둔다.

### 2. 빌더가 고칠 수 있는가 — **여기가 거절선이다**

지우면 안 되는데 빌더가 **올바른 값을 알 수 없으면** 추측하지 않는다.

- **고칠 수 있다** → 고친다 (`name:`, `description:` 이 이 길이다).
- **고칠 수 없다** → **생성을 거절한다.** `_validate` 에서, `flutter create` 보다
  먼저. 아무것도 만들어지지 않으므로 되돌릴 것이 없다.

`dependencies:`/`dev_dependencies:` 의 `path:`·`git:` 소스가 여기다. 로컬 개발 중에
직접 의존성을 형제 저장소로 바꿔보는 것은 정상 작업이고, 그대로 실려 나가면 결과물이
**exit 66** 으로 죽는다 — `dependency_overrides` 와 글자 하나 다르지 않은 실패다.

그런데 **처리는 정반대다.** 지우면 그 패키지가 통째로 사라져 결과물이 컴파일되지
않는다. 그리고 빌더는 `^4.2.0` 인지 `^5.0.0` 인지 알 방법이 없다 — 로컬 경로가 무슨
버전을 담고 있는지는 그 폴더가 말해주지 않는다. **모르는 것을 추측해서 채우면
결과물은 컴파일되고 화면만 다르다.**

### 3. 조용히 성공하는 갈래가 있으면 이름 목록으로 지우지 않는다

1번이 "드롭" 으로 떨어졌을 때, **무엇을 지울지를 이름으로 정하려는 유혹**이 생긴다.
`_withoutDependencies` 가 그 모양이라 재사용하고 싶어진다.

**그 방식은 갈래마다 증상이 다르면 성립하지 않는다.** `dependency_overrides` 의 실측:

| 갈래 | 결과 |
|---|---|
| `path:` | **exit 66** — 시끄럽게 죽는다 |
| hosted 버전 핀 | **exit 0** — lock 에 `dependency: "direct overridden"` 으로 구워진다 |
| `git:` | **exit 0** — 퍼블리시된 적 없는 버전이 `source: git` 으로 구워진다 |

조용한 두 갈래에서는 **지울 이름을 알 방법이 없다.** 그래서 섹션 통째로 드롭한다.

따름정리: **"`pub get` 이 죽는가" 를 기준으로 삼는 탐지기는 전부 틀린 탐지기다.**

### 4. 답이 안 나오면 미처리로 **기록한다** — 조용히 넘기지 않는다

톱레벨 `resolution: workspace` 가 여기다. 결과물에서 같은 **exit 66** 을 낸다(실측 —
워크스페이스 루트를 부모 디렉토리에서 못 찾는다). 1번으로는 드롭이 맞아 보이는데,
이 저장소가 pub workspaces 를 실제로 쓰게 되면 `template/` 이 정당하게 그 키를 갖게
되고 그때 드롭이 옳은지는 그때 재야 한다.

**지금 템플릿에 없으므로 구현하지 않고, 실측값과 함께 적어둔다.** 없는 것을 위해
분류 로직을 이고 가지 않되, 다음 사람이 같은 프로브를 다시 돌리지도 않게 한다.

## 이 규칙이 안 다루는 것 — pubspec 밖의 근거

**override 는 root 패키지에서만 유효하다** (실측: 같은 `child` 패키지를 두고, `app` 이
root 이고 `child` 를 `path:` 로 물면 `collection 1.19.1`, `child` 자신이 root 면
`1.18.0`).

따라서 `template/pubspec.yaml` 의 override 는:

- **빌더 미리보기에 아무 효과가 없다** — 빌더가 root 이고 template 은 `path:` 의존이다.
- `cd template && flutter test` 에서만 먹는다.
- **결과물에서만 root 가 되어, 그때 항상 틀린다.**

이것은 "상대 경로가 사용자 머신에 없다" 보다 강한 논거다. 로컬에서 override 를 걸고
미리보기로 확인한 사람은 **자기가 확인한 것이 override 와 무관하다는 것을 모른다.**

## 상류는 이 규칙을 정하지 않는다 — 다만 침묵하지도 않는다

1층 tie-breaker 는 "상류 `flutter_tools` 가 이긴다 — 미러링이다" 다. **이 자리에는
미러링할 규칙이 없다.** `flutter_tools` 의 `templates/` 전체에 `dependency_overrides`
가 0건이고, `flutter create` 는 기존 pubspec 을 상속하지 않는다.

**그러나 "상류가 침묵한다" 로 적으면 다음 사람이 `lib/` 를 안 연다.** 상류에는 인접
사례에 대한 규칙이 있고, 방법은 스트리핑이 아니라 **구조적 회피**다:

- `widget_preview/preview_pubspec_builder.dart:205-212` — 기존 프로젝트에서 미리보기
  스캐폴드를 파생할 때 `FlutterManifest.copyWith(removeDependencies: true)` 로 의존성을
  **떼고 나중에 다시 붙인다.**
- 같은 파일 `:146-149` — 필요한 override 는 상속하지 않고 `'override:$key:$value'` 로
  **합성해 넣는다** (flutter/flutter#176018).
- `flutter_manifest.dart:87-91` — `removeDependencies` 는 `dependencies` 만 리셋하고
  `dependency_overrides` 는 **안 건드린다.** 베이스가 스캐폴드 자신의 manifest 라서
  상속 문제가 구조적으로 발생하지 않기 때문이다.

즉 상류의 답은 "어느 섹션을 지우는가" 가 아니라 **"애초에 상속하지 않는다"** 이고,
우리는 상속하는 쪽을 골랐다(템플릿을 얹는 것이 이 도구의 정의다). 그래서 우리에게는
섹션별 판정이 필요하고, 상류에는 필요 없다. **갈림이 아니라 전제가 다른 것이다.**

## 증명 방법 — 통과했다고 말하려면

`docs/agents/thegraph.md` 의 1층 절차를 그대로 쓰되, 이 규칙에는 **입력 조건이 하나
더** 붙는다.

**결함을 심은 템플릿으로 돌려야 한다.** 지금 `template/pubspec.yaml` 에는
`dependency_overrides` 가 없다. 그래서 진짜 템플릿으로 생성한 결과물에 거는 어서션은
**수정을 꺼도 초록이다** — 끄고 빨개지는 것을 볼 수가 없다. 두 가지가 따라온다:

1. **판정 함수는 public 순수 함수여야 한다.** 생성기를 통해서는 템플릿이 가진 모양
   하나만 지나간다. `withMainLocale` 이 공개인 이유와 같고, 그 doc-comment 가 이 문장을
   이미 들고 있다.
2. **1층 왕복은 template pubspec 에 결함을 심은 채 돌린다.** 그래서
   `scripts/thegraph/generate.dart` 의 선행 조건은 override 를 **막지 않고 알린다.**
   막으면 그 수정을 증명할 유일한 입력이 사라진다. 회귀는 결과물 쪽 `_outputSane` 이
   잡는다.

**가드와 수정이 반대 방향으로 어긋나지 않게 한다.** 두 가지가 실제로 어긋났다:

- 생 `contains('dependency_overrides:')` 는 **주석 한 줄**에도 걸린다. 누군가 템플릿에
  `# dependency_overrides: 를 여기 두지 말 것` 이라고 적으면 영수증이 영구히 빨개진다.
  → 가드도 **톱레벨 키**로 본다.
- 섹션 헤더를 `==` 로 보는 드롭은 한 줄 flow 스타일
  `dependency_overrides: {a: {path: ../a}}` 를 **놓친다.** → `startsWith` 로 본다.

## 이 규칙이 재현하는 결정과 뒤집는 결정

**재현한다** (= 이 문서가 없어도 같은 답이 나왔어야 하는 것):

- `copyEntries` 가 blocklist 가 아니라 allowlist 인 것. 2번의 거절선은 같은 사고방식이다
  — 모르면 조용히 통과시키지 않고 멈춘다.
- `_withoutDependencies` 가 `exampleOnlyDependencies` 를 **이름으로** 지우는 것.
  그 섹션은 갈래가 하나(`fl_chart`, hosted)이고 우리가 이름을 알므로 3번에 안 걸린다.
- `pubspec_overrides.yaml` 에 아무 처리도 안 하는 것. `copyEntries` 에 없으므로 애초에
  안 실린다 — allowlist 가 이미 답했다.

**뒤집는다:**

- #50 본문의 선택지 (a) — *"`_withoutDependencies` 의 섹션 집합에
  `dependency_overrides:` 를 더한다"*. 3번에 걸려 죽는다(조용한 두 갈래의 이름을 모른다).
  독립적으로, 그 함수의 유일한 호출자가 `_dropExample` 이라 **예제를 켜면 아예 안
  돈다** — 그리고 `includeExample` 의 기본값이 `true` 다.

## 안 정한 것

- **`resolution:` / `workspace:`** — §4.
- **`pubspec.lock` 을 실을지** — #58. 이 문서는 "실어도 안전하다"(1번) 까지만 말하고,
  실을지는 재현성 대 신선도의 판단이라 그 티켓이 정한다. 다만 **`--enforce-lockfile` 을
  켜는 것은 같은 결정이 아니다** — 켜는 순간 1번이 기대는 pub 의 조용한 lock 교정이
  사라진다(실측: 같은 입력에 그 플래그만 붙이면 exit 65,
  `Unable to satisfy pubspec.yaml using pubspec.lock`).
- **`.github/`** — #59. 복사 대상이 아니라 **신규 생성**이라 이 축에 안 걸린다.
- **`environment:` 가 머신에 따라 죽는 것** — 의도다. 템플릿의 툴체인 하한이
  `flutter create` 것을 이기고, 낡은 SDK 에서 죽는 것이 옳다.
  `template/pubspec.yaml` 이 근거를 in-code 로 들고 있다.
