# Oculus_RaidFrames

## 역할

파티/레이드 CompactUnitFrame 의 가시성 토글, 파티 프레임 스케일, 사거리 투명도 처리.

> **12.0.5 PrivateAura 도입 이후**: 버프/디버프 표시는 PrivateAura 시스템으로 통합되었고
> 해당 anchor 와 button template 은 forbidden scope. 애드온이 `CompactUnitFrame_SetMaxBuffs`
> / `SetAuraSize` / 개별 버튼 조작을 시도하면 frame taint 또는 ADDON_ACTION_BLOCKED 가 발생.
> 그래서 본 모듈은 **버프/디버프 커스터마이징 기능을 제공하지 않음** — 가시성 토글, 사거리
> 투명도, 파티 스케일 등 child region 알파/secret-safe API 만 사용하는 기능에 한정.

## 기능

### 1. 프레임 가시성 토글
- 역할 아이콘 숨김 (`HideRoleIcon`)
- 이름 텍스트 숨김 (`HideName`)
- 어그로 오버레이 숨김 (`HideAggroBorder`)
- 파티/레이드 그룹 타이틀 숨김 (`HidePartyTitle`)
- 디스펠 오버레이 숨김 (`HideDispelOverlay`, forbidden scope 가드 포함)

### 2. 파티 프레임 스케일
- `CompactPartyFrame:SetScale()` 로 파티 프레임 전체 배율 조정 (50%~200%)
- 전투 중에는 secure frame protection 으로 적용 불가 → `InCombatLockdown()` 가드

### 3. 사거리 투명도 (Range Fade)
- `frame:SetAlphaFromBoolean(UnitInRange(unit), 1.0, MinAlpha)` — 12.0 secret boolean 안전 API
- 최소 불투명도 슬라이더로 사거리 밖 알파값 조정

## 설정 옵션

```lua
OculusRaidFramesStorage = {
    Enabled = true,
    Frame = {
        Scale = 100,
        HideRoleIcon = false,
        HideName = false,
        HideAggroBorder = false,
        HidePartyTitle = false,
        HideDispelOverlay = false,
        RangeFade = {
            Enabled = true,
            MinAlpha = 0.55,
        },
    },
}
```

## 설정 UI

ESC > 인터페이스 > 애드온 > Oculus > Raid Frames

단일 패널 (탭 없음). `ConfigFrameTab.lua` 가 모든 설정을 표시.

## 외부 연동

없음. 12.0.5 에서 Masque 는 forbidden scope 인 Blizzard buff/debuff 버튼에 적용 불가.

## 파일 구조

```
Oculus_RaidFrames/
├── Oculus_RaidFrames.toc
├── RaidFrames.lua        -- 모듈 초기화, 스토리지, Auras 서브모듈 enable/disable
├── Auras.lua             -- 가시성/스케일/사거리 페이드 로직 (visibility/scale/rangefade)
├── Config.lua            -- 설정 패널 생성, 컨트롤 위젯 헬퍼
└── ConfigFrameTab.lua    -- Frame Settings UI
```

## 기술 구현 메모

### 후킹 전략

12.0.5 에서 `hooksecurefunc("CompactUnitFrame_UpdateAuras", ...)` 같은 훅은 콜백 안에서
`C_Timer.After` 만 호출해도 후속 같은 스택의 Blizzard 코드를 우리 taint 컨텍스트로 마킹.
그래서 본 모듈은 다음 두 경우만 hook 함:

- `CompactUnitFrame_UpdateCenterStatusIcon` (range fade 갱신, secret-safe API 만 사용)

나머지는 이벤트 기반 (`GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD`,
`PLAYER_REGEN_ENABLED`, `UNIT_PET`) 으로 0.3s 지연 후 `RefreshAllFrames()` 호출.

### Idempotent SetAlpha

`region:GetAlpha()` 가 target 과 다를 때만 `SetAlpha` 호출 — 불필요한 호출 제거 +
같은 child region 에 매번 똑같은 mutate 누적 방지.

### Secret-safe Range Fade

`UnitInRange(unit)` 는 secret boolean 반환 가능. `if inRange then` 같은 조건문은
secret 비교 에러. 대신 `SetAlphaFromBoolean(secretBoolean, alphaIn, alphaOut)` 으로
UI API 에 직접 전달 (12.0 공식 secret-safe 패턴).

## 슬래시 명령

- `/ocrf debug` — Storage 상태 로그
- `/ocrf enable` — 모듈 활성화
- `/ocrf refresh` — 모든 프레임 재적용
