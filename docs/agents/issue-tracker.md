# 이슈 트래커: GitHub

이 저장소의 이슈와 PRD는 GitHub 이슈로 관리한다. 모든 작업은 `gh` CLI를 사용한다.

저장소는 `git remote -v`로 추론한다 — clone 내부에서 실행하면 `gh`가 자동으로 처리한다. (현재: `kihyun1998/mobile_init_project`)

## 규칙

- **이슈 생성**: `gh issue create --title "..." --body "..."`. 여러 줄 본문은 heredoc을 사용한다.
- **이슈 조회**: `gh issue view <number> --comments`. 댓글은 `jq`로 필터링하고 라벨도 함께 가져온다.
- **이슈 목록**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` — 필요에 따라 `--label`, `--state` 필터를 붙인다.
- **댓글 작성**: `gh issue comment <number> --body "..."`
- **라벨 추가 / 제거**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **종료**: `gh issue close <number> --comment "..."`

## 트리아지 대상으로서의 Pull Request

**PR을 요청 창구로 사용: 아니오.** _(외부 PR을 기능 요청처럼 다루려면 `yes`로 바꾼다. `/triage`가 이 플래그를 읽는다.)_

`yes`로 설정하면 PR도 이슈와 동일한 라벨·상태 체계를 따르며, `gh pr` 명령을 사용한다:

- **PR 조회**: `gh pr view <number> --comments`, diff는 `gh pr diff <number>`
- **트리아지용 외부 PR 목록**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` 실행 후 `authorAssociation`이 `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`인 것만 남긴다 (`OWNER`/`MEMBER`/`COLLABORATOR`는 제외).
- **댓글 / 라벨 / 종료**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`

GitHub는 이슈와 PR이 번호 공간을 공유하므로 `#42`만으로는 구분할 수 없다. `gh pr view 42`로 먼저 확인하고, 실패하면 `gh issue view 42`로 대체한다.

## 스킬이 "이슈 트래커에 등록"이라고 할 때

GitHub 이슈를 생성한다.

## 스킬이 "해당 티켓을 가져오라"고 할 때

`gh issue view <number> --comments`를 실행한다.

## Wayfinding 작업

`/wayfinder`가 사용한다. **맵(map)** 은 하나의 이슈이고, **자식(child)** 이슈들이 티켓이 된다.

- **맵**: `wayfinder:map` 라벨이 붙은 단일 이슈. Notes / Decisions-so-far / Fog 본문을 담는다. `gh issue create --label wayfinder:map`.
- **자식 티켓**: 맵에 GitHub 하위 이슈(sub-issue)로 연결된 이슈 (하위 이슈 엔드포인트에 `gh api` 호출). 하위 이슈 기능을 쓸 수 없으면 맵 본문의 task list에 자식을 추가하고, 자식 본문 맨 위에 `Part of #<map>`을 적는다. 라벨은 `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). 티켓을 맡으면 담당 개발자에게 assign한다.
- **차단(Blocking)**: GitHub의 **네이티브 이슈 의존성**을 정식 표현으로 사용한다. `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>` — 여기서 `<blocker-db-id>`는 차단 이슈의 숫자 **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`이며, `#number`나 `node_id`가 아니다). GitHub는 `issue_dependencies_summary.blocked_by`(열린 차단 이슈만)로 상태를 알려준다. 의존성 기능을 쓸 수 없으면 자식 본문 맨 위에 `Blocked by: #<n>, #<n>` 줄로 대체한다. 모든 차단 이슈가 닫히면 해제된 것으로 본다.
- **프론티어 질의**: 맵의 열린 자식 이슈를 조회하고(`gh issue list --state open`, 맵의 하위 이슈/task list 범위로 한정), 열린 차단 이슈가 있거나(`issue_dependencies_summary.blocked_by > 0` 또는 `Blocked by` 줄에 열린 이슈가 있음) assignee가 있는 항목을 제외한다. 맵 순서상 가장 앞선 것이 선택된다.
- **claim**: `gh issue edit <n> --add-assignee @me` — 세션의 첫 쓰기 작업.
- **해결**: `gh issue comment <n> --body "<answer>"` → `gh issue close <n>` → 맵의 Decisions-so-far에 컨텍스트 포인터(gist + 링크)를 추가한다.
