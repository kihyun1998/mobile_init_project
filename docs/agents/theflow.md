# theflow 바인딩

`theflow` 스킬은 방법만 들고 있고 프로젝트별 값은 전부 문서에서 읽는다. 이 파일은
스킬의 일곱 단계를 그 값이 사는 곳으로 **라우팅**한다.

## 값은 여기 없다 — `docs/agents/thegraph.md` 에 있다

이 문서는 원래 값을 직접 들고 있었다. 2026-08-14 에 `/grill-the-graph` 가
`thegraph.md` 를 컴파일하면서 **겹치는 값이 ~43개**가 됐고, 그중 **여섯 군데가 이미
갈려 있었다** — 아무도 눈치채지 못한 채로. 그중 하나는 `sweep` 표면 목록이라,
어느 문서를 읽었는지에 따라 **같은 변경에 대해 done 의 정의가 둘**이 되는 상태였다.

그래서 값을 한 곳으로 모았다. **`thegraph.md` 가 계약이고 이 파일은 포인터다.**
`theflow` 로 시작한 작업은 계속 돌아가되, 단계마다 아래가 가리키는 절을 읽는다.

값을 고칠 일이 생기면 **`thegraph.md` 를 고친다.** 여기에 되살려 적으면 갈림이
그날부터 다시 시작된다.

---

## 전 단계에 적용

| 무엇 | 어디 |
|---|---|
| 교차 확인하는 prior art · tie-breaker | `thegraph.md` § **Tie-breaker — 층마다 다르다** |
| 일부러 갈리는 자리 (deliberate divergences) | `thegraph.md` § **일부러 갈리는 자리** |
| 이슈 번호 표기 (`#` 는 로컬, `ftg#`·`fcb#`·`fdb#` 는 상류) | `thegraph.md` § **이슈 번호 표기** |

**tie-breaker 는 하나가 아니다.** 층마다 다르고, 브리프에 *그 변경이 앉은 층의 행*을
싣는다. 이 문서가 하나만 들고 있던 것이 컴파일에서 잡힌 결함이다.

## 모듈 맵

`thegraph.md` § **boundary — 경계 규칙 (3층)** 과 § **gate** 의 사각지대 1번.

요지만: 루트에 `pubspec.yaml` 이 없고 Flutter 프로젝트가 **둘**이며 워크스페이스로
묶여 있지 않다. **top-level 테스트 명령이 존재하지 않는다.**

---

## Step 1 — 레퍼런스 라우팅

`thegraph.md` § **reference — 소스 클래스 6개**. 그 절의 **라우팅** 표가
`change_type` 별로 어느 클래스를 여는지 정한다.

이 문서가 들고 있던 표는 외부 소스를 **2개**만 들고 있었다. 실제로 읽는 것은
**6개**이고, 나머지 넷의 근거는 이 파일의 war-story 와 `CLAUDE.md` 와 ADR-0001 이
이미 들고 있었다.

### hidden state 목록이 사는 곳

`thegraph.md` § **enumerate — hidden state 목록이 사는 곳**. **늘어나면 거기에
추가한다** (여기가 아니다).

---

## Step 2 — 경계 규칙

`thegraph.md` § **boundary — 경계 규칙 (3층)**.

크로스레포 규칙의 적용 범위(publish 하는 것이 없고 생성물은 포크다)는 같은 절과
§ **노드 로스터** 의 `downstream` 부재 사유에 있다.

---

## Step 4 — 층별 증명 방법

`thegraph.md` § **implement / proof — 층 4개**.

- 1층의 "진짜 생성" 은 그 절의 **1층의 진짜 생성 절차** 에 선행 조건까지 적혀 있다.
- 함정은 같은 절의 **자기 자신을 오독할 수 있는 측정**.

---

## Step 5 — 무조건 완전성 패스가 도는 경로 (성역)

`thegraph.md` § **verify — 성역 경로와 두 렌즈**.

경로가 **셋**으로 늘었고(컴포넌트 디렉토리 추가), 가드가 **경로**와 **의존성** 둘로
나뉜다 — `pubspec.lock` 의 생성기 버전이 움직이면 `preview_theme.dart` 의 사본이
틀려지는데 파일의 바이트는 안 바뀌므로 경로만으로는 안 잡힌다.

---

## Step 6 — 행동을 기술하는 표면

`thegraph.md` § **sweep — 행동을 기술하는 표면 8개**.

- 결정 기록(promotion 목적지) → § **promote — 결정 기록**
- 이미 record 를 가진 영역 → § **search** 의 같은 이름 소절
- 트래커 사용법(하위 이슈·`blocked_by` 의 database id 함정) → § **batch — 어떻게
  트래커에 닿는가**

---

## Step 7 — 게이트 매트릭스

`thegraph.md` § **gate — 명령 목록**. 사각지대와 브랜치/PR/CI 도 그 절에 있다.

`.github/workflows/gates.yml` 의 헤더 주석도 이제 그쪽을 가리킨다.

릴리스 / downstream loop 는 **N/A** — § **노드 로스터** 의 `downstream` 부재 사유.

---

## War-story index

`thegraph.md` § **War-story index**. 전문이 거기 있고, **어느 노드의 가드가 어느
전례에 걸리는지**로 묶여 있다.

새 전례가 쌓이면 거기에 더한다. (`docs/agents/lessons.md` 로 뽑아낸다는 옛 계획은
폐기했다 — 목적지가 둘이면 먼저 움직이는 쪽이 나머지를 고아로 만든다.)
