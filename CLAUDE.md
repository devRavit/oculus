# Oculus Addon - Development Guidelines

> **Claude 지시사항**: 이 파일의 모든 규칙을 준수할 것.

---

## Checkpoint: 작업 전 필수 읽기

> **⚠️ WoW API 사용 시 1순위 참조**: https://warcraft.wiki.gg/wiki/Secret_Values
> 모든 기능 개발/수정 전 Secret Values 문서를 먼저 확인하고 시작할 것.

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

## 개발 문서

| 문서 | 경로 | 내용 |
|------|------|------|
| 코드 스타일 | [`docs/CODE_STYLE.md`](docs/CODE_STYLE.md) | 네이밍, 포맷팅, 파일 구조, 리팩토링 체크리스트 |
| 아키텍처 | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | WoW 특화 규칙, 객체지향 설계, 설정 패턴 |

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

## Secret Values (WoW 12.0 Midnight) — 필수 숙지

> **⚠️ CRITICAL: 기능 개발 및 수정 시 1순위 참조 문서**
> **공식 문서**: https://warcraft.wiki.gg/wiki/Secret_Values
> 코드 작성 전 반드시 읽고, 시크릿 값 관련 패턴인지 확인할 것.

**CRITICAL: 아래 API는 전투 중 tainted 코드에서 시크릿 값을 반환함. 잘못 사용 시 Lua 에러 발생.**

### 시크릿 값을 반환하는 주요 API

| API | 반환되는 시크릿 값 | 비고 |
|-----|-------------------|------|
| `UnitCastingInfo(unit)` | texture, startTime, endTime, name (비-플레이어 유닛) | 플레이어 시전은 non-secret |
| `UnitChannelInfo(unit)` | 위와 동일 | |
| `UnitHealth(unit)` | HP 수치 | |
| `UnitHealthMax(unit)` | 최대 HP | |
| `UnitPower(unit)` | 자원 수치 | |
| `UnitInRange(unit)` | 시크릿 **불리언** | `if inRange` 불가 |
| `UnitGUID(unit)` | 적 유닛 GUID (PvP/레이드) | |
| CLEU spellID/destGUID | 시크릿 숫자 | CLEU 자체가 12.0에서 제거됨 |

### 금지 연산 (시크릿 값에 절대 사용 금지)

```lua
-- ❌ 비교 연산
if health > 50 then ...
if not spellName then ...       -- nil 체크도 금지!
if texture == nil then ...
if inRange then ...              -- 시크릿 불리언 조건문 금지

-- ❌ 산술 연산
local remaining = endTime - GetTime() * 1000

-- ❌ 길이 연산자
local len = #secretString

-- ❌ 테이블 키로 사용
myTable[spellID] = true
```

### 허용 연산 (UI API에 전달)

```lua
-- ✅ UI API는 시크릿 값 허용
icon:SetTexture(texture)
bar:SetMinMaxValues(startTime, endTime)
bar:SetValue(GetTime() * 1000)    -- GetTime()은 non-secret
frame:SetAlpha(health)
nameText:SetText(spellName)
frame:SetAlphaFromBoolean(inRange, 1.0, 0.55)  -- UnitInRange 전용

-- ✅ 변수/테이블 필드에 저장
local saved = startTime
castInfo.texture = texture

-- ✅ string.format()
local text = string.format("%s", spellName)
```

### 이벤트 기반 패턴 (nil 체크 우회)

```lua
-- ❌ 잘못된 패턴: UnitCastingInfo 반환값 nil 체크
local name, _, texture = UnitCastingInfo(unit)
if not name then return end  -- 시전 중이면 name이 시크릿 → 비교 불가!

-- ✅ 올바른 패턴: 이벤트로 시전 상태 판단, 값은 UI API로만 사용
-- UNIT_SPELLCAST_START 이벤트 = 시전 중임이 확정
-- → nil 체크 없이 바로 UnitCastingInfo 호출 후 UI API에 전달
local function onCastStart(unit)
    local _, _, texture, startTime, endTime = UnitCastingInfo(unit)
    icon:SetTexture(texture)                        -- 시크릿 OK (UI API)
    bar:SetMinMaxValues(startTime, endTime)         -- 시크릿 OK (UI API)
    bar:SetValue(GetTime() * 1000)                  -- non-secret
end
-- UNIT_SPELLCAST_STOP/SUCCEEDED/FAILED/INTERRUPTED → 시전 종료 처리
```

### pcall 활용 (시크릿 값 접근 에러 방어)

```lua
-- 시크릿 여부 불확실한 코드는 pcall로 감싸기
pcall(function()
    local _, _, texture, startTime, endTime = UnitCastingInfo(unit)
    icon:SetTexture(texture)
    bar:SetMinMaxValues(startTime, endTime)
end)
```

---

## 로깅 규칙 (절대 준수)

**CRITICAL: print() 함수 사용 절대 금지**

- **print() 직접 호출 절대 금지** - 어떠한 상황에서도 print() 사용 금지
- **반드시 logDebug() 함수만 사용** - 모든 로그는 logDebug()를 통해서만 출력
- **Logger 모듈 사용**: `addon.Logger:Log(module, submodule, message)`
- **로그 저장**: SavedVariables (`OculusUnitFramesLogs`)에 자동 저장
- **로그 확인**:
  - 게임 내: 채팅창에 실시간 출력
  - SavedVariables: `/Applications/World of Warcraft/_retail_/WTF/Account/*/SavedVariables/Oculus_UnitFrames.lua`
- **로그 포맷**: `[YYYY-MM-DD HH:MM:SS] [Module:SubModule] message`
- **최대 로그 수**: 500개 (초과 시 오래된 로그부터 삭제)
