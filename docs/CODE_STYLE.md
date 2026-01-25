# Lua Code Style Guide

> Roblox Lua Style Guide 기반, WoW 애드온 개발에 맞게 조정

---

## 핵심 원칙

1. **일관성 우선** - 코드베이스 전체에 동일한 스타일 유지
2. **가독성 최적화** - 읽기 쉬운 코드가 좋은 코드
3. **마법 최소화** - 메타테이블 등 고급 기능은 신중하게 사용
4. **WoW 관례 존중** - Blizzard UI 소스 스타일 참고
5. **약어 사용 최소화** - 가능한 풀네임 사용 (가독성 우선)
6. **파일 분리** - 한 파일에 너무 많은 코드 금지, 기능/섹션별 분리
7. **객체지향 설계** - 모듈은 객체처럼 설계, 상태와 행위 캡슐화

---

## 네이밍 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| 모듈/클래스 | PascalCase | `UnitFrames`, `RaidFrames`, `Core` |
| 함수 | PascalCase | `CreateFrame`, `UpdateHealth`, `OnEvent` |
| 지역 변수 | camelCase | `healthBar`, `currentTarget`, `framePool` |
| 상수 | LOUD_SNAKE_CASE | `MAX_RAID_SIZE`, `DEFAULT_WIDTH` |
| 비공개 멤버 | 언더스코어 접두사 | `_internalState`, `_cachedValue` |
| 이벤트 핸들러 | On + PascalCase | `OnLoad`, `OnEvent`, `OnUpdate` |

### 약어 금지

변수명, 함수명에 약어 사용을 최소화하고 **풀네임을 사용**한다.

```lua
-- Good: 풀네임 사용
local configuration = {}
local currentTarget = nil
local isInitializing = false
local expirationTime = 0

-- Bad: 약어 사용
local cfg = {}
local curTarget = nil
local isInit = false
local expTime = 0

-- 예외: 널리 알려진 약어는 허용
local db = {}  -- database
local id = 0   -- identifier
```

### 약어 대소문자

```lua
-- Good: 약어도 camelCase 규칙 적용
local jsonData = {}
local htmlContent = ""

-- Bad: 전체 대문자 약어
local JSONData = {}
local HTMLContent = ""
```

---

## 인덴트 및 공백

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

### 공백 규칙

```lua
-- Good: 연산자 전후 공백
local result = a + b * c

-- Good: 쉼표 뒤 공백
local frame = CreateFrame("Frame", nil, parent, template)

-- Good: 테이블 중괄호 내부 공백 (한 줄일 때)
local point = { x = 0, y = 0 }
```

### 금지 사항

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

### 빈 줄 규칙

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

---

## 함수

### 함수 정의

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

### 함수 호출

```lua
-- Good: 항상 괄호 사용
local name = GetUnitName(unit)
print("Hello")

-- Bad: 괄호 생략
print "Hello"
```

### 긴 파라미터 줄바꿈

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

### Early Return

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

---

## 문자열

```lua
-- Good: 큰따옴표 사용
local message = "Hello, World!"

-- 예외: 문자열 내 큰따옴표가 많을 때
local html = '<div class="container">Content</div>'
```

### 문자열 연결

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

---

## 테이블

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

### 테이블 내 함수 정의

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

---

## 조건문

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

### 긴 조건문 줄바꿈

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

### 삼항 연산자 대체

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

---

## 주석

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

### 블록 주석 vs 한 줄 주석

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

### 주석 위치

```lua
-- Good: 코드 위에 주석
-- 체력바 업데이트
UpdateHealthBar(unit)

-- Bad: 코드 옆 인라인 주석 (짧은 설명 제외)
UpdateHealthBar(unit) -- 체력바 업데이트

-- 예외: 짧은 인라인 주석은 허용
local MAX_FRAMES = 40  -- 레이드 최대 인원
```

---

## 파일 구조

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

### 파일 분리 원칙

한 파일에 너무 많은 코드를 넣지 않는다. 기능/섹션별로 파일을 분리한다.

| 기준 | 설명 |
|------|------|
| 300줄 초과 | 분리 검토 필요 |
| 500줄 초과 | 반드시 분리 |
| 단일 책임 원칙 | 한 파일은 한 가지 역할만 |

```
-- Bad: 모든 코드가 한 파일에
Oculus_RaidFrames/
└── RaidFrames.lua (1000줄+, 모든 기능 포함)

-- Good: 기능별 분리
Oculus_RaidFrames/
├── RaidFrames.lua      -- 모듈 진입점, 초기화
├── Auras.lua           -- 버프/디버프 표시
├── Config.lua          -- 설정 UI
├── Cooldowns.lua       -- 쿨다운 트래킹 (예정)
└── CastAlerts.lua      -- 시전 알림 (예정)
```

### 공유 기능 분리

버프와 디버프처럼 유사한 기능은 공통 모듈로 분리할 수 있다.

```lua
-- AuraUtils.lua: 버프/디버프 공통 유틸리티
local AuraUtils = {}

function AuraUtils:CreateIcon(parent, size)
    -- 공통 아이콘 생성 로직
end

function AuraUtils:UpdateTimer(frame, expirationTime)
    -- 공통 타이머 업데이트 로직
end

return AuraUtils
```

---

## 리팩토링 체크리스트

### 네이밍
- [ ] 모듈/클래스: PascalCase
- [ ] 함수: PascalCase
- [ ] 지역 변수: camelCase
- [ ] 상수: LOUD_SNAKE_CASE
- [ ] 비공개: _underscore 접두사
- [ ] 약어: 풀네임 사용, camelCase 규칙 적용

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
- [ ] 300줄 초과 파일 분리 검토

---

## 참고 자료

- [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/)
- [WoW API Documentation](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [Blizzard UI Source](https://github.com/Gethe/wow-ui-source)
