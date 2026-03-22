# WoW 애드온 개발 패턴 규칙

WoW 특유의 API 제약과 보안 모델에서 비롯된 개발 패턴을 정리한다.

---

## 1. Secret Value 캐싱 패턴

### 배경

WoW는 전투 중 보호된 프레임(CompactUnitFrame 등)의 속성을 외부 애드온이 읽을 때
**secret number** 또는 **secret boolean** 형태로 tainted value를 반환한다.
이 값은 비교(`>`, `<=`, `==`)나 연산 시 Lua 에러를 발생시킨다.

```
attempt to compare local 'h' (a secret number value tainted by 'Oculus_RaidFrames')
```

### 핵심 원칙

> **전투 중 변하지 않는 레이아웃 값은, 안전한 시점에 미리 측정해 캐싱하고 그 값만 사용한다.**

보호된 프레임의 크기/위치 등 레이아웃 값은 아래 상황에서만 변한다:
- 편집 모드(Edit Mode) 진입/종료
- UI 스케일 변경
- 프레임 레이아웃 리셋

이 상황은 모두 **전투 밖**에서만 발생하므로, 전투 중 재측정이 불필요하다.

### 구현 패턴

```lua
-- 1. 측정 함수: GetHeight/GetWidth 등을 pcall로 감싸 비교까지 보호
local function cacheFrameHeight(frame)
    if not frame or not frame.healthBar then return end
    pcall(function()
        local val = frame.healthBar:GetHeight()
        if val > 0 then  -- 비교도 pcall 안에서 (secret number 대비)
            frame.OculusHealthBarHeight = val
            -- SavedVariables에도 기록 → 다음 세션 로드 시 즉시 사용 가능
            if OculusRaidFramesStorage then
                OculusRaidFramesStorage.CachedHealthBarHeight = val
            end
        end
    end)
end

-- 2. 전체 캐싱 함수: 전투 중 호출 방지
local function cacheAllFrameHeights()
    if InCombatLockdown() then return end  -- 전투 중 스킵
    CompactRaidFrameContainer:ApplyToFrames("normal", cacheFrameHeight)
    -- party frames ...
end

-- 3. 사용 함수: 캐시 참조만, GetHeight() 호출 없음
local function getActualAuraSize(frame, sizePercent)
    local h = (frame and frame.OculusHealthBarHeight)
           or (OculusRaidFramesStorage and OculusRaidFramesStorage.CachedHealthBarHeight)
           or 24  -- 최종 fallback
    if h <= 0 then h = 24 end
    return math.max(8, math.floor(h * (sizePercent / 100)))
end
```

### 캐싱 시점

| 시점 | 방법 |
|------|------|
| 애드온 활성화 | `Enable()` → `RefreshAllFrames()` → `cacheAllFrameHeights()` |
| 편집 모드 종료 | `EditModeManagerFrame:OnHide` 훅 → `RefreshAllFrames()` |
| 전투 종료 후 리프레시 | `PLAYER_REGEN_ENABLED` 이후 `RefreshAllFrames()` 호출 시 |
| 신규 프레임 등장 | `GROUP_ROSTER_UPDATE` 등 이벤트 기반 refresh |

### SavedVariables fallback

같은 계정/캐릭터에서 레이아웃이 바뀌지 않는 한 이전 세션의 측정값을 재사용할 수 있다.
로드 직후 프레임이 아직 배치되기 전에도 올바른 크기 계산이 가능해진다.

```
우선순위: frame.OculusHealthBarHeight → SavedVariables 캐시 → 기본값(24)
```

### 적용 대상

이 패턴은 아래 유형의 값에 적용한다:

- `frame:GetWidth()`, `frame:GetHeight()` — 프레임 크기
- `frame:GetFrameLevel()` — 필요 시
- 기타 전투 중 secret value를 반환하는 프레임 속성

---

## 2. pcall 보호 범위 규칙

secret value와 관련된 코드는 **GetHeight() 호출과 비교 연산을 모두 같은 pcall 블록 안에** 넣는다.
비교를 pcall 밖으로 꺼내면 동일한 taint 에러가 발생한다.

```lua
-- Bad: 비교가 pcall 밖
local ok, val = pcall(function() return frame.healthBar:GetHeight() end)
if ok and val > 0 then  -- val이 secret number면 여기서 에러
    ...
end

-- Good: 비교까지 pcall 안
pcall(function()
    local val = frame.healthBar:GetHeight()
    if val > 0 then  -- pcall이 taint 에러를 catch
        ...
    end
end)
```

---

## 3. InCombatLockdown 가드 규칙

보호된 프레임을 수정하거나 secret value를 읽는 코드 블록은
`InCombatLockdown()` 체크로 전투 중 실행을 막는다.

```lua
local function cacheAllFrameHeights()
    if InCombatLockdown() then return end
    -- 안전하게 실행
end
```

단, **읽기 전용 + pcall 보호**가 완벽하다면 전투 중 실행해도 에러는 발생하지 않는다.
캐싱이 실패해도 기존 캐시를 그대로 쓰면 되므로 기능 저하 없이 안전하다.
