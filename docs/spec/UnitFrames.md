# Oculus_UnitFrames

> ⚠️ **포트레이트 CC 오버레이 기능 제거 예정**
> miniCC 애드온과 기능 중복으로 인해 포트레이트 Aura 오버레이(BigDebuffs 스타일) 기능을 제거할 예정.
> 해당 기능은 miniCC로 대체.

## 역할

Player, Target, Focus, Target-of-Target 프레임 강화

## 주요 기능

### ~~포트레이트 CC/Aura 오버레이 (BigDebuffs 스타일)~~ → miniCC로 대체 예정

- ~~포트레이트 위에 가장 우선순위가 높은 단일 Aura 오버레이~~
- ~~아이콘 위에 쿨다운 스윕 애니메이션~~
- ~~타이머 텍스트, 원형 마스킹, 카테고리별 글로우 색상~~

## 파일 구조

```
Oculus_UnitFrames/
├── Oculus_UnitFrames.toc
├── UnitFrames.lua   -- 모듈 초기화, 스토리지 관리, 이벤트 등록
├── Auras.lua        -- 아이콘 프레임 생성/갱신, Aura 스캔 및 정렬, 이벤트 처리
├── Spells.lua       -- SpellDB (카테고리별 스펠 목록, 우선순위), 커스텀 스펠 관리
└── Config.lua       -- 설정 UI
```
