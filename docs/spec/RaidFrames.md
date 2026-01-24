# Oculus_RaidFrames

## 역할

파티/레이드 프레임 강화

## 기능

### 1. 버프/디버프 필터
- 파티원에게 걸린 중요 CC/디버프 표시
- 아이콘 크기 확대
- 우선순위 기반 표시

### 2. 아군 쿨다운 트래킹
- 파티원 주요 쿨다운 표시
- 방어기, 유틸리티 스킬 추적
- 남은 시간 표시

### 3. 적 시전 알림 (Cast Alert)
- 적이 아군에게 시전 시 해당 프레임 하이라이트
- 아이콘 + 타이머 표시
- 메즈/딜 스킬 구분 (색상 또는 테두리)

## 트래킹 스킬 예시

| 클래스 | 스킬 |
|--------|------|
| 성기사 | 신성한 보호막, 헌신의 오라, 축복의 보호 |
| 사제 | 고통 억제, 수호 영혼, 생명의 약진 |
| 드루이드 | 철피, 재생의 숲 |
| 수도사 | 생명의 고치, 부활의 안개 |
| 전사 | 집결의 외침, 보호막 방벽 |
| 죽기사 | 대마법 보호막, 얼어붙은 인내력 |

## 알림 분류

| 타입 | 색상 | 예시 |
|------|------|------|
| CC/메즈 | 보라색 | 양변이, 공포, 사이클론 |
| 강한 딜 | 빨간색 | 카오스 화살 |
| 유틸리티 | 노란색 | 정화, 해제 |

## 설정 옵션

```lua
Oculus_RaidFramesDB = {
    enabled = true,
    auras = {
        enabled = true,
        iconSize = 30,
        maxIcons = 3,
    },
    cooldowns = {
        enabled = true,
        iconSize = 20,
        position = "BOTTOM",
        trackedSpells = { ... },
    },
    castAlert = {
        enabled = true,
        flashDuration = 0.5,
        showIcon = true,
        ccColor = {0.5, 0, 0.5, 0.8},    -- 보라
        damageColor = {1, 0, 0, 0.8},     -- 빨강
        utilityColor = {1, 1, 0, 0.8},    -- 노랑
    },
}
```

## 파일 구조

```
Oculus_RaidFrames/
├── Oculus_RaidFrames.toc
├── RaidFrames.lua     -- 메인 초기화, 프레임 후킹
├── Auras.lua          -- Aura 필터링
├── Cooldowns.lua      -- 쿨다운 트래킹
└── CastAlert.lua      -- 적 시전 알림
```

## 프리뷰 모드

- `/oculus test raidframes`
- 가짜 파티 프레임 5개 표시
- CC 아이콘, 쿨다운 바, 시전 알림 시뮬레이션

---

## Progress

### Phase 1: 기본 구조
- [ ] Oculus_RaidFrames.toc 생성
- [ ] RaidFrames.lua 초기화
- [ ] 파티 프레임 후킹

### Phase 2: Aura 필터링
- [ ] Auras.lua 구현
- [ ] 카테고리별 필터링

### Phase 3: 쿨다운 트래킹
- [ ] Cooldowns.lua 구현
- [ ] UNIT_SPELLCAST_SUCCEEDED 이벤트 연동
- [ ] 쿨다운 타이머 계산

### Phase 4: Cast Alert
- [ ] CastAlert.lua 구현
- [ ] UNIT_SPELLCAST_START 이벤트 연동
- [ ] 프레임 하이라이트 효과
- [ ] 메즈/딜 구분 색상

### Phase 5: 테스트 모드
- [ ] 가짜 데이터 시뮬레이션
