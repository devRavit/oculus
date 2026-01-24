# Oculus Addon - Development Guidelines

> **Claude 지시사항**: 이 파일의 모든 규칙을 준수할 것.

---

## Checkpoint: 작업 전 필수 읽기

모듈 관련 작업 시 **반드시** 해당 명세서를 먼저 읽을 것.

| 작업 대상 | 명세서 경로 |
|-----------|-------------|
| 전체 구조/개요 | `docs/spec/Overview.md` |
| Core 모듈 | `docs/spec/Core.md` |
| UnitFrames 모듈 | `docs/spec/UnitFrames.md` |
| RaidFrames 모듈 | `docs/spec/RaidFrames.md` |
| ArenaFrames 모듈 | `docs/spec/ArenaFrames.md` |

### 작업 흐름

1. **작업 시작 전**: 관련 명세서 Read 도구로 읽기
2. **구현 중**: 명세서의 구조/API 설계 따르기
3. **구현 완료 후**: 명세서 업데이트 (구현된 내용 반영)

### 명세서 업데이트 규칙

- 새 기능 추가 시: 해당 섹션에 기능 설명 추가
- API 변경 시: 함수 시그니처, 파라미터 업데이트
- 설정 추가 시: DB 구조, 기본값 업데이트

---

## Localization (i18n)

**모든 UI에 표시되는 문자열은 반드시 현지화(Localization) 처리되어야 함**

- 하드코딩된 문자열 사용 금지
- `Oculus.L` 테이블을 통해 현지화된 문자열 사용
- 새로운 문자열 추가 시 `Oculus/Localization.lua`에 enUS, koKR 번역 모두 추가

### 사용 예시

```lua
-- Bad
Button:SetText("Preview Mode")

-- Good
Button:SetText(L["Preview Mode"])
```

### 현지화 파일 구조

- `Oculus/Localization.lua`: 메인 현지화 파일
- enUS (기본값) + koKR 지원

---

## Lua Coding Conventions

> Roblox Lua Style Guide 기반, WoW 애드온 개발에 맞게 조정

### 핵심 원칙

1. **일관성 우선** - 코드베이스 전체에 동일한 스타일 유지
2. **가독성 최적화** - 읽기 쉬운 코드가 좋은 코드
3. **마법 최소화** - 메타테이블 등 고급 기능은 신중하게 사용
4. **WoW 관례 존중** - Blizzard UI 소스 스타일 참고

### 네이밍 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| 모듈/클래스 | PascalCase | `UnitFrames`, `RaidFrames`, `Core` |
| 함수 | PascalCase | `CreateFrame`, `UpdateHealth`, `OnEvent` |
| 지역 변수 | camelCase | `healthBar`, `currentTarget`, `framePool` |
| 상수 | LOUD_SNAKE_CASE | `MAX_RAID_SIZE`, `DEFAULT_WIDTH` |
| 비공개 멤버 | 언더스코어 접두사 | `_internalState`, `_cachedValue` |
| 이벤트 핸들러 | On + PascalCase | `OnLoad`, `OnEvent`, `OnUpdate` |

#### 약어 규칙

```lua
-- Good: 약어도 camelCase 규칙 적용
local jsonData = {}
local htmlContent = ""

-- Bad: 전체 대문자 약어
local JSONData = {}
local HTMLContent = ""
```

### 인덴트 및 공백

```lua
-- 4 spaces 사용 (탭 대신)
local function Example()
    if condition then
        DoSomething()
    end
end
```

- **코드**: 최대 100 칼럼
- **주석**: 최대 80 칼럼
- **인코딩**: UTF-8

#### 공백 규칙

```lua
-- Good: 연산자 전후 공백
local result = a + b * c

-- Good: 쉼표 뒤 공백
local frame = CreateFrame("Frame", nil, parent, template)

-- Good: 테이블 중괄호 내부 공백 (한 줄일 때)
local point = { x = 0, y = 0 }
```

#### 금지 사항

```lua
-- Bad: 세미콜론 사용
local x = 1;

-- Bad: 수직 정렬
local shortName    = "foo"
local veryLongName = "bar"

-- Good: 정렬 없이
local shortName = "foo"
local veryLongName = "bar"
```

#### 빈 줄 규칙

```lua
-- 함수 사이: 1줄
local function Foo()
end

local function Bar()
end

-- 섹션 사이: 2줄 (전역 로컬화 → 상수 → 변수 → 함수 등)
local CreateFrame = CreateFrame
local UnitHealth = UnitHealth


local MAX_FRAMES = 40
local DEFAULT_WIDTH = 200


local framePool = {}

-- 논리적 그룹 내: 빈 줄 없음
local width = 200
local height = 50
local padding = 10

-- 관련 없는 변수 그룹 사이: 1줄
local width = 200
local height = 50

local name = "Player"
local class = "WARRIOR"
```

### 함수

#### 함수 정의

```lua
-- 지역 함수
local function CalculateHealth(unit)
    return UnitHealth(unit)
end

-- 모듈 함수
function UnitFrames:Initialize()
    self:CreateFrames()
end

-- 정적 함수
function UnitFrames.GetDefaultConfig()
    return DEFAULT_CONFIG
end
```

#### 함수 호출

```lua
-- Good: 항상 괄호 사용
local name = GetUnitName(unit)
print("Hello")

-- Bad: 괄호 생략
print "Hello"
```

#### 긴 파라미터 줄바꿈

```lua
-- 100 칼럼 초과 시: 각 파라미터 개별 줄 + 후행 쉼표
local frame = CreateFrame(
    "Frame",
    "OculusMainFrame",
    UIParent,
    "BackdropTemplate",
)

-- 함수 정의도 동일
local function CreateHealthBar(
    parent,
    width,
    height,
    showText,
    textFormat,
)
    -- ...
end

-- 메서드 체이닝: 각 호출 개별 줄
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetSize(200, 50)
frame:Show()

-- 테이블 파라미터: 인라인 또는 별도 변수
-- Good: 인라인
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

-- Good: 복잡하면 별도 변수
local anchorPoint = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 0,
    offsetY = 0,
}
frame:SetPoint(
    anchorPoint.point,
    anchorPoint.relativeTo,
    anchorPoint.relativePoint,
    anchorPoint.offsetX,
    anchorPoint.offsetY,
)
```

#### Early Return

```lua
-- Good: 조기 반환으로 중첩 감소
local function UpdateUnit(unit)
    if not unit then return end
    if not UnitExists(unit) then return end

    local health = UnitHealth(unit)
    -- ...
end

-- Bad: 깊은 중첩
local function UpdateUnit(unit)
    if unit then
        if UnitExists(unit) then
            local health = UnitHealth(unit)
            -- ...
        end
    end
end
```

### 문자열

```lua
-- Good: 큰따옴표 사용
local message = "Hello, World!"

-- 예외: 문자열 내 큰따옴표가 많을 때
local html = '<div class="container">Content</div>'
```

#### 문자열 연결

```lua
-- 짧은 연결: 공백 없이
local fullName = firstName .. lastName

-- 공백 포함 연결: 명시적 공백
local fullName = firstName .. " " .. lastName

-- 긴 연결: string.format 사용 (권장)
local message = string.format("%s has %d health", name, health)

-- 여러 줄 연결: .. 연산자는 줄 끝에
local longMessage = "This is a very long message "
    .. "that spans multiple lines "
    .. "for better readability."

-- 테이블 concat: 많은 문자열 연결 시
local parts = { "Hello", " ", "World" }
local result = table.concat(parts)
```

### 테이블

```lua
-- 한 줄: 짧은 테이블
local point = { x = 0, y = 0 }

-- 여러 줄: 3개 이상 (후행 쉼표 필수)
local config = {
    width = 200,
    height = 50,
    showName = true,
}

-- 순회: 리스트는 ipairs, 딕셔너리는 pairs
for i, unit in ipairs(units) do end
for key, value in pairs(config) do end
```

#### 테이블 내 함수 정의

```lua
-- 이벤트 핸들러 테이블: 익명 함수 사용
local eventHandlers = {
    PLAYER_LOGIN = function()
        Initialize()
    end,
    UNIT_HEALTH = function(unit)
        UpdateHealth(unit)
    end,
}

-- 짧은 함수: 한 줄 허용
local callbacks = {
    OnClick = function(self) self:Toggle() end,
    OnEnter = function(self) self:Highlight() end,
}

-- 긴 함수: 여러 줄
local callbacks = {
    OnClick = function(self, button)
        if button == "LeftButton" then
            self:Toggle()
        elseif button == "RightButton" then
            self:ShowMenu()
        end
    end,
}

-- Mixin 테이블: 별도 함수 정의 (권장)
local MyMixin = {}

function MyMixin:OnLoad()
    -- ...
end

function MyMixin:OnClick()
    -- ...
end
```

### 조건문

```lua
-- 본문은 항상 새 줄에
if condition then
    DoSomething()
end

-- Bad: 한 줄 if
if condition then DoSomething() end

-- 복합 조건: 의미 있는 변수로 추출
local targetExists = UnitExists(target)
local targetAlive = not UnitIsDead(target)

if targetExists and targetAlive then
    StartAttack()
end
```

#### 긴 조건문 줄바꿈

```lua
-- 연산자는 새 줄 시작에 배치 (들여쓰기 2단계)
local canAttack = UnitExists(target)
        and not UnitIsDead(target)
        and UnitCanAttack("player", target)
        and not UnitIsFriend("player", target)

-- if문에서도 동일
if UnitExists(target)
        and not UnitIsDead(target)
        and UnitCanAttack("player", target) then
    StartAttack()
end

-- 복잡하면 변수로 추출 (권장)
local targetExists = UnitExists(target)
local targetAlive = not UnitIsDead(target)
local isHostile = UnitCanAttack("player", target)

if targetExists and targetAlive and isHostile then
    StartAttack()
end
```

#### 삼항 연산자 대체

```lua
-- Lua에는 삼항 연산자 없음, and/or 패턴 사용
local value = condition and trueValue or falseValue

-- 긴 경우: 여러 줄
local displayName = isPlayer
        and UnitName("player")
        or "Unknown"

-- 복잡하면 if문 사용 (권장)
local displayName
if isPlayer then
    displayName = UnitName("player")
else
    displayName = "Unknown"
end
```

### 주석

```lua
-- WHY를 설명, WHAT은 코드가 말함

-- Good: 이유 설명
-- WoW API가 nil을 반환할 수 있어서 기본값 설정
local name = UnitName(unit) or "Unknown"

-- Bad: 코드 설명
-- name 변수에 유닛 이름 할당
local name = UnitName(unit)

-- TODO 주석
-- TODO: 12.0 API 변경 후 업데이트 필요
-- FIXME: 간헐적으로 nil 반환하는 버그
```

#### 블록 주석 vs 한 줄 주석

```lua
-- 블록 주석 --[[ ]]: 파일/모듈 설명에만 사용
--[[
    UnitFrames.lua

    플레이어, 타겟, 포커스 유닛 프레임을 관리한다.
    Blizzard 기본 UI를 대체하며 커스터마이징 가능.
]]

-- 한 줄 주석 --: 그 외 모든 경우
-- 이벤트 핸들러 등록
eventFrame:RegisterEvent("UNIT_HEALTH")

-- 여러 줄 설명도 한 줄 주석 반복 사용
-- 이 함수는 유닛의 체력 비율을 계산한다.
-- max가 0인 경우 0을 반환하여 division by zero 방지.
local function CalculateHealthPercent(current, max)
    if max == 0 then return 0 end
    return current / max
end

-- Bad: 코드 내 블록 주석
local value = 1 --[[ 임시 값 ]]
```

#### 주석 위치

```lua
-- Good: 코드 위에 주석
-- 체력바 업데이트
UpdateHealthBar(unit)

-- Bad: 코드 옆 인라인 주석 (짧은 설명 제외)
UpdateHealthBar(unit) -- 체력바 업데이트

-- 예외: 짧은 인라인 주석은 허용
local MAX_FRAMES = 40  -- 레이드 최대 인원
```

### 파일 구조

```lua
--[[
    모듈명.lua
    모듈 설명
]]

-- 1. 전역 참조 로컬화 (성능 최적화)
local CreateFrame = CreateFrame
local UnitHealth = UnitHealth

-- 2. 상수
local MAX_FRAMES = 40
local DEFAULT_WIDTH = 200

-- 3. 지역 변수
local framePool = {}

-- 4. 지역 함수 (헬퍼)
local function CalculatePercentage(current, max)
    if max == 0 then return 0 end
    return current / max
end

-- 5. 모듈 테이블
local UnitFrames = {}

-- 6. 모듈 함수
function UnitFrames:Initialize()
    -- ...
end

-- 7. 반환
return UnitFrames
```

---

## WoW 특화 규칙

### 전역 API 로컬화

```lua
-- 자주 사용하는 API 로컬화 (성능 향상)
local CreateFrame = CreateFrame
local UnitHealth = UnitHealth
local UnitName = UnitName
local GetTime = GetTime
```

### 이벤트 핸들러

```lua
-- 이벤트별 함수 테이블 (권장)
local eventHandlers = {
    PLAYER_LOGIN = function()
        -- ...
    end,
    UNIT_HEALTH = function(unit)
        -- ...
    end,
}

local function OnEvent(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(...)
    end
end

eventFrame:SetScript("OnEvent", OnEvent)
```

### Mixin 패턴

```lua
local HealthBarMixin = {}

function HealthBarMixin:OnLoad()
    self:RegisterForClicks("AnyUp")
end

function HealthBarMixin:SetUnit(unit)
    self.unit = unit
    self:Update()
end

-- 프레임에 Mixin 적용
local frame = CreateFrame("StatusBar", nil, parent)
Mixin(frame, HealthBarMixin)
frame:OnLoad()
```

### 에러 처리

```lua
-- 방어적 코딩: nil 체크
local function GetUnitInfo(unit)
    if not unit then return nil end
    if not UnitExists(unit) then return nil end

    return {
        name = UnitName(unit),
        health = UnitHealth(unit),
    }
end
```

### 설정 병합 패턴 (Storage + Default)

SavedVariables(Storage)와 기본값(Default)을 병합하여 설정 객체를 구성한다.

#### 기본 문법

```lua
-- Lua 테이블 문법: 콜론(:)이 아닌 등호(=) 사용
local config = {
    key = value,
    nested = {
        innerKey = innerValue,
    },
}
```

#### 구조 설계

```lua
-- 모든 구조를 중첩 형태로 통일

-- Defaults: 중첩 구조
local DEFAULTS = {
    Buff = {
        Size = 24,
        PerRow = 8,
        Anchor = "TOPRIGHT",
        UseCustomPosition = false,
    },
    Debuff = {
        Size = 24,
        PerRow = 8,
        Anchor = "TOPRIGHT",
        UseCustomPosition = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 5,
    },
}

-- Storage (SavedVariables): 중첩 구조
-- OculusStorage = {
--     Buff = {
--         Size = 32,
--     },
--     Timer = {
--         Show = false,
--     },
-- }

-- Config: 중첩 구조 (Storage + Defaults 병합 결과)
-- Config.Buff.Size
-- Config.Timer.Show
```

#### 깊은 병합 함수

```lua
-- 재귀적으로 Storage와 Defaults 병합
local function DeepMerge(defaults, storage)
    if type(defaults) ~= "table" then
        -- 기본값이 테이블이 아니면 storage 값 또는 defaults 반환
        if storage ~= nil then
            return storage
        end
        return defaults
    end

    if type(storage) ~= "table" then
        -- storage가 없으면 defaults 복사
        storage = {}
    end

    local result = {}
    for key, defaultValue in pairs(defaults) do
        result[key] = DeepMerge(defaultValue, storage[key])
    end
    return result
end
```

#### 빌드 함수

```lua
local Config = {}

local function BuildConfig()
    local storage = OculusStorage or {}

    Config.Buff = {
        Size = storage.Buff and storage.Buff.Size or DEFAULTS.Buff.Size,
        PerRow = storage.Buff and storage.Buff.PerRow or DEFAULTS.Buff.PerRow,
        Anchor = storage.Buff and storage.Buff.Anchor or DEFAULTS.Buff.Anchor,
        UseCustomPosition = storage.Buff and storage.Buff.UseCustomPosition
            or DEFAULTS.Buff.UseCustomPosition,
    }

    Config.Debuff = {
        Size = storage.Debuff and storage.Debuff.Size or DEFAULTS.Debuff.Size,
        PerRow = storage.Debuff and storage.Debuff.PerRow or DEFAULTS.Debuff.PerRow,
        Anchor = storage.Debuff and storage.Debuff.Anchor or DEFAULTS.Debuff.Anchor,
        UseCustomPosition = storage.Debuff and storage.Debuff.UseCustomPosition
            or DEFAULTS.Debuff.UseCustomPosition,
    }

    -- boolean 값: nil 체크 필요
    local timerStorage = storage.Timer or {}
    Config.Timer = {
        Show = (timerStorage.Show == nil) and DEFAULTS.Timer.Show or timerStorage.Show,
        ExpiringThreshold = timerStorage.ExpiringThreshold or DEFAULTS.Timer.ExpiringThreshold,
    }

    return Config
end

-- 또는 DeepMerge 사용 (간결)
local function BuildConfig()
    Config = DeepMerge(DEFAULTS, OculusStorage or {})
    return Config
end
```

#### boolean 값 처리

```lua
-- or 패턴은 false를 nil로 취급하므로 주의
local timerStorage = storage.Timer or {}

-- Bad: timerStorage.Show가 false면 DEFAULTS 사용됨
Show = timerStorage.Show or DEFAULTS.Timer.Show,

-- Good: nil 체크로 false 구분
Show = (timerStorage.Show == nil) and DEFAULTS.Timer.Show or timerStorage.Show,
```

#### 사용 예시

```lua
-- 초기화 시 빌드
local function OnAddonLoaded()
    BuildConfig()
end

-- 다른 모듈에서 사용
local debuffSize = Config.Debuff.Size
local showTimer = Config.Timer.Show
local buffsPerRow = Config.Buff.PerRow

-- 설정 변경 시 Storage 업데이트 + 리빌드
local function SetDebuffSize(size)
    OculusStorage = OculusStorage or {}
    OculusStorage.Debuff = OculusStorage.Debuff or {}
    OculusStorage.Debuff.Size = size
    BuildConfig()
end
```

#### Storage 구조

```lua
-- 중첩 구조: 그룹 > 속성
OculusStorage = {
    Buff = {
        Size = 24,
        PerRow = 8,
        Anchor = "TOPRIGHT",
        UseCustomPosition = false,
    },
    Debuff = {
        Size = 24,
        PerRow = 8,
        Anchor = "TOPRIGHT",
        UseCustomPosition = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 5,
    },
}
```

### Config 모듈 패턴 (객체화)

메타테이블 자동 폴백 + getter/setter + 옵저버 패턴을 결합한 설정 모듈.

#### 전체 구현

```lua
--[[
    Config.lua

    설정 관리 모듈
    - 메타테이블: 자동 Storage/Default 폴백
    - getter/setter: 명시적 접근
    - 옵저버: 설정 변경 시 콜백 호출
]]

local addonName, addon = ...


-- 상수: 기본값 정의
local DEFAULTS = {
    Buff = {
        Size = 24,
        PerRow = 8,
        Anchor = "TOPRIGHT",
        UseCustomPosition = false,
    },
    Debuff = {
        Size = 24,
        PerRow = 8,
        Anchor = "TOPRIGHT",
        UseCustomPosition = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 5,
    },
}



-- 지역 변수
local observers = {}  -- { ["Buff.Size"] = { callback1, callback2 }, ... }
local configCache = nil


-- Config 클래스
local Config = {}
Config.__index = Config


-- Private: 경로로 값 가져오기 (중첩 구조)
local function GetByPath(tbl, path)
    if not tbl then return nil end

    local parts = { strsplit(".", path) }
    local value = tbl

    for _, part in ipairs(parts) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[part]
    end

    return value
end

-- Private: 경로로 값 설정하기 (중첩 구조)
local function SetByPath(tbl, path, value)
    local parts = { strsplit(".", path) }
    local current = tbl

    -- 마지막 키 전까지 경로 생성
    for i = 1, #parts - 1 do
        local part = parts[i]
        if current[part] == nil then
            current[part] = {}
        end
        current = current[part]
    end

    -- 마지막 키에 값 설정
    current[parts[#parts]] = value
end

-- Private: 값 비교 (boolean 처리)
local function GetValueWithDefault(storageValue, defaultValue)
    if storageValue == nil then
        return defaultValue
    end
    return storageValue
end


-- Public: 값 가져오기
function Config:Get(path)
    local storage = OculusStorage or {}
    local storageValue = GetByPath(storage, path)
    local defaultValue = GetByPath(DEFAULTS, path)

    return GetValueWithDefault(storageValue, defaultValue)
end

-- Public: 값 설정하기
function Config:Set(path, value)
    -- Storage 초기화
    OculusStorage = OculusStorage or {}

    -- 이전 값 저장 (옵저버용)
    local oldValue = self:Get(path)

    -- Storage 업데이트 (중첩 경로 자동 생성)
    SetByPath(OculusStorage, path, value)

    -- 캐시 무효화
    configCache = nil

    -- 옵저버 호출
    self:_NotifyObservers(path, value, oldValue)
end

-- Public: 기본값으로 리셋
function Config:Reset(path)
    local defaultValue = GetDefault(path)
    self:Set(path, defaultValue)
end

-- Public: 전체 리셋
function Config:ResetAll()
    OculusStorage = {}
    configCache = nil
    self:_NotifyObservers("*", nil, nil)
end


-- Observer: 콜백 등록
function Config:Subscribe(path, callback)
    observers[path] = observers[path] or {}
    table.insert(observers[path], callback)

    -- 구독 해제 함수 반환
    return function()
        self:Unsubscribe(path, callback)
    end
end

-- Observer: 콜백 해제
function Config:Unsubscribe(path, callback)
    local pathObservers = observers[path]
    if not pathObservers then return end

    for i, cb in ipairs(pathObservers) do
        if cb == callback then
            table.remove(pathObservers, i)
            return
        end
    end
end

-- Observer: 콜백 호출 (private)
function Config:_NotifyObservers(path, newValue, oldValue)
    -- 특정 경로 옵저버
    local pathObservers = observers[path]
    if pathObservers then
        for _, callback in ipairs(pathObservers) do
            callback(newValue, oldValue, path)
        end
    end

    -- 와일드카드 옵저버 ("*")
    local wildcardObservers = observers["*"]
    if wildcardObservers then
        for _, callback in ipairs(wildcardObservers) do
            callback(newValue, oldValue, path)
        end
    end

    -- 그룹 옵저버 ("Buff.*")
    local group = path:match("^(%w+)%.")
    if group then
        local groupObservers = observers[group .. ".*"]
        if groupObservers then
            for _, callback in ipairs(groupObservers) do
                callback(newValue, oldValue, path)
            end
        end
    end
end


-- 메타테이블: 자동 폴백 프록시 생성
local function CreateProxy(group)
    local proxy = {}

    setmetatable(proxy, {
        __index = function(_, key)
            local path = group .. "." .. key
            return Config:Get(path)
        end,
        __newindex = function(_, key, value)
            local path = group .. "." .. key
            Config:Set(path, value)
        end,
    })

    return proxy
end

-- 메타테이블: Config 최상위 프록시
setmetatable(Config, {
    __index = function(self, key)
        -- 메서드는 그대로 반환
        if rawget(self, key) then
            return rawget(self, key)
        end

        -- 그룹이면 프록시 반환
        if DEFAULTS[key] then
            return CreateProxy(key)
        end

        return nil
    end,
})


-- 모듈 등록
addon.Config = Config
```

#### 사용 예시

```lua
local Config = addon.Config

-- 1. 메타테이블 자동 폴백 (간단한 접근)
local debuffSize = Config.Debuff.Size      -- 읽기: DB or Default
Config.Debuff.Size = 32                     -- 쓰기: DB 저장 + 옵저버 호출

local showTimer = Config.Timer.Show         -- boolean도 정상 처리
Config.Timer.Show = false

-- 2. 명시적 getter/setter (경로 문자열)
local size = Config:Get("Buff.Size")
Config:Set("Buff.Size", 28)
Config:Reset("Buff.Size")                   -- 기본값으로 리셋
Config:ResetAll()                           -- 전체 리셋

-- 3. 옵저버 패턴 (설정 변경 감지)
-- 특정 설정 구독
local unsubscribe = Config:Subscribe("Debuff.Size", function(newValue, oldValue, path)
    print(path .. " changed: " .. oldValue .. " -> " .. newValue)
    UpdateDebuffFrames()  -- UI 업데이트
end)

-- 그룹 전체 구독
Config:Subscribe("Buff.*", function(newValue, oldValue, path)
    print("Buff setting changed: " .. path)
    UpdateBuffFrames()
end)

-- 모든 변경 구독
Config:Subscribe("*", function(newValue, oldValue, path)
    print("Any config changed: " .. path)
end)

-- 구독 해제
unsubscribe()
-- 또는
Config:Unsubscribe("Debuff.Size", callbackFunction)
```

#### UI 연동 예시

```lua
-- 슬라이더 설정
local function CreateSizeSlider(parent)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")

    -- 초기값 설정
    slider:SetValue(Config.Debuff.Size)

    -- 사용자 입력 시 Config 업데이트
    slider:SetScript("OnValueChanged", function(self, value)
        Config.Debuff.Size = value
    end)

    -- Config 변경 시 슬라이더 업데이트 (다른 곳에서 변경될 수 있음)
    Config:Subscribe("Debuff.Size", function(newValue)
        slider:SetValue(newValue)
    end)

    return slider
end

-- 체크박스 설정
local function CreateTimerCheckbox(parent)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")

    checkbox:SetChecked(Config.Timer.Show)

    checkbox:SetScript("OnClick", function(self)
        Config.Timer.Show = self:GetChecked()
    end)

    Config:Subscribe("Timer.Show", function(newValue)
        checkbox:SetChecked(newValue)
    end)

    return checkbox
end
```

#### 새 설정 추가 시

```lua
-- 1. DEFAULTS에 추가
local DEFAULTS = {
    -- ...기존 설정
    NewGroup = {
        NewSetting = "defaultValue",
    },
}

-- 2. 사용 (매핑 필요 없음, 중첩 경로 자동 처리)
local value = Config.NewGroup.NewSetting
Config.NewGroup.NewSetting = "newValue"

-- getter/setter로도 사용 가능
Config:Get("NewGroup.NewSetting")
Config:Set("NewGroup.NewSetting", "newValue")
```

---

## 리팩토링 체크리스트

### 네이밍
- [ ] 모듈/클래스: PascalCase
- [ ] 함수: PascalCase
- [ ] 지역 변수: camelCase
- [ ] 상수: LOUD_SNAKE_CASE
- [ ] 비공개: _underscore 접두사
- [ ] 약어: camelCase 규칙 적용 (jsonData, htmlContent)

### 포맷팅
- [ ] 4 spaces 인덴트
- [ ] 100 칼럼 제한
- [ ] 후행 쉼표 사용
- [ ] 세미콜론 제거
- [ ] 연산자 전후 공백
- [ ] 수직 정렬 제거

### 빈 줄
- [ ] 함수 사이: 1줄
- [ ] 섹션 사이: 2줄
- [ ] 논리적 그룹 내: 빈 줄 없음

### 줄바꿈
- [ ] 긴 파라미터: 각 파라미터 개별 줄
- [ ] 긴 조건문: 연산자는 새 줄 시작에
- [ ] 긴 문자열 연결: .. 연산자는 줄 끝에

### 주석
- [ ] 블록 주석: 파일/모듈 설명에만
- [ ] 한 줄 주석: 그 외 모든 경우
- [ ] WHY 설명, WHAT은 코드가 말함

### 구조
- [ ] 전역 API 로컬화
- [ ] 상수 분리
- [ ] Early return 적용
- [ ] 이벤트 핸들러 테이블화
- [ ] 파일 구조 순서 준수

---

## 참고 자료

- [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/)
- [WoW API Documentation](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [Blizzard UI Source](https://github.com/Gethe/wow-ui-source)
