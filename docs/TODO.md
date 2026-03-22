# TODO

## Oculus_General

- [ ] **레이드프레임 적 시전 알림** (`IncomingCasts`) — ⚠️ API 제약으로 보류
  - **WoW Midnight(12.0)에서 `COMBAT_LOG_EVENT_UNFILTERED` 삭제됨**
  - 레이드/던전/M+/PvP에서 `destGUID`, `spellID` 등이 Secret Value 처리 → 비교/판단 불가
  - WeakAuras도 CLEU 기반 트리거 비활성화, BigWigs/DBM은 Blizzard Boss Timeline API로 전환
  - **대안 검토 필요**:
    - `UNIT_SPELLCAST_START(unit)` — unit token 접근 제한 여부 확인 필요
    - Blizzard Boss Encounter Timeline API — Blizzard 허용 데이터만 사용 가능

- [ ] **설정 사이드바 순서 고정**
  - "일반" 패널이 한글 가나다순으로 맨 뒤에 위치하는 문제
  - WoW Settings API 정렬 방식 조사 필요

## Oculus_RaidFrames

- [ ] **쿨다운 트래킹** (spec에 미구현으로 표기)

- [ ] **적 시전 알림** (spec에 미구현으로 표기) — ⚠️ 위 IncomingCasts API 제약과 동일

## 공통

- [ ] **`gh` CLI PATH 등록**
  - 현재 `/c/Program Files/GitHub CLI/gh.exe` 절대 경로로만 실행 가능
