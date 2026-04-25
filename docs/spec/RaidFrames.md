# Oculus_RaidFrames

## 역할

파티/레이드 CompactUnitFrame 의 가시성 토글, 파티 프레임 스케일, 사거리 투명도 처리,
**자체 buff/debuff overlay 패널** (AuraUtil 빌트인 필터 활용, taint-free).

> **12.0.5 PrivateAura 도입 이후**: Blizzard 의 buff/debuff 버튼은 forbidden scope 로 이동했고
> `SetMaxBuffs` / `SetAuraSize` 호출 시 frame taint / ADDON_ACTION_BLOCKED 발생. 따라서 본 모듈은
> Blizzard 의 기본 표시는 CVar / optionTable 로 숨기고, **자체 frame 으로 같은 자리에 overlay**
> 를 그림. 데이터는 `AuraUtil.ForEachAura` + `AuraUtil.AuraFilters` (CrowdControl/RaidInCombat
> /Important/BigDefensive 등 Blizzard 빌트인) 으로 안전하게 수집.

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

### 4. 자체 Aura Panel (buff/debuff overlay)
- Blizzard 의 PrivateAura 시스템과 별개로 우리 frame 을 각 raid frame 멤버 위에 overlay
- 데이터: `AuraUtil.ForEachAura(unit, filter, max, cb)` (12.0.5 공식)
- 필터: `AuraUtil.AuraFilters` (CrowdControl, RaidInCombat, Important, BigDefensive,
  ExternalDefensive 등 Blizzard 빌트인) → spell ID 리스트 유지 불필요
- CC 디버프는 별도 사이즈 (강조)
- Blizzard 기본 표시 숨김: `SetCVar("raidFramesDisplayDebuffs", "0")` + `frame.optionTable.displayBuffs = false`
- 모든 필터는 사용자 ON/OFF 가능

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
        RangeFade = { Enabled = true, MinAlpha = 0.55 },
    },
    AuraPanel = {
        Enabled = true,
        HideBlizzardDebuffs = true,
        HideBlizzardBuffs = true,
        Debuff = {
            ShowAll = true,
            FilterRaid = true,
            FilterRaidInCombat = true,
            FilterCrowdControl = true,
            FilterImportant = true,
            FilterDispellable = false,
            MaxCount = 5, NormalSize = 22, CCSize = 32, Spacing = 2,
            Anchor = "BOTTOMRIGHT", Growth = "LEFT",
            ShowCooldown = true, ShowStack = true,
        },
        Buff = {
            ShowAll = false, OnlyMine = true,
            FilterRaid = false, FilterRaidInCombat = true,
            FilterCancelable = false, FilterImportant = true,
            FilterBigDefensive = true, FilterExternalDefensive = true,
            MaxCount = 3, Size = 18, Spacing = 2,
            Anchor = "BOTTOMLEFT", Growth = "RIGHT",
            ShowCooldown = true, ShowStack = true,
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
├── RaidFrames.lua          -- 모듈 초기화, 스토리지, 서브모듈 enable/disable
├── Auras.lua               -- 가시성/스케일/사거리 페이드
├── AuraPanel.lua           -- 자체 buff/debuff overlay 패널 (AuraUtil 기반)
├── Config.lua              -- 설정 패널 생성, 컨트롤 위젯 헬퍼
├── ConfigFrameTab.lua      -- Frame Settings UI
└── ConfigAuraPanelTab.lua  -- AuraPanel Settings UI (필터 ON/OFF, 사이즈 등)
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
