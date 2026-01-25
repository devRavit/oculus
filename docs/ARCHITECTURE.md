# Architecture & Design Patterns

> WoW 애드온 아키텍처 및 설계 패턴

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

---

## 객체지향 설계

모듈은 객체처럼 설계하여 상태와 행위를 캡슐화한다.

### 모듈 객체 패턴

```lua
-- 모듈을 클래스처럼 사용
local Auras = {}
Auras.__index = Auras

-- 상태
Auras.isEnabled = false
Auras.frames = {}

-- 생성자 (선택적)
function Auras:New()
    local instance = setmetatable({}, self)
    instance.frames = {}
    return instance
end

-- Public 메서드
function Auras:Enable()
    self.isEnabled = true
    self:HookFrames()
end

function Auras:Disable()
    self.isEnabled = false
end

-- Private 메서드 (언더스코어 접두사)
function Auras:_UpdateSingleFrame(frame)
    -- 내부 로직
end

-- Getter/Setter
function Auras:GetSettings()
    return self.settings
end

function Auras:SetSetting(key, value)
    self.settings[key] = value
    self:_NotifyObservers(key, value)
end
```

---

## 설정 병합 패턴 (Storage + Default)

SavedVariables(Storage)와 기본값(Default)을 병합하여 설정 객체를 구성한다.

### 기본 문법

```lua
-- Lua 테이블 문법: 콜론(:)이 아닌 등호(=) 사용
local config = {
    key = value,
    nested = {
        innerKey = innerValue,
    },
}
```

### 구조 설계

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

### 깊은 병합 함수

```lua
-- 재귀적으로 Storage와 Defaults 병합
local function DeepMerge(defaults, storage)
    if type(defaults) ~= "table" then
        if storage ~= nil then
            return storage
        end
        return defaults
    end

    if type(storage) ~= "table" then
        storage = {}
    end

    local result = {}
    for key, defaultValue in pairs(defaults) do
        result[key] = DeepMerge(defaultValue, storage[key])
    end
    return result
end
```

### 빌드 함수

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

### boolean 값 처리

```lua
-- or 패턴은 false를 nil로 취급하므로 주의
local timerStorage = storage.Timer or {}

-- Bad: timerStorage.Show가 false면 DEFAULTS 사용됨
Show = timerStorage.Show or DEFAULTS.Timer.Show,

-- Good: nil 체크로 false 구분
Show = (timerStorage.Show == nil) and DEFAULTS.Timer.Show or timerStorage.Show,
```

### 사용 예시

```lua
-- 초기화 시 빌드
local function OnAddonLoaded()
    BuildConfig()
end

-- 다른 모듈에서 사용
local debuffSize = Config.Debuff.Size
local showTimer = Config.Timer.Show

-- 설정 변경 시 Storage 업데이트 + 리빌드
local function SetDebuffSize(size)
    OculusStorage = OculusStorage or {}
    OculusStorage.Debuff = OculusStorage.Debuff or {}
    OculusStorage.Debuff.Size = size
    BuildConfig()
end
```

---

## Config 모듈 패턴 (객체화)

메타테이블 자동 폴백 + getter/setter + 옵저버 패턴을 결합한 설정 모듈.

### 전체 구현

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
}


-- 지역 변수
local observers = {}
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

    for i = 1, #parts - 1 do
        local part = parts[i]
        if current[part] == nil then
            current[part] = {}
        end
        current = current[part]
    end

    current[parts[#parts]] = value
end


-- Public: 값 가져오기
function Config:Get(path)
    local storage = OculusStorage or {}
    local storageValue = GetByPath(storage, path)
    local defaultValue = GetByPath(DEFAULTS, path)

    if storageValue == nil then
        return defaultValue
    end
    return storageValue
end

-- Public: 값 설정하기
function Config:Set(path, value)
    OculusStorage = OculusStorage or {}
    local oldValue = self:Get(path)
    SetByPath(OculusStorage, path, value)
    configCache = nil
    self:_NotifyObservers(path, value, oldValue)
end

-- Public: 기본값으로 리셋
function Config:Reset(path)
    local defaultValue = GetByPath(DEFAULTS, path)
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
    local pathObservers = observers[path]
    if pathObservers then
        for _, callback in ipairs(pathObservers) do
            callback(newValue, oldValue, path)
        end
    end

    local wildcardObservers = observers["*"]
    if wildcardObservers then
        for _, callback in ipairs(wildcardObservers) do
            callback(newValue, oldValue, path)
        end
    end

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
            return Config:Get(group .. "." .. key)
        end,
        __newindex = function(_, key, value)
            Config:Set(group .. "." .. key, value)
        end,
    })
    return proxy
end

setmetatable(Config, {
    __index = function(self, key)
        if rawget(self, key) then
            return rawget(self, key)
        end
        if DEFAULTS[key] then
            return CreateProxy(key)
        end
        return nil
    end,
})


-- 모듈 등록
addon.Config = Config
```

### 사용 예시

```lua
local Config = addon.Config

-- 1. 메타테이블 자동 폴백 (간단한 접근)
local debuffSize = Config.Debuff.Size      -- 읽기: DB or Default
Config.Debuff.Size = 32                     -- 쓰기: DB 저장 + 옵저버 호출

-- 2. 명시적 getter/setter (경로 문자열)
local size = Config:Get("Buff.Size")
Config:Set("Buff.Size", 28)
Config:Reset("Buff.Size")
Config:ResetAll()

-- 3. 옵저버 패턴 (설정 변경 감지)
local unsubscribe = Config:Subscribe("Debuff.Size", function(newValue, oldValue, path)
    UpdateDebuffFrames()
end)

Config:Subscribe("Buff.*", function(newValue, oldValue, path)
    UpdateBuffFrames()
end)

unsubscribe()
```

### UI 연동 예시

```lua
-- 슬라이더 설정
local function CreateSizeSlider(parent)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetValue(Config.Debuff.Size)

    slider:SetScript("OnValueChanged", function(self, value)
        Config.Debuff.Size = value
    end)

    Config:Subscribe("Debuff.Size", function(newValue)
        slider:SetValue(newValue)
    end)

    return slider
end
```

### 새 설정 추가 시

```lua
-- 1. DEFAULTS에 추가
local DEFAULTS = {
    NewGroup = {
        NewSetting = "defaultValue",
    },
}

-- 2. 사용 (매핑 필요 없음, 중첩 경로 자동 처리)
local value = Config.NewGroup.NewSetting
Config.NewGroup.NewSetting = "newValue"
Config:Get("NewGroup.NewSetting")
Config:Set("NewGroup.NewSetting", "newValue")
```
