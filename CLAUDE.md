# Oculus Addon - Development Guidelines

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

### 설정 병합 패턴 (DB + Default)

SavedVariables(DB)와 기본값(Default)을 병합하여 설정 객체를 구성한다.

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
-- Defaults: 중첩 구조 (논리적 그룹화)
local Defaults = {
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

-- DB (SavedVariables): flat 구조 (저장 용이)
-- OculusDB = {
--     BuffSize = 32,
--     DebuffsPerRow = 6,
--     ShowTimer = false,
-- }

-- Config: 중첩 구조 (사용 편의)
-- Config.Buff.Size
-- Config.Timer.Show
```

#### 빌드 함수 (권장 패턴)

```lua
local Config = {}

local function BuildConfig()
    local DB = OculusDB or {}

    Config.Buff = {
        Size = DB.BuffSize or Defaults.Buff.Size,
        PerRow = DB.BuffsPerRow or Defaults.Buff.PerRow,
        Anchor = DB.BuffAnchor or Defaults.Buff.Anchor,
        UseCustomPosition = DB.UseCustomBuffPosition or Defaults.Buff.UseCustomPosition,
    }

    Config.Debuff = {
        Size = DB.DebuffSize or Defaults.Debuff.Size,
        PerRow = DB.DebuffsPerRow or Defaults.Debuff.PerRow,
        Anchor = DB.DebuffAnchor or Defaults.Debuff.Anchor,
        UseCustomPosition = DB.UseCustomDebuffPosition or Defaults.Debuff.UseCustomPosition,
    }

    -- boolean 값: nil 체크 필요 (false와 구분)
    Config.Timer = {
        Show = (DB.ShowTimer == nil) and Defaults.Timer.Show or DB.ShowTimer,
        ExpiringThreshold = DB.ExpiringThreshold or Defaults.Timer.ExpiringThreshold,
    }

    return Config
end
```

#### boolean 값 처리

```lua
-- or 패턴은 false를 nil로 취급하므로 주의

-- Bad: DB.ShowTimer가 false면 Defaults 사용됨
Show = DB.ShowTimer or Defaults.Timer.Show,

-- Good: nil 체크로 false 구분
Show = (DB.ShowTimer == nil) and Defaults.Timer.Show or DB.ShowTimer,

-- 또는 삼항 패턴
Show = DB.ShowTimer ~= nil and DB.ShowTimer or Defaults.Timer.Show,
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

-- 설정 변경 시 DB 업데이트 + 리빌드
local function SetDebuffSize(size)
    OculusDB = OculusDB or {}
    OculusDB.DebuffSize = size
    BuildConfig()  -- Config 갱신
end
```

#### DB 키 네이밍 규칙

```lua
-- Flat 구조: 그룹명 + 속성명
OculusDB = {
    -- Buff 그룹
    BuffSize = 24,
    BuffsPerRow = 8,
    BuffAnchor = "TOPRIGHT",
    UseCustomBuffPosition = false,

    -- Debuff 그룹
    DebuffSize = 24,
    DebuffsPerRow = 8,
    DebuffAnchor = "TOPRIGHT",
    UseCustomDebuffPosition = false,

    -- Timer 그룹
    ShowTimer = true,
    ExpiringThreshold = 5,
}
```

### Config 모듈 패턴 (객체화)

메타테이블 자동 폴백 + getter/setter + 옵저버 패턴을 결합한 설정 모듈.

#### 전체 구현

```lua
--[[
    Config.lua

    설정 관리 모듈
    - 메타테이블: 자동 DB/Default 폴백
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

-- DB 키 매핑: Config 경로 -> DB 키
local DB_KEY_MAP = {
    ["Buff.Size"] = "BuffSize",
    ["Buff.PerRow"] = "BuffsPerRow",
    ["Buff.Anchor"] = "BuffAnchor",
    ["Buff.UseCustomPosition"] = "UseCustomBuffPosition",
    ["Debuff.Size"] = "DebuffSize",
    ["Debuff.PerRow"] = "DebuffsPerRow",
    ["Debuff.Anchor"] = "DebuffAnchor",
    ["Debuff.UseCustomPosition"] = "UseCustomDebuffPosition",
    ["Timer.Show"] = "ShowTimer",
    ["Timer.ExpiringThreshold"] = "ExpiringThreshold",
}


-- 지역 변수
local observers = {}  -- { ["Buff.Size"] = { callback1, callback2 }, ... }
local configCache = nil


-- Config 클래스
local Config = {}
Config.__index = Config


-- Private: DB 참조 가져오기
local function GetDB()
    return OculusDB or {}
end

-- Private: 경로로 기본값 가져오기
local function GetDefault(path)
    local parts = { strsplit(".", path) }
    local value = DEFAULTS

    for _, part in ipairs(parts) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[part]
    end

    return value
end

-- Private: 값 비교 (boolean 처리)
local function GetValueWithDefault(dbValue, defaultValue)
    if dbValue == nil then
        return defaultValue
    end
    return dbValue
end


-- Public: 값 가져오기
function Config:Get(path)
    local dbKey = DB_KEY_MAP[path]
    if not dbKey then
        error("Unknown config path: " .. path)
    end

    local db = GetDB()
    local defaultValue = GetDefault(path)

    return GetValueWithDefault(db[dbKey], defaultValue)
end

-- Public: 값 설정하기
function Config:Set(path, value)
    local dbKey = DB_KEY_MAP[path]
    if not dbKey then
        error("Unknown config path: " .. path)
    end

    -- DB 초기화
    OculusDB = OculusDB or {}

    -- 이전 값 저장 (옵저버용)
    local oldValue = self:Get(path)

    -- DB 업데이트
    OculusDB[dbKey] = value

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
    OculusDB = {}
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

-- 2. DB_KEY_MAP에 매핑 추가
local DB_KEY_MAP = {
    -- ...기존 매핑
    ["NewGroup.NewSetting"] = "NewGroupNewSetting",
}

-- 3. 사용
local value = Config.NewGroup.NewSetting
Config.NewGroup.NewSetting = "newValue"
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
