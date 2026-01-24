# Oculus - WoW PvP Addon Suite

> 라틴어 "Oculus" = 눈 (Eye)
> PvP 전투에서 모든 것을 볼 수 있게 해주는 애드온

---

## 개요

Oculus는 World of Warcraft Midnight (12.0) PvP를 위한 통합 애드온 스위트입니다.
코어 모듈과 3개의 독립적인 프레임 모듈로 구성되어 있으며, 각 모듈은 개별적으로 활성화/비활성화할 수 있습니다.

### 목표

- 일반 PvP 유저들이 표준으로 사용하는 애드온
- 직관적이고 깔끔한 UI
- 12.0 API에 완벽 대응

---

## 프로젝트 구조

```
oculus/
├── Oculus/                    # 코어 모듈
│   ├── Oculus.toc
│   ├── Core.lua
│   ├── ModuleManager.lua
│   ├── Config.lua
│   ├── Constants.lua
│   ├── Utils.lua
│   └── TestMode.lua
│
├── Oculus_UnitFrames/         # 유닛프레임 모듈
│   ├── Oculus_UnitFrames.toc
│   ├── UnitFrames.lua
│   └── Auras.lua
│
├── Oculus_RaidFrames/         # 레이드프레임 모듈
│   ├── Oculus_RaidFrames.toc
│   ├── RaidFrames.lua
│   ├── Auras.lua
│   ├── Cooldowns.lua
│   └── CastAlert.lua
│
├── Oculus_ArenaFrames/        # 아레나프레임 모듈
│   ├── Oculus_ArenaFrames.toc
│   ├── ArenaFrames.lua
│   ├── Auras.lua
│   └── Sorting.lua
│
├── SPECIFICATION.md
├── README.md
└── .gitignore
```

---

## 모듈 상세

### 1. Oculus (코어)

**역할**: 전체 애드온 관리, 공통 기능 제공

**기능**:
- 모듈 활성화/비활성화 UI
- 공통 상수 (Spell ID, 카테고리 등)
- 공통 유틸리티 함수
- 슬래시 커맨드
- 테스트/프리뷰 모드

**슬래시 커맨드**:
```
/oculus              - 설정 UI 열기
/oculus enable <module>   - 모듈 활성화
/oculus disable <module>  - 모듈 비활성화
/oculus test              - 전체 테스트 모드
/oculus test <module>     - 특정 모듈 테스트
```

**SavedVariables**:
```lua
OculusDB = {
    enabledModules = {
        UnitFrames = true,
        RaidFrames = true,
        ArenaFrames = true,
    },
    -- 공통 설정
}
```

---

### 2. Oculus_UnitFrames

**역할**: Player, Target, Focus, ToT 프레임 강화

**기능**:

#### 2.1 버프/디버프 필터
- 중요 버프/디버프를 프레임에 크게 표시
- CC, 방어기, 주요 디버프 카테고리별 필터링
- 우선순위 기반 표시 (가장 중요한 것만)

**대상 프레임**:
| 프레임 | 설명 |
|--------|------|
| PlayerFrame | 플레이어 |
| TargetFrame | 타겟 |
| FocusFrame | 포커스 |
| TargetOfTargetFrame | 타겟의 타겟 |

**설정 옵션**:
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

**프리뷰 모드**:
- `/oculus test unitframes`
- 가짜 CC 아이콘 표시 (양, 빙결, 실명)
- 타이머 카운트다운 시뮬레이션

---

### 3. Oculus_RaidFrames

**역할**: 파티/레이드 프레임 강화

**기능**:

#### 3.1 버프/디버프 필터
- 파티원에게 걸린 중요 CC/디버프 표시
- 아이콘 크기 확대
- 우선순위 기반 표시

#### 3.2 아군 쿨다운 트래킹
- 파티원 주요 쿨다운 표시
- 방어기, 유틸리티 스킬 추적
- 남은 시간 표시

**트래킹 스킬 예시**:
| 클래스 | 스킬 |
|--------|------|
| 성기사 | 신성한 보호막, 헌신의 오라, 축복의 보호 |
| 사제 | 고통 억제, 수호 영혼, 생명의 약진 |
| 드루이드 | 철피, 재생의 숲 |
| 수도사 | 생명의 고치, 부활의 안개 |
| 전사 | 집결의 외침, 보호막 방벽 |
| 죽기사 | 대마법 보호막, 얼어붙은 인내력 |

#### 3.3 적 시전 알림 (Cast Alert)
- 적이 아군에게 시전 시 해당 프레임 하이라이트
- 아이콘 + 타이머 표시
- 메즈/딜 스킬 구분 (색상 또는 테두리)

**알림 분류**:
| 타입 | 색상 | 예시 |
|------|------|------|
| CC/메즈 | 보라색 | 양변이, 공포, 사이클론 |
| 강한 딜 | 빨간색 | 카오스 화살, 신속 치유 (적) |
| 유틸리티 | 노란색 | 정화, 해제 |

**설정 옵션**:
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

**프리뷰 모드**:
- `/oculus test raidframes`
- 가짜 파티 프레임 5개 표시
- CC 아이콘, 쿨다운 바, 시전 알림 시뮬레이션

---

### 4. Oculus_ArenaFrames

**역할**: 아레나 적 프레임 강화

**기능**:

#### 4.1 프레임 정렬
- 힐러/딜러/탱 순서 자동 정렬
- 수동 정렬 옵션
- 드래그로 위치 조정

**정렬 옵션**:
| 옵션 | 설명 |
|------|------|
| SPEC | 힐러 > 딜러 순서 |
| CLASS | 클래스 알파벳 순서 |
| MANUAL | 사용자 지정 |
| NONE | 정렬 안 함 (기본) |

#### 4.2 버프/디버프 필터
- 적에게 걸린 중요 버프 표시 (트링켓, 방어기 등)
- 내가 건 디버프 강조
- 우선순위 기반 표시

**설정 옵션**:
```lua
Oculus_ArenaFramesDB = {
    enabled = true,
    sorting = {
        enabled = true,
        mode = "SPEC",  -- SPEC, CLASS, MANUAL, NONE
    },
    auras = {
        enabled = true,
        iconSize = 35,
        showMyDebuffs = true,
        myDebuffGlow = true,
    },
    layout = {
        scale = 1.0,
        spacing = 5,
        growDirection = "DOWN",
    },
}
```

**프리뷰 모드**:
- `/oculus test arenaframes`
- 가짜 Arena1/2/3 프레임 표시
- 정렬 시뮬레이션

---

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

    -- 빙결
    [45438] = {name = "Ice Block", duration = 10, category = "IMMUNITY"},

    -- ... 추가
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

    -- ... 추가
}
```

---

## 기술 스펙

### 12.0 API 대응

**Secret Values 처리**:
```lua
-- 안전한 aura 조회
local function GetSafeAuraInfo(unit, index)
    local aura = C_UnitAuras.GetAuraDataByIndex(unit, index)
    if aura and not issecretvalue(aura.spellId) then
        return aura
    end
    return nil
end
```

**이벤트 핸들링**:
```lua
-- 주요 이벤트
UNIT_AURA                  -- 버프/디버프 변경
UNIT_SPELLCAST_START       -- 시전 시작
UNIT_SPELLCAST_STOP        -- 시전 종료
ARENA_OPPONENT_UPDATE      -- 아레나 상대 변경
GROUP_ROSTER_UPDATE        -- 파티/레이드 변경
```

### 성능 최적화

- 이벤트 쓰로틀링 (0.1초)
- 불필요한 업데이트 방지
- 테이블 재사용

---

## 개발 로드맵

### Phase 1: 코어 + 기본 구조
- [ ] Oculus 코어 모듈
- [ ] 모듈 매니저
- [ ] 슬래시 커맨드
- [ ] 기본 설정 UI

### Phase 2: UnitFrames
- [ ] 프레임 후킹
- [ ] Aura 필터링
- [ ] 아이콘 표시
- [ ] 테스트 모드

### Phase 3: RaidFrames
- [ ] 파티 프레임 후킹
- [ ] Aura 필터링
- [ ] 쿨다운 트래킹
- [ ] Cast Alert

### Phase 4: ArenaFrames
- [ ] 아레나 프레임 후킹
- [ ] 정렬 기능
- [ ] Aura 필터링

### Phase 5: 폴리싱
- [ ] 설정 UI 개선
- [ ] 프로필 저장/불러오기
- [ ] 성능 최적화
- [ ] CurseForge 배포

---

## 참고 자료

- [WoW 12.0 API 변경사항](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
- [BigDebuffs GitHub](https://github.com/jordonwow/bigdebuffs)
- [OmniCD CurseForge](https://www.curseforge.com/wow/addons/omnicd)
