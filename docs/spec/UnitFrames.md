# Oculus_UnitFrames

## 역할

Player, Target, Focus, Target-of-Target 프레임의 포트레이트 위에 가장 우선순위가 높은 Aura를 큰 아이콘으로 오버레이 표시 (BigDebuffs 스타일)

## 대상 프레임

| 유닛 | 블리자드 프레임 | 포트레이트 |
|------|----------------|------------|
| player | PlayerFrame | PlayerPortrait (60×60) |
| target | TargetFrame | Portrait (58×58) |
| focus | FocusFrame | Portrait (58×58) |
| targettarget | TargetFrameToT | Portrait (37×37) |

## 주요 기능

### Aura 오버레이 (BigDebuffs 스타일)

- 4개 유닛에 대해 가장 우선순위가 높은 단일 Aura를 포트레이트에 오버레이
- 아이콘 위에 쿨다운 스윕 애니메이션
- 타이머 텍스트 (1초 간격 갱신)
- PORTRAIT 위치 시 원형 마스킹 처리
- 카테고리별 테두리 글로우 색상 (PORTRAIT 외 위치에서만)

### Aura 카테고리 및 우선순위

| 카테고리 | 글로우 색상 | 카테고리 우선순위 | 스펠 예시 |
|----------|------------|-----------------|---------|
| CC | 빨강 | 1 (최우선) | Polymorph(100), Fear(90), Stun(80) |
| Immunity | 보라 | 2 | Divine Shield(95), Ice Block(90) |
| Defensive | 파랑 | 3 | Pain Suppression, Guardian Spirit |
| Offensive | 노랑 | 4 | Bloodlust, Recklessness |

정렬 기준: 카테고리 순서 → 스펠 우선순위 → 남은 시간 짧은 순

### Aura 스캔 방식

- HARMFUL 40개 + HELPFUL 40개 순차 스캔
- `C_UnitAuras.GetAuraDataByIndex()` 사용 (12.0 API)
- SpellDB에 등록된 스펠만 표시
- Secret Values는 pcall로 안전하게 처리

## 설정 옵션

```lua
OculusUnitFramesStorage = {
    Enabled = true,
    IconSize = 40,           -- 아이콘 크기 (20~60px), PORTRAIT 모드에서는 포트레이트의 85% 크기로 자동 조정
    Position = "PORTRAIT",   -- PORTRAIT | CENTER | LEFT | RIGHT
    ShowTimer = true,        -- 타이머 텍스트 표시 여부
    Categories = {
        CC = true,
        Immunity = true,
        Defensive = true,
        Offensive = true,
    },
    CustomSpells = {},       -- 사용자 추가 스펠
}
```

## 파일 구조

```
Oculus_UnitFrames/
├── Oculus_UnitFrames.toc
├── UnitFrames.lua   -- 모듈 초기화, 스토리지 관리, 이벤트 등록
├── Auras.lua        -- 아이콘 프레임 생성/갱신, Aura 스캔 및 정렬, 이벤트 처리
├── Spells.lua       -- SpellDB (카테고리별 스펠 목록, 우선순위), 커스텀 스펠 관리
└── Config.lua       -- 설정 UI (Icon Size 슬라이더, Position 드롭다운, 카테고리 체크박스, 디버그 로그 뷰어)
```

## 주요 이벤트

| 이벤트 | 처리 |
|--------|------|
| `UNIT_AURA` (player/target/focus/targettarget) | 해당 유닛 아이콘 갱신 |
| `PLAYER_TARGET_CHANGED` | target, targettarget 아이콘 갱신 |
| `PLAYER_FOCUS_CHANGED` | focus 아이콘 갱신 |

## 기술 구현 메모

### Combat Lockdown 회피

PlayerFrame/TargetFrame 등은 Protected Frame이므로 자식 프레임이 전투 중 제한됨.
아이콘 프레임은 `UIParent`를 부모로 생성하고, 포트레이트에만 앵커를 걸어 이 문제를 회피.

```lua
local frame = CreateFrame("Frame", nil, UIParent)  -- 부모: UIParent (non-protected)
frame:SetPoint("CENTER", portrait, "CENTER", 0, 0) -- 앵커: 포트레이트 중심
```

### 원형 마스킹 (PORTRAIT 모드)

```lua
local maskTexture = frame:CreateMaskTexture()
maskTexture:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", ...)
frame.Icon:AddMaskTexture(maskTexture)
```
