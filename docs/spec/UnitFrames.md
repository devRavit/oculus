# Oculus_UnitFrames

## 역할

Player, Target, Focus, ToT 프레임 강화

## 기능

### 버프/디버프 필터
- 중요 버프/디버프를 프레임에 크게 표시
- CC, 방어기, 주요 디버프 카테고리별 필터링
- 우선순위 기반 표시 (가장 중요한 것만)

## 대상 프레임

| 프레임 | 설명 |
|--------|------|
| PlayerFrame | 플레이어 |
| TargetFrame | 타겟 |
| FocusFrame | 포커스 |
| TargetOfTargetFrame | 타겟의 타겟 |

## 설정 옵션

```lua
Oculus_UnitFramesDB = {
    enabled = true,
    iconSize = 40,
    position = "CENTER",  -- CENTER, LEFT, RIGHT
    showTimer = true,
    categories = {
        cc = true,         -- CC (양, 빙결, 공포 등)
        defensive = true,  -- 방어기 (신보, 얼방 등)
        offensive = true,  -- 공격 버프 (광전사, 변신 등)
        immunity = true,   -- 면역 (무적, 버블 등)
    },
}
```

## 파일 구조

```
Oculus_UnitFrames/
├── Oculus_UnitFrames.toc
├── UnitFrames.lua     -- 메인 초기화, 프레임 후킹
└── Auras.lua          -- Aura 필터링, 아이콘 표시
```

## 프리뷰 모드

- `/oculus test unitframes`
- 가짜 CC 아이콘 표시 (양, 빙결, 실명)
- 타이머 카운트다운 시뮬레이션

---

## Progress

### Phase 1: 기본 구조
- [ ] Oculus_UnitFrames.toc 생성
- [ ] UnitFrames.lua 초기화
- [ ] 프레임 후킹 (PlayerFrame, TargetFrame, FocusFrame, ToT)

### Phase 2: Aura 필터링
- [ ] Auras.lua 구현
- [ ] C_UnitAuras API 연동
- [ ] 카테고리별 필터링 로직

### Phase 3: 아이콘 표시
- [ ] 아이콘 프레임 생성
- [ ] 위치/크기 설정
- [ ] 타이머 표시

### Phase 4: 테스트 모드
- [ ] 가짜 aura 데이터 생성
- [ ] 시뮬레이션 로직
