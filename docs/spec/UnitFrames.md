# Oculus_UnitFrames

## 역할

Player, Target, Focus, Target-of-Target 프레임 강화

> 포트레이트 CC/Aura 오버레이 기능이 제거되었으며 (miniCC로 대체), 향후 기능 추가 예정.

## 현재 상태

모듈 스켈레톤만 존재. 저장소 초기화 및 모듈 등록만 수행.

## SavedVariables

```lua
OculusUnitFramesStorage = {
    Enabled = true,
}
```

## 파일 구조

```
Oculus_UnitFrames/
├── Oculus_UnitFrames.toc
└── UnitFrames.lua   -- 모듈 초기화, 스토리지 관리, 이벤트 등록
```

## 제거된 기능

### ~~포트레이트 CC/Aura 오버레이 (BigDebuffs 스타일)~~ → miniCC로 대체

- ~~포트레이트 위에 가장 우선순위가 높은 단일 Aura 오버레이~~
- ~~아이콘 위에 쿨다운 스윕 애니메이션~~
- ~~타이머 텍스트, 원형 마스킹, 카테고리별 글로우 색상~~
- ~~SpellDB (CC/Immunity/Defensive/Offensive 카테고리)~~
- ~~커스텀 스펠 관리~~
- ~~설정 UI (아이콘 크기, 위치, 카테고리 필터)~~
