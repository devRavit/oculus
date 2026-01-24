# Oculus - Core Module

## 역할

전체 애드온 관리, 공통 기능 제공

## 기능

- 모듈 활성화/비활성화 UI
- 공통 상수 (Spell ID, 카테고리 등)
- 공통 유틸리티 함수
- 슬래시 커맨드
- 테스트/프리뷰 모드

## 슬래시 커맨드

```
/oculus                   - 설정 UI 열기
/oculus enable <module>   - 모듈 활성화
/oculus disable <module>  - 모듈 비활성화
/oculus test              - 전체 테스트 모드
/oculus test <module>     - 특정 모듈 테스트
```

## SavedVariables

```lua
OculusDB = {
    enabledModules = {
        UnitFrames = true,
        RaidFrames = true,
        ArenaFrames = true,
    },
}
```

## 파일 구조

```
Oculus/
├── Oculus.toc
├── Core.lua           -- 메인 초기화
├── ModuleManager.lua  -- 모듈 활성화/비활성화
├── Config.lua         -- 설정 UI
├── Constants.lua      -- Spell ID, 카테고리 상수
├── Utils.lua          -- 공통 유틸리티
└── TestMode.lua       -- 테스트/프리뷰 모드
```

## Spell Database

### CC 카테고리

```lua
OCULUS_CC_SPELLS = {
    -- 변이
    [118] = {name = "Polymorph", duration = 8, category = "INCAPACITATE"},
    [28272] = {name = "Polymorph (Pig)", duration = 8, category = "INCAPACITATE"},

    -- 공포
    [5782] = {name = "Fear", duration = 8, category = "FEAR"},
    [8122] = {name = "Psychic Scream", duration = 8, category = "FEAR"},

    -- 기절
    [853] = {name = "Hammer of Justice", duration = 6, category = "STUN"},
    [408] = {name = "Kidney Shot", duration = 6, category = "STUN"},

    -- 빙결/면역
    [45438] = {name = "Ice Block", duration = 10, category = "IMMUNITY"},
}
```

### 방어기 카테고리

```lua
OCULUS_DEFENSIVE_SPELLS = {
    -- 성기사
    [642] = {name = "Divine Shield", duration = 8, category = "IMMUNITY"},
    [1022] = {name = "Blessing of Protection", duration = 10, category = "PHYSICAL_IMMUNE"},
    [6940] = {name = "Blessing of Sacrifice", duration = 12, category = "DEFENSIVE"},

    -- 사제
    [33206] = {name = "Pain Suppression", duration = 8, category = "DEFENSIVE"},
    [47788] = {name = "Guardian Spirit", duration = 10, category = "DEFENSIVE"},
}
```

---

## Progress

### Phase 1: 기본 구조
- [ ] Oculus.toc 생성
- [ ] Core.lua 초기화
- [ ] 슬래시 커맨드 등록

### Phase 2: 모듈 매니저
- [ ] ModuleManager.lua 구현
- [ ] 모듈 활성화/비활성화 로직

### Phase 3: 설정 UI
- [ ] Config.lua 구현
- [ ] 기본 설정 패널

### Phase 4: 상수/유틸리티
- [ ] Constants.lua (Spell DB)
- [ ] Utils.lua (공통 함수)

### Phase 5: 테스트 모드
- [ ] TestMode.lua 구현
