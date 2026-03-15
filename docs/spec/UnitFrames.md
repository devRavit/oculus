# Oculus_UnitFrames

## 역할

Player, Target, Focus, Target-of-Target 프레임 강화

> 포트레이트 CC/Aura 오버레이 기능이 제거되었으며 (miniCC로 대체), 향후 기능 추가 예정.

## 현재 상태

LossOfControlFrame 커스터마이징 기능 구현 완료.

## SavedVariables

```lua
OculusUnitFramesStorage = {
    Enabled = true,
    LossOfControl = {
        HideBackground = false,  -- 어두운 배경 숨김
        HideRedLines = false,    -- 빨간 선(RedLineTop/RedLineBottom) 숨김
        Scale = 100,             -- 프레임 크기 (50-200%)
        OffsetX = 0,             -- X 위치 오프셋 (-500 ~ 500)
        OffsetY = 0,             -- Y 위치 오프셋 (-500 ~ 500)
    },
}
```

## 파일 구조

```
Oculus_UnitFrames/
├── Oculus_UnitFrames.toc
├── UnitFrames.lua      -- 모듈 초기화, 스토리지 관리, 이벤트 등록
├── LossOfControl.lua   -- LossOfControlFrame 커스터마이징 로직
└── Config.lua          -- 설정 UI (탭/사이드바 구조)
```

## LossOfControl 기능

### 개요
플레이어가 CC (군중 제어) 당했을 때 화면 중앙에 표시되는 `LossOfControlFrame`을 커스터마이징.

### 구현 방식
- `LossOfControlFrame:HookScript("OnShow", applySettings)` — 프레임이 표시될 때마다 설정 적용
- `LossOfControlFrame.blackBg` — 어두운 배경 Hide/Show
- `LossOfControlFrame.RedLineTop` / `RedLineBottom` — 빨간 선 Hide/Show
- `LossOfControlFrame:SetScale(scale)` — 크기 조절
- `LossOfControlFrame:ClearAllPoints()` + `SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)` — 위치 조절

### API
```lua
addon.LossOfControl:Enable()          -- 훅 등록, 기능 활성화
addon.LossOfControl:Disable()         -- 기능 비활성화, 기본값으로 복원
addon.LossOfControl:ApplySettings()   -- 현재 Storage 설정 즉시 적용
```

## 제거된 기능

### ~~포트레이트 CC/Aura 오버레이 (BigDebuffs 스타일)~~ → miniCC로 대체

- ~~포트레이트 위에 가장 우선순위가 높은 단일 Aura 오버레이~~
- ~~아이콘 위에 쿨다운 스윕 애니메이션~~
- ~~타이머 텍스트, 원형 마스킹, 카테고리별 글로우 색상~~
- ~~SpellDB (CC/Immunity/Defensive/Offensive 카테고리)~~
- ~~커스텀 스펠 관리~~
- ~~설정 UI (아이콘 크기, 위치, 카테고리 필터)~~
